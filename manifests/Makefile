SHELL=/bin/bash

longhorn:login
	argocd app sync longhorn

vl:login
	argocd app sync victoria-logs-cluster

vmalert:login
	argocd app sync victoria-metrics-alert

monitoring:login
	argocd app sync monitoring --prune

ingress-nginx:login
	argocd app sync ingress-nginx --prune

login:
	argocd login argocd.aimhighergg.com --grpc-web
