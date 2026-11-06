{{/*
Chart name, truncated and DNS1123-safe.
*/}}
{{- define "edc-vpn.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "edc-vpn.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "edc-vpn.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "edc-vpn.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "edc-vpn.selectorLabels" -}}
app.kubernetes.io/name: {{ include "edc-vpn.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "edc-vpn.image" -}}
{{- printf "%s:%s" (required "image.repository is required" .Values.image.repository) (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{/*
This release's Service, as other Pods in the cluster reach it.
*/}}
{{- define "edc-vpn.serviceHost" -}}
{{- printf "%s.%s.svc.cluster.local" (include "edc-vpn.fullname" .) .Release.Namespace -}}
{{- end -}}

{{- define "edc-vpn.dspCallbackAddress" -}}
{{- .Values.dspCallbackAddress | default (printf "http://%s:%v%s" (include "edc-vpn.serviceHost" .) .Values.ports.protocol .Values.paths.protocol) -}}
{{- end -}}

{{- define "edc-vpn.vpnCallbackUrl" -}}
{{- .Values.vpn.callbackUrl | default (printf "http://%s:%v%s" (include "edc-vpn.serviceHost" .) .Values.ports.control .Values.paths.control) -}}
{{- end -}}

{{/*
Container port name for one of .Values.ports (at most 15 characters).
*/}}
{{- define "edc-vpn.portName" -}}
{{- printf "edc-%s" . | trunc 15 -}}
{{- end -}}
