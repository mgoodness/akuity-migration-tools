#!/usr/bin/env bash

if [ $# -lt 2 ]; then
  echo "usage: migrate-projects.sh <org> <project_files..>"
  exit 1
fi

export org=$1
shift

for project_file in "$@"; do
  apf="../akuity-projects/$project_file"

  if [[ "$project_file" != "$org"* ]]; then
    apf="../akuity-projects/$org-$project_file"
  fi

  cp $project_file $apf

  oldDestServers=$(yq '.spec.destinations[].server' $apf)
  for ods in $oldDestServers; do
    newDestName=$(ods=$ods yq -Poy '.[]|(select(.oldServer==strenv(ods))|.newName)' \
      ../cluster-map.json)
    ods=$ods ndn=$newDestName yq '(.spec.destinations[]|select(.server==strenv(ods))|.name)=strenv(ndn)' \
      -i $apf
  done

  yq 'del(.spec.destinations[]|select(.name==""))|del(.spec.destinations[].server)' \
    -i $apf

  old_name="$(yq '.metadata.name' $apf)"
  if [[ "$old_name" != "$org"-* ]]; then
    new_name="$org-$old_name" yq '.metadata.name=strenv(new_name)' -i $apf
  fi

  yq '.metadata.labels.org=strenv(org)|sort_keys(..)' -i $apf
done
