#!/bin/bash

kubectl label ns argocd trust-manager/bundle=enabled --overwrite
kubectl label ns vault trust-manager/bundle=enabled --overwrite
