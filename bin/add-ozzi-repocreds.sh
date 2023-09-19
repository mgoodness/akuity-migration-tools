#!/usr/bin/env bash

if [ $# -ne 2 ]; then
  echo "usage: add-ozzi-repocreds.sh <org_url> <installation_id>"
  exit 1
fi

url="$1"
private_key_pem=$(mktemp)
# Read GH App private key from 1Password to $private_key_pem

argocd --grpc-web --server $argocd_server repocreds add --upsert \
  "${repo%/}/" \
  --github-app-id=$app_id \
  --github-app-installation-id="$2" \
  --github-app-private-key-path="$private_key_pem" \
  --github-app-enterprise-base-url=$ghes_url
