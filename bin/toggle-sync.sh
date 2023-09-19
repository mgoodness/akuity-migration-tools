#!/usr/bin/env bash

if [ $# -ne 2 ]; then
  echo "usage: toggle-sync.sh <directory> [on|off]"
  exit 1
fi

dir="$1"

while read f; do
  if [ "$2" == "off" ]; then
    yq '(select(.spec.syncPolicy.automated | (has("prune") and .prune)) | .spec.syncPolicy) |= with(.; (. | key) head_comment = "restorePrune" | del(.automated))' -i "$f"
    yq '(select(.spec.syncPolicy | has("automated")) | .spec.syncPolicy) |= with(.; (. | key) head_comment = "restoreAutomated" | del(.automated))' -i "$f"
  fi
  
  if [ "$2" == "on" ]; then
    yq '(select((.spec.syncPolicy | key | head_comment)=="restorePrune") | .spec.syncPolicy) |= with(.; (. | key) head_comment = "" | . += {"automated": {"prune": true}} | sort_keys(..))' -i "$f"
    yq '(select((.spec.syncPolicy | key | head_comment)=="restoreAutomated") | .spec.syncPolicy) |= with(.; (. | key) head_comment = "" | . += {"automated": {}} | sort_keys(..))' -i "$f"
  fi
done < <(fd -e yaml -E "*-appset.yaml" . "$dir")

while read f; do
  if [ "$2" == "off" ]; then
    yq '(select(.spec.template.spec.syncPolicy.automated | (has("prune") and .prune)) | .spec.template.spec.syncPolicy) |= with(.; (. | key) head_comment = "restorePrune" | del(.automated))' -i "$f"
    yq '(select(.spec.template.spec.syncPolicy | has("automated")) | .spec.template.spec.syncPolicy) |= with(.; (. | key) head_comment = "restoreAutomated" | del(.automated))' -i "$f"
  fi
  
  if [ "$2" == "on" ]; then
    yq '(select((.spec.template.spec.syncPolicy | key | head_comment)=="restorePrune") | .spec.template.spec.syncPolicy) |= with(.; (. | key) head_comment = "" | . += {"automated": {"prune": true}} | sort_keys(..))' -i "$f"
    yq '(select((.spec.template.spec.syncPolicy | key | head_comment)=="restoreAutomated") | .spec.template.spec.syncPolicy) |= with(.; (. | key) head_comment = "" | . += {"automated": {}} | sort_keys(..))' -i "$f"
  fi
done < <(fd ".*-appset.yaml" "$dir")
