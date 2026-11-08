#!/usr/bin/env bash
set -euo pipefail
# 呼び出し元が xtrace を有効にしていても認証情報を表示しない
set +x

for tool in jq python3 vault argocd-vault-plugin; do
  if ! command -v "$tool" > /dev/null 2>&1; then
    echo "必要なコマンドが見つかりません: $tool" >&2
    exit 1
  fi
done

# 標準入力は Helm の YAML 専用
# 入力・プロンプトは端末に分離
if ! { exec 3<> /dev/tty; } 2>/dev/null; then
  echo "対話入力できる端末から実行してください。" >&2
  exit 1
fi
prompt() {
  local name=$1 message=$2 hidden=${3:-false}
  printf '%s' "$message" >&3
  if [[ "$hidden" == true ]]; then
    IFS= read -r -s -u 3 "$name" || return 1
    printf '\n' >&3
  else
    IFS= read -r -u 3 "$name" || return 1
  fi
}


prompt vault_url 'Vault URL（Basic 認証の埋め込み可・非表示）: ' true
export vault_url
# URL パーサーで userinfo を分離し、percent-encoding を一度だけデコード
# URL は環境変数で渡し、コマンド引数や Python のエラーに含めない
if ! url_config=$(python3 - <<'PYURL'
import json
import os
import re
from urllib.parse import unquote, urlsplit, urlunsplit

try:
    raw = os.environ["vault_url"]
    url = urlsplit(raw)
    if (url.scheme != "https" or not url.hostname or url.query or url.fragment
            or any(c.isspace() for c in raw) or "\\" in raw
            or url.path.rstrip("/").endswith(("/ui", "/v1"))):
        raise ValueError()
    # 不正なポートと percent-encoding も認証開始前に拒否
    url.port
    if re.search(r"%(?![0-9a-fA-F]{2})", raw):
        raise ValueError()
    embedded = url.username is not None
    username = unquote(url.username or "", errors="strict")
    password = unquote(url.password or "", errors="strict")
    if embedded and (not username or ":" in username):
        raise ValueError()
    base = urlunsplit(("https", url.netloc.rsplit("@", 1)[-1], url.path, "", ""))
    print(json.dumps({"url": base, "embedded": embedded,
                      "username": username, "password": password}))
except (ValueError, UnicodeError):
    raise SystemExit(1)
PYURL
); then
  echo "有効な https:// のベース URL を指定してください（/ui・/v1 は不要。認証情報の特殊文字は URL エンコードしてください）" >&2
  exit 1
fi
vault_url=$(jq -r '.url' <<< "$url_config")
basic_user=$(jq -r '.username' <<< "$url_config")
basic_password=$(jq -r '.password' <<< "$url_config")
if [[ $(jq -r '.embedded' <<< "$url_config") == false ]]; then
  prompt basic_user 'Basic 認証ユーザー名（不要なら Enter）: '
  if [[ -n "$basic_user" ]]; then
    if [[ "$basic_user" == *:* ]]; then
      echo "Basic 認証ユーザー名に : は使用できません" >&2
      exit 1
    fi
    prompt basic_password 'Basic 認証パスワード: ' true
  fi
fi
unset url_config
prompt oidc_path 'OIDC 認証パス [oidc]: '
oidc_path=${oidc_path:-oidc}
if [[ ! "$oidc_path" =~ ^[a-zA-Z0-9_-]+(/[a-zA-Z0-9_-]+)*$ ]]; then
  echo "OIDC 認証パスは auth/ を除いたマウント名で指定してください" >&2
  exit 1
fi
prompt oidc_role 'OIDC ロール（Vault UI と同じ値。既定なら Enter）: '
prompt use_mtls 'Vault に直接 mTLS 接続しますか？ [y/N]: '
case "$use_mtls" in
  y|Y|yes|YES) use_mtls=true ;;
  ''|n|N|no|NO) use_mtls=false ;;
  *) echo "mTLS は y または n で指定してください。" >&2; exit 1 ;;
esac
exec 3>&-

unset VAULT_TOKEN VAULT_WRAP_TTL
export AVP_TYPE=vault AVP_AUTH_TYPE=token
# Argo CD 用の環境変数や Agent アドレスに入力内容を上書きされない
unset ARGOCD_ENV_AVP_TYPE ARGOCD_ENV_AVP_AUTH_TYPE ARGOCD_ENV_VAULT_ADDR
unset ARGOCD_ENV_VAULT_TOKEN VAULT_AGENT_ADDR
# SDK が URL の userinfo を HTTP Basic 認証に使用
# jq の環境変数経由で渡し、パスワードをコマンド引数に含めない
export vault_url basic_user basic_password
VAULT_ADDR=$(jq -nr '
  env.vault_url | if env.basic_user == "" then . else
    sub("https://"; "https://" + (env.basic_user | @uri) + ":" +
      (env.basic_password | @uri) + "@") end')
export VAULT_ADDR

umask 077
avp_tmpdir=$(mktemp -d)
trap 'rm -f -- "$avp_tmpdir"/*; rmdir -- "$avp_tmpdir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# 公開 URL はシステム CA で検証
# 指定済みのローカル証明書も利用可能
# 直接接続の mTLS を選択した場合のみ Kubernetes から証明書を取得
for variable in VAULT_CLIENT_CERT VAULT_CLIENT_KEY VAULT_CACERT; do
  if [[ -n "${!variable:-}" ]]; then
    if [[ ! -r "${!variable}" ]]; then
      echo "$variable で指定したファイルを読み取れません。" >&2
      exit 1
    fi
    continue
  fi
  if [[ "$use_mtls" != true ]]; then
    continue
  fi
  if ! command -v kubectl > /dev/null 2>&1; then
    echo "mTLS 証明書の取得には kubectl が必要です。" >&2
    exit 1
  fi
  case "$variable" in
    VAULT_CLIENT_CERT|VAULT_CLIENT_KEY)
      secret_file="$avp_tmpdir/client-tls.json"
      secret_name="${AVP_TLS_SECRET_NAME:-vault-client-tls}"
      secret_namespace="${AVP_TLS_SECRET_NAMESPACE:-argocd}"
      if [[ "$variable" == VAULT_CLIENT_CERT ]]; then
        secret_key=tls.crt
      else
        secret_key=tls.key
      fi
      ;;
    VAULT_CACERT)
      secret_file="$avp_tmpdir/ca-secret.json"
      secret_name="${AVP_CA_SECRET_NAME:-vault-ha-tls}"
      secret_namespace="${AVP_CA_SECRET_NAMESPACE:-vault}"
      secret_key="${AVP_CA_SECRET_KEY:-ca.crt}"
      ;;
  esac

  if [[ ! -f "$secret_file" ]]; then
    kubectl get secret "$secret_name" \
      --namespace "$secret_namespace" \
      --request-timeout=15s -o json < /dev/null |
      jq --arg key "$secret_key" --arg variable "$variable" \
        'if $variable == "VAULT_CACERT" then {data: {($key): .data[$key]}} else . end' \
        > "$secret_file"
  fi
  local_path="$avp_tmpdir/$variable.pem"
  jq -er --arg key "$secret_key" \
    '.data[$key] | select(type == "string" and length > 0) | @base64d' \
    "$secret_file" > "$local_path"
  export "$variable=$local_path"
done

# SSO の案内は認証待ちの間も表示
# URL 内の Basic 認証情報は除去
redact() {
  jq --unbuffered -Rr '
    def redact($value):
      if $value == "" then . else split($value) | join("[REDACTED]") end;
    gsub("https://[^/[:space:]]*@"; "https://[REDACTED]@") |
    redact(env.VAULT_ADDR // "") | redact(env.VAULT_TOKEN // "") |
    redact((env.basic_password // "") | @uri) | redact(env.basic_password // "")
  '
}

printf '%s\n' 'ブラウザーで Google SSO を完了してください（callback: http://localhost:8250/oidc/callback）。' >&2
login_args=(login -method=oidc -path="$oidc_path" -token-only)
if [[ -n "$oidc_role" ]]; then
  login_args+=("role=$oidc_role")
fi
# -token-only は token helper に保存せず、stdout に token だけを返す
# Helm の YAML をログインコマンドに利用しない
if ! VAULT_TOKEN=$(vault "${login_args[@]}" < /dev/null 2> >(redact >&2)); then
  echo "SSO ログインに失敗しました。OIDC パス・ロールと、ロールの allowed_redirect_uris に http://localhost:8250/oidc/callback が含まれることを確認してください。" >&2
  exit 1
fi
if [[ -z "$VAULT_TOKEN" || "$VAULT_TOKEN" == *[[:space:]]* ]]; then
  echo "SSO ログインから有効な Vault token を取得できませんでした" >&2
  exit 1
fi
export VAULT_TOKEN

status=0
argocd-vault-plugin generate - 2> "$avp_tmpdir/stderr" || status=$?
redact < "$avp_tmpdir/stderr" >&2
exit "$status"
