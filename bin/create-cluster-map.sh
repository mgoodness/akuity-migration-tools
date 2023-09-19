#!/usr/bin/env bash

# tempfile=$(mktemp)

# kubectl get secrets -l argocd.argoproj.io/secret-type=cluster,league -o json | \
#   jq -r '.items|map({"newName": (.metadata.labels.league + "-" + .metadata.labels.ballpark + "-" + .metadata.labels.cluster), "oldServer": .data.server|@base64d})' > ballpark-clusters.json

# kubectl get secrets -l argocd.argoproj.io/secret-type=cluster,onprem,!ballpark -o json | \
#   jq -r '.items|map({"newName": ("mlb-" + .metadata.labels.region + "-" + .metadata.labels.owner + "-" + .metadata.labels.env), "oldServer": .data.server|@base64d})' > onprem-clusters.json

# kubectl get secrets -l argocd.argoproj.io/secret-type=cluster,!onprem,org!=tdc -o json | \
#   jq -r '.items|map({"newName": ("mlb-gcp-" + .metadata.labels.team + "-" + .metadata.labels.env + "-" + .metadata.labels.region + "-" + .metadata.labels.cluster), "oldServer": .data.server|@base64d})' > mlb-gcp-clusters.json

# kubectl get secrets -l argocd.argoproj.io/secret-type=cluster,!onprem,org=tdc,team!=oke -o json | \
#   jq -r '.items|map({"newName": ("tdc-gcp-" + (.metadata.labels.team|ltrimstr("tdc-")) + "-" + .metadata.labels.env + "-" + .metadata.labels.region + "-" + .metadata.labels.cluster), "oldServer": .data.server|@base64d})' > tdc-gcp-clusters.json

# tempfile=$(mktemp)
# for n in $(jq -r '.[]|(select(.newName|contains("pci-"))|.newName)' tdc-gcp-clusters.json); do
#   np="${n//pci-}"
#   c="${np:(-2)}"
#   export new_pci_name="${np/$c/-pci$c}"
#   cp tdc-gcp-clusters.json $tempfile && \
#     old_name=$n jq -r 'map(select(.newName==env.old_name).newName|=env.new_pci_name)' $tempfile > tdc-gcp-clusters.json
# done

# kubectl get secrets -l argocd.argoproj.io/secret-type=cluster,!onprem,org=tdc,team=oke -o json | \
#   jq -r '.items|map({"newName": ("tdc-oci-" + (.metadata.labels.team|ltrimstr("tdc-")) + "-" + .metadata.labels.env + "-" + .metadata.labels.region + "-" + .metadata.labels.cluster), "oldServer": .data.server|@base64d})' > tdc-oci-clusters.json

jq -s 'add|sort_by(.newName)' \
  ballpark-clusters.json \
  onprem-clusters.json \
  mlb-gcp-clusters.json \
  tdc-gcp-clusters.json \
  > cluster-map.json

# rm ballpark-clusters.json *-gcp-clusters.json
