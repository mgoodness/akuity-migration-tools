#!/usr/bin/env bash

if [ $# -lt 3 ]; then
  echo "usage: migrate-apps.sh <path_to_cluster_map.json> <dir> <team> (<org>)"
  exit 1
fi

cluster_map="$1"
dir="$2"
export team="$3"
export org="$4"

while read f; do
  old_app_name="$(yq '.metadata.name' $f)"
  if [[ "$old_app_name" != *"$team"* ]]; then
    new_app_name="$team-$old_app_name" yq '.metadata.name=strenv(new_app_name)' -i $f
  fi

  yq '.metadata.labels.team=strenv(team)' -i $f

  if [ ! -z $org ]; then
    # old_project="$(yq '.spec.project' $f)"
    # if [[ "$old_project" != "$org"-* ]]; then
    #   new_project="$org-$old_project" yq '.spec.project=strenv(new_project)' -i $f
    # fi
  
    env="$(yq .metadata.labels.env $f)"
    if [[ "$env" == *"prod"* ]]; then
      env="prod"
    else
      env="npd"
    fi

    new_project="$org-$team-$env" yq '.spec.project=strenv(new_project)' -i $f
    yq '.metadata.labels.org=strenv(org)' -i $f
  fi

  export old_dest_server=$(yq '(select(.spec.destination | has("server")))|.spec.destination.server' $f)
  if [ ! -z "$old_dest_server" ]; then
    export new_dest_name=$(yq -Poy '.[]|(select(.oldServer==strenv(old_dest_server))|.newName)' "$cluster_map")
    if [ ! -z "$new_dest_name" ]; then
      yq '.spec.destination.name=strenv(new_dest_name)|del(.spec.destination.server)|sort_keys(..)' -i $f
    fi
  fi

  yq '.spec.syncPolicy.syncOptions=["ApplyOutOfSyncOnly=true", "CreateNamespace=true", "PruneLast=true", "PrunePropagationPolicy=background", "RespectIgnoreDifferences=true"]|sort_keys(..)' -i $f
done < <(fd -e yaml -E "*-appset.yaml" . "$dir")

while read f; do
  old_appset_name="$(yq '.metadata.name' $f)"
  if [[ "$old_appset_name" != *"$team"* ]]; then
    new_appset_name="$team-$old_appset_name" yq '.metadata.name=strenv(new_appset_name)' -i $f
  fi

  old_app_name="$(yq '.spec.template.metadata.name' $f)"
  if [[ "$old_app_name" != *"$team"* ]]; then
    new_app_name="$team-$old_app_name" yq '.spec.template.metadata.name=strenv(new_app_name)' -i $f
  fi

  yq '.spec.template.metadata.labels.team=strenv(team)' -i $f

  if [ ! -z $org ]; then
    old_project="$(yq '.spec.template.spec.project' $f)"
    if [[ "$old_project" != "$org"-* ]]; then
      new_project="$org-$old_project" yq '.spec.template.spec.project=strenv(new_project)' -i $f
    fi
  
    yq '.spec.template.metadata.labels.org=strenv(org)' -i $f
  fi

  yq '.spec.template.spec.destination.name="{{name}}"|del(.spec.template.spec.destination.server)|sort_keys(..)' -i $f
  yq '.spec.template.spec.syncPolicy.syncOptions=["ApplyOutOfSyncOnly=true", "CreateNamespace=true", "PruneLast=true", "PrunePropagationPolicy=background", "RespectIgnoreDifferences=true"]|sort_keys(..)' -i $f
done < <(fd ".*-appset.yaml" "$dir")
