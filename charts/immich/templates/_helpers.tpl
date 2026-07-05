{{/*
Expand the name of the chart.
*/}}
{{- define "immich.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "immich.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "immich.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "immich.labels" -}}
helm.sh/chart: {{ include "immich.chart" . }}
{{ include "immich.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.global.environment | quote }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "immich.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Application label value for selectors.
*/}}
{{- define "immich.appLabel" -}}
{{- if eq .component "server" -}}immich-server
{{- else if eq .component "immich-ml" -}}immich-ml
{{- else -}}{{ .component }}
{{- end }}
{{- end }}

{{/*
Selector labels with component.
*/}}
{{- define "immich.selectorLabelsWithComponent" -}}
{{- $ctx := .context -}}
{{ include "immich.selectorLabels" $ctx }}
app.kubernetes.io/component: {{ .component }}
app: {{ include "immich.appLabel" . }}
{{- end }}

{{/*
Common labels with component.
*/}}
{{- define "immich.labelsWithComponent" -}}
{{- $ctx := .context -}}
{{- include "immich.labels" $ctx }}
app.kubernetes.io/component: {{ .component }}
app: {{ include "immich.appLabel" . }}
{{- end }}

{{/*
Component resource name.
*/}}
{{- define "immich.componentName" -}}
{{- printf "%s-%s" (include "immich.fullname" .context) .component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.serverWorkloadName" -}}
{{- printf "%s-immich-server" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.serverConfigName" -}}
{{- printf "%s-server" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.immichConfigName" -}}
{{- printf "%s-immich-config" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.mlName" -}}
{{- printf "%s-immich-ml" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.mlConfigName" -}}
{{- printf "%s-ml-config" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.postgresName" -}}
{{- printf "%s-postgres" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.postgresSecretName" -}}
{{- printf "%s-db" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.redisName" -}}
{{- printf "%s-redis" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.serverDataPvcName" -}}
{{- printf "%s-immich-data" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.modelCachePvcName" -}}
{{- printf "%s-model-cache" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "immich.dbDataPvcName" -}}
{{- printf "%s-db-data-pvc" (include "immich.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "immich.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "immich.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
