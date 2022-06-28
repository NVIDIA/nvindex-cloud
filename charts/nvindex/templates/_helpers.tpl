{{/*
Expand the name of the chart.
*/}}
{{- define "nvindex.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nvindex.fullname" -}}
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
{{- define "nvindex.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nvindex.labels" -}}
helm.sh/chart: {{ include "nvindex.chart" . }}
{{ include "nvindex.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nvindex.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nvindex.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nvindex.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nvindex.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Image name expanders
*/}}
{{- define "nvindex.image" -}}
{{- $registryName := .Values.nvindex.image.registry -}}
{{- $repositoryName := .Values.nvindex.image.repository -}}
{{- $tag := .Values.nvindex.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end }}

{{- define "cloudhelper.image" -}}
{{- $registryName := .Values.cloudhelper.image.registry -}}
{{- $repositoryName := .Values.cloudhelper.image.repository -}}
{{- $tag := .Values.cloudhelper.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end }}

{{- define "debughelper.image" -}}
{{- $registryName := .Values.debughelper.image.registry -}}
{{- $repositoryName := .Values.debughelper.image.repository -}}
{{- $tag := .Values.debughelper.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end }}
