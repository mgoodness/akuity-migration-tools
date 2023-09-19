#!/usr/bin/env bash

export AKUITY_SERVER=
export AKUITY_WEBHOOK_SECRET=
export GH_HOST=
export OLD_ARGO_SERVER=

function create_hook () {
  gh api --method POST --silent repos/$1/hooks \
    -f config[content_type]='json' \
    -f config[secret]="$AKUITY_WEBHOOK_SECRET" \
    -f config[url]="https://$AKUITY_SERVER/api/webhook" \
    -f events[]='push'

  echo "Created Akuity hook for $org/$repo"
}
  
function update_hook () {
  gh api --method PATCH --silent repos/$1/hooks/$2 \
    -f events[]='push'

  gh api --method PATCH --silent repos/$1/hooks/$2/config \
    -f content_type='json' \
    -f secret="$AKUITY_WEBHOOK_SECRET" \
    -f url="https://$AKUITY_SERVER/api/webhook"

  echo "Updated Akuity hook for $org/$repo"
}
  
hooks=$(mktemp)
repos=$(mktemp)

for project in "$@"; do
  argocd --grpc-web --server $AKUITY_SERVER app list -o json -p $project | jq -r 'map(.spec.source.repoURL|sub(".git$"; ""))|unique|.[]' >> $repos
done
  
for r in $(sort $repos | uniq); do
  org=$(echo "$r" | sd "^https://$GH_HOST/(.*)/.*$" '$1')
  repo=$(echo "$r" | sd "^https://$GH_HOST/.*/(.*)$" '$1')

  if gh api --paginate repos/${org}/${repo}/hooks &> $hooks; then
    akuity_hook=$(jq -r '.[]|(select(.config.url==$ENV.AKUITY_SERVER+"/api/webhook")|.id)' $hooks)
    argocd_hook=$(jq -r '.[]|(select(.config.url==$ENV.OLD_ARGOCD_SERVER+"/api/webhook")|.id)' $hooks)

    # If self-hosted webhook exists, delete it
    if [ ! -z $argocd_hook ]; then
      gh api --method DELETE repos/$org/$repo/hooks/$argocd_hook

      echo "Deleted self-hosted hook from $org/$repo"
    fi

    # If Akuity webhook exists, update it.
    if [ ! -z $akuity_hook ]; then
      update_hook "$org/$repo" $akuity_hook
    else
      # echo "Create Akuity hook for $org/$repo? "
      create_hook "$org/$repo"
    fi
  else
    echo "** Unlock repo: https://$GH_HOST/stafftools/repositories/$org/$repo/security **"
  fi
done
