{{/*
Common helper templates for all services.
These names are intentionally generic ("app.*") so they can be copied across charts.
*/}}

# so "app.name" picks the chart-name
# if you set in values.yaml ".Values.nameOverride"then "app.name" picks that - otherwise it will by default pick chart-name that you write in Chart.yaml
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


# "app.fullname" picks "app.name"
# but if you set ".Values.fullnameOverride" - it uses that
# at the end the resource name will always be the chart name
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "app.name" . | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{- define "app.labels" -}}
project: {{ required "values.yaml: project is required" .Values.project | quote }}
app: {{ include "app.name" . | quote }}
env: {{ required "values.yaml: env is required" .Values.env | quote }}
{{- end -}}


{{- define "app.selectorLabels" -}}
project: {{ required "values.yaml: project is required" .Values.project | quote }}
app: {{ include "app.name" . | quote }}
env: {{ required "values.yaml: env is required" .Values.env | quote }}
{{- end -}}



{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "app.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "app.configmapName" -}}
{{- default (include "app.fullname" .) .Values.configmap.nameOverride -}}
{{- end -}}

{{- define "app.secretName" -}}
{{- default (include "app.fullname" .) .Values.secret.nameOverride -}}
{{- end -}}
