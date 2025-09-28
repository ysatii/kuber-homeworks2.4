{{- define "webapp.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "webapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
