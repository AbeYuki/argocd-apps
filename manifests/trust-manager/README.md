# Vault PKI / mTLS 証明書運用メモ

## 概要

この構成では、Vault の mTLS に以下の証明書を利用する。

- Root CA
  - `cert-manager/vault-root-ca-secret`
  - Vault server 証明書、AVP client 証明書、Traefik client 証明書の発行元
- Root CA bundle
  - `vault-root-ca-secret-bundle`
  - trust-manager により各 namespace へ配布する信頼 CA
- Vault server Leaf 証明書
  - `vault/vault-ha-tls`
- ArgoCD AVP client Leaf 証明書
  - `argocd/vault-client-tls`
- Traefik Vault client Leaf 証明書
  - `vault/traefik-vault-client-tls`

Root CA は信頼アンカーであり、Leaf 証明書は実際に Vault / AVP / Traefik が mTLS で利用する証明書である。

## trust-manager Secret target の許可設定

trust-manager で target を Secret にする場合、trust-manager の values で Secret target を有効化し、target Secret 名を明示的に許可する必要がある。
Secret 名が secretTargets.authorizedSecrets に含まれていない場合 RBAC エラーになる。
```yaml
secretTargets:
  enabled: true
  authorizedSecretsAll: false
  authorizedSecrets:
    - vault-root-ca-secret-bundle
```

以下の Bundle の場合、target Secret 名は Bundle 名と同じ secret/vault-root-ca-secret-bundle になる。
```yaml
apiVersion: trust.cert-manager.io/v1alpha1
kind: Bundle
metadata:
  name: vault-root-ca-secret-bundle
spec:
  sources:
    - secret:
        name: vault-root-ca-secret
        key: ca.crt
  target:
    secret:
      key: ca.pem
    namespaceSelector:
      matchLabels:
        trust-manager/bundle: "enabled"
```

## Root CA bundle の役割

trust-manager の Bundle は、Root CA を複数 namespace に一貫して配布するために利用する。

```
cert-manager/vault-root-ca-secret
  -> trust-manager Bundle
    -> argocd/vault-root-ca-secret-bundle
    -> vault/vault-root-ca-secret-bundle
```

Root CA bundle は、AVP や Vault などが相手の証明書を検証するための信頼 CA として利用する。
```yaml
volumes:
  - name: vault-ca
    secret:
      secretName: vault-root-ca-secret-bundle
      items:
        - key: ca.pem
          path: ca.pem

volumeMounts:
  - name: vault-ca
    mountPath: /etc/vault/ca
    readOnly: true
```

AVP の設定:
```yaml
VAULT_CACERT: /etc/vault/ca/ca.pem
```

## Leaf 証明書の役割

AVP client 証明書は trust-manager で bundle 配布しない。
AVP 用の client Leaf 証明書は、cert-manager が argocd namespace に直接発行する。

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: avp-client-leaf
  namespace: argocd
spec:
  secretName: vault-client-tls
```

ArgoCD repo-server では以下のように mount する。

```yaml
volumes:
  - name: vault-client-tls
    secret:
      secretName: vault-client-tls
      items:
        - key: tls.crt
          path: tls.crt
        - key: tls.key
          path: tls.key

volumeMounts:
  - name: vault-client-tls
    mountPath: /etc/vault/tls
    readOnly: true
```

AVP の設定:

```yaml
VAULT_CLIENT_CERT: /etc/vault/tls/tls.crt
VAULT_CLIENT_KEY: /etc/vault/tls/tls.key
```

## 更新方針

### Root CA 更新時

Root CA を更新する場合は、Root CA bundle とすべての Leaf 証明書の世代を揃える。

Root CA 更新時は以下を同じメンテナンス枠で実施する。

1. Root CA を renew
1. Root CA bundle source Secret を更新
1. trust-manager 配布先 Secret の更新を確認
1. Vault server cert / AVP client cert / Traefik client cert を renew
1. Vault / ArgoCD repo-server / Traefik など利用側を再起動または reload
1. fingerprint と mTLS 接続確認を行う

Root CA 更新後に Leaf 証明書を更新しないと、古い Root CA で発行された Leaf 証明書と、新しい trust bundle の世代がずれて unknown certificate authority が発生する可能性がある。


### Leaf 証明書更新時

Leaf 証明書は cert-manager により自動更新される。

ただし、Vault / ArgoCD repo-server / Traefik などのプロセスが Secret volume の更新を自動で再読み込みするとは限らないため、Leaf 証明書更新後は対象 Pod を再起動または reload する。

## renew-root.sh

Root CA を手動更新する場合のスクリプト。
Root CA 更新時は Leaf 証明書もまとめて renew し、世代を揃える。

## renew-leaf.sh

Leaf 証明書のみを手動更新する場合のスクリプト。
Root CA は更新しない。