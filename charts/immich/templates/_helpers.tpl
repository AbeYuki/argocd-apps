{{/*
チャート名を生成
*/}}
{{- define "immich.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
既定の完全修飾アプリケーション名を生成
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
ラベルに使用するチャート名とバージョンを生成
*/}}
{{- define "immich.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
共通ラベル
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
セレクター用ラベル
*/}}
{{- define "immich.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
セレクターに使用するアプリケーションラベル
*/}}
{{- define "immich.appLabel" -}}
{{- if eq .component "server" -}}immich-server
{{- else if eq .component "immich-ml" -}}immich-ml
{{- else -}}{{ .component }}
{{- end }}
{{- end }}

{{/*
コンポーネント名を含むセレクター用ラベル
*/}}
{{- define "immich.selectorLabelsWithComponent" -}}
{{- $ctx := .context -}}
{{ include "immich.selectorLabels" $ctx }}
app.kubernetes.io/component: {{ .component }}
app: {{ include "immich.appLabel" . }}
{{- end }}

{{/*
コンポーネント名を含む共通ラベル
*/}}
{{- define "immich.labelsWithComponent" -}}
{{- $ctx := .context -}}
{{- include "immich.labels" $ctx }}
app.kubernetes.io/component: {{ .component }}
app: {{ include "immich.appLabel" . }}
{{- end }}

{{/*
コンポーネントのリソース名
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
使用するサービスアカウント名を生成
*/}}
{{- define "immich.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "immich.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
