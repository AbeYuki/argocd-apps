#!/bin/bash

kubectl create ns argocd || true
kubectl create ns vault || true
kubectl create ns cert-manager || true
kubectl create ns airflow || true
kubectl label ns argocd trust-manager/bundle=enabled --overwrite
kubectl label ns vault trust-manager/bundle=enabled --overwrite
pushd cert-manager/production
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl apply -f -
popd

pushd vault-ca
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl apply -f -
popd

if [ -n $(kubectl -n cert-manager get secret vault-root-ca-secret -o jsonpath='{.data.tls\.crt}') ];then
    kubectl -n cert-manager get secret vault-root-ca-secret -o jsonpath='{.data.tls\.crt}' \
     | base64 -d \
     | kubectl -n cert-manager create configmap vault-ca-bundle --from-file=ca.pem=/dev/stdin
fi

pushd trust-manager/production
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl apply -f -
popd

pushd avp-secret/dev/
kubectl apply -k ./
popd

pushd argocd/production
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl apply -f -
popd

pushd vault/dev
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl apply -f -
popd

pushd secret/
kubectl apply -k ./
popd