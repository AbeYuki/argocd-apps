#!/bin/bash

# 1. Root CA を手動 renew
kubectl cert-manager renew -n cert-manager vault-root-ca

# 2. bundle source Secret を更新
kubectl -n cert-manager get secret vault-root-ca-secret \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | \
kubectl -n cert-manager create secret generic vault-root-ca-secret-bundle \
  --from-file=ca.pem=/dev/stdin \
  --dry-run=client -o yaml | \
kubectl apply -f -

# 3. Leaf 証明書 renew
kubectl cert-manager renew -n vault vault-server-cert
kubectl cert-manager renew -n argocd avp-client-leaf
kubectl cert-manager renew -n vault traefik-vault-client-leaf

# 4. 再起動
kubectl -n vault delete pod vault-2
until kubectl -n vault get pod vault-2 >/dev/null 2>&1; do
  echo "waiting for vault-2 to be recreated..."
  sleep 2
done
kubectl -n vault wait --for=condition=PodScheduled pod/vault-2 --timeout=300s

kubectl -n vault delete pod vault-1
until kubectl -n vault get pod vault-1 >/dev/null 2>&1; do
  echo "waiting for vault-1 to be recreated..."
  sleep 2
done
kubectl -n vault wait --for=condition=PodScheduled pod/vault-1 --timeout=300s

kubectl -n vault delete pod vault-0
until kubectl -n vault get pod vault-0 >/dev/null 2>&1; do
  echo "waiting for vault-0 to be recreated..."
  sleep 2
done
kubectl -n vault wait --for=condition=PodScheduled pod/vault-0 --timeout=300s

kubectl -n argocd rollout restart deploy/argo-cd-argocd-repo-server