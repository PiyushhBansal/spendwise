{{- define "spendwise.name" -}}
{{- .Release.Name | trunc 40 | trimSuffix "-" -}}
{{- end -}}

{{- define "spendwise.labels" -}}
app.kubernetes.io/part-of: spendwise
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "spendwise.backend" -}}{{ include "spendwise.name" . }}-backend{{- end -}}
{{- define "spendwise.frontend" -}}{{ include "spendwise.name" . }}-frontend{{- end -}}
{{- define "spendwise.postgres" -}}{{ include "spendwise.name" . }}-postgres{{- end -}}

{{- define "spendwise.podSecurity" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{- define "spendwise.containerSecurity" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: ["ALL"]
{{- end -}}
