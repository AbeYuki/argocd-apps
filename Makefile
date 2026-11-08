.PHONY: test-nextcloud test-immich clean-nextcloud clean-immich

export AVP_TLS_SECRET_NAME ?= vault-client-tls
export AVP_TLS_SECRET_NAMESPACE ?= argocd
export AVP_CA_SECRET_NAMESPACE ?= vault
export AVP_CA_SECRET_NAME ?= vault-ha-tls
export AVP_CA_SECRET_KEY ?= ca.crt

test-nextcloud:
	helm upgrade --install nextcloud ./charts/nextcloud \
		-f ./manifests/nextcloud/dev/values.yaml \
		--namespace nextcloud-dev \
		--create-namespace \
		--post-renderer ./scripts/helm-avp-post-renderer.sh

test-immich:
	helm upgrade --install immich ./charts/immich \
		-f ./manifests/immich/dev/values.yaml \
		--namespace immich-dev \
		--create-namespace \
		--post-renderer ./scripts/helm-avp-post-renderer.sh

clean-nextcloud:
	helm uninstall nextcloud --namespace nextcloud-dev

clean-immich:
	helm uninstall immich --namespace immich-dev
