{{/*
Expand the name of the chart.
*/}}
{{- define "waha.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "waha.fullname" -}}
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

{{- define "waha.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "waha.labels" -}}
helm.sh/chart: {{ include "waha.chart" . }}
{{ include "waha.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "waha.selectorLabels" -}}
app.kubernetes.io/name: {{ include "waha.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "waha.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "waha.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding credentials, whether chart-managed or user-supplied.
*/}}
{{- define "waha.secretName" -}}
{{- if .Values.secret.existingSecret }}
{{- .Values.secret.existingSecret }}
{{- else }}
{{- include "waha.fullname" . }}-credentials
{{- end }}
{{- end }}

{{/*
Name of the PVC holding session data, whether chart-managed or user-supplied.
*/}}
{{- define "waha.pvcName" -}}
{{- if .Values.session.existingClaim }}
{{- .Values.session.existingClaim }}
{{- else }}
{{- include "waha.fullname" . }}-sessions
{{- end }}
{{- end }}
