#!/bin/sh
set -eu

log() {
    printf '%s\n' "[oidc-setup] $*"
}

occ() {
    php /var/www/html/occ "$@"
}

if [ "${NEXTCLOUD_OIDC_ENABLED:-false}" != "true" ]; then
    exit 0
fi

if ! php -r '
    $CONFIG = [];
    $file = "/var/www/html/config/config.php";
    if (is_file($file)) {
        require $file;
    }
    exit(!empty($CONFIG["installed"]) ? 0 : 1);
'; then
    log "Nextcloud is not installed; finish setup and restart the Pod."
    exit 0
fi

: "${NEXTCLOUD_OIDC_ISSUER:?OIDC discovery URL is required}"
: "${NEXTCLOUD_OIDC_CLIENT_ID:?OIDC client ID is required}"
: "${NEXTCLOUD_OIDC_CLIENT_SECRET:?OIDC client secret is required}"

occ status --output=json >/dev/null
apps="$(occ app:list --output=json)"
state="$(printf '%s' "$apps" | php -r '
    $apps = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
    if (isset($apps["enabled"]["user_oidc"])) {
        echo "enabled";
    } elseif (isset($apps["disabled"]["user_oidc"])) {
        echo "disabled";
    } else {
        echo "missing";
    }
')"

if [ "$state" != "enabled" ] && [ "${NEXTCLOUD_OIDC_INSTALL_APP:-true}" != "true" ]; then
    log "user_oidc must be installed and enabled when sso.app.enabled is false."
    exit 1
fi

case "$state" in
    missing)
        log "Installing user_oidc."
        occ app:install user_oidc --no-interaction
        ;;
    disabled)
        log "Enabling user_oidc."
        occ app:enable user_oidc --no-interaction
        ;;
esac

log "Applying OIDC provider configuration."
occ user_oidc:provider "${NEXTCLOUD_OIDC_PROVIDER:-dex}" \
    --clientid="$NEXTCLOUD_OIDC_CLIENT_ID" \
    --clientsecret="$NEXTCLOUD_OIDC_CLIENT_SECRET" \
    --discoveryuri="$NEXTCLOUD_OIDC_ISSUER" \
    --scope="${NEXTCLOUD_OIDC_SCOPES:-openid profile email}" \
    --mapping-uid="${NEXTCLOUD_OIDC_USERNAME_CLAIM:-preferred_username}" \
    --mapping-email="${NEXTCLOUD_OIDC_EMAIL_CLAIM:-email}" \
    --mapping-display-name="${NEXTCLOUD_OIDC_DISPLAY_NAME_CLAIM:-name}" \
    --no-interaction
log "OIDC provider configuration completed."
