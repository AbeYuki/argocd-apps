# Root CA Issuer

vault-ca-issuer は vault-root-ca-secret を利用して、Vault 関連の Leaf 証明書を発行する。
```yaml
ClusterIssuer:
  name: vault-ca-issuer
  secretName: vault-root-ca-secret
```

Root 証明書は 1年有効 / 30日前更新とする

```bash
duration: 8760h      # 1年
renewBefore: 720h    # 30日前
```

# Leaf 証明書

Leaf 証明書は 90日有効 / 15日前更新とする。

```bash
duration: 2160h      # 90日
renewBefore: 360h    # 15日前
```

対象:

|Certificate|Namespace|Secret|用途|
|-|-|-|-|
|vault-server-cert|vault|vault-ha-tls|Vault server 証明書|
|avp-client-leaf|argocd|vault-client-tls|ArgoCD AVP client 証明書|
|traefik-vault-client-leaf|vault|traefik-vault-client-tls|Traefik -> Vault client 証明書|

# 更新時の注意

Leaf 証明書は cert-manager により自動更新されるが、利用プロセスが Secret volume の変更を自動で再読み込みするとは限らない。
そのため、更新後は対象コンポーネントを再起動または reload する。

```
vault-server-cert 更新後:
  Vault Pod を再起動

avp-client-leaf 更新後:
  argocd-repo-server を再起動

traefik-vault-client-leaf 更新後:
  Traefik または利用コンポーネントを再起動 / reload
```

# Root CA 更新時の運用

Root CA を更新する場合は、Root CA だけでなく Leaf 証明書も同じタイミングで更新する。

1. Root CA を renew
2. trust-manager の bundle 配布先を確認
3. Vault server cert / AVP client cert / Traefik client cert を renew
4. Vault / ArgoCD repo-server / Traefik を再起動または reload
5. fingerprint と mTLS 接続確認を行う

Root CA と Leaf 証明書の世代がずれると、unknown certificate authority が発生する可能性がある。