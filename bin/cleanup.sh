#!/usr/bin/env bash

argocd_server=

for a in $(argocd --grpc-web --server $argocd_server app list -p "$1" -o name); do
  argocd --grpc-web --server $argocd_server app delete --cascade=false "$a"
done

rm "projects/$1.yaml"
argocd --grpc-web --server $argocd_server proj delete "$1"
