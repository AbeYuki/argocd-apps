# gateway 運用

## gateway
gateway は共有型の検証のため "envoy-gateway" の namespace につくられている。  
そのため cert-manager による ACME Challenge は envoy-gateway の namespace で行われる。  

そのため gateway で以下のような制限をいれてしまうと envoy-gateway の namespace で行われる namespace と一致しないため通信が許可される失敗する。  

```yaml
      allowedRoutes:
        namespaces:
          from: Selector
          selector: 
            matchLabels:
              gateway: www-aimhighergg-com
```

そのため envoy-gateway の namesapce にもラベルを付与するか all で許可する必要がある。
```bash
$ kubectl label namespace envoy-gateway gateway=www-aimhighergg-com --overwrite
```
