# manifest

```bash
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl diff -f -
```

```bash
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl apply -f -
```

```bash
kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone . | kubectl apply --server-side -f -
```