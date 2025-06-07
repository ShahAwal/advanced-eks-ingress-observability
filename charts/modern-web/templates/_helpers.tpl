{{/*
Expand the name of the chart.
*/}}
{{- define "modern-web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "modern-web.fullname" -}}
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
{{- define "modern-web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "modern-web.labels" -}}
helm.sh/chart: {{ include "modern-web.chart" . }}
{{ include "modern-web.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "modern-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "modern-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "modern-web.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "modern-web.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress
*/}}
{{- define "modern-web.ingress.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19-0" .Capabilities.KubeVersion.Version) -}}
{{- print "networking.k8s.io/v1" -}}
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Return if ingress is stable.
*/}}
{{- define "modern-web.ingress.isStable" -}}
{{- eq (include "modern-web.ingress.apiVersion" .) "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Return if ingress supports pathType.
*/}}
{{- define "modern-web.ingress.supportsPathType" -}}
{{- or (eq (include "modern-web.ingress.apiVersion" .) "networking.k8s.io/v1") (eq (include "modern-web.ingress.apiVersion" .) "networking.k8s.io/v1beta1") -}}
{{- end -}}

{{/*
Validate values for deployment strategy
*/}}
{{- define "modern-web.validateValues.deploymentStrategy" -}}
{{- if and .Values.deploymentStrategy (not (or (eq .Values.deploymentStrategy.type "RollingUpdate") (eq .Values.deploymentStrategy.type "Recreate"))) -}}
{{- fail "deploymentStrategy.type must be either RollingUpdate or Recreate" -}}
{{- end -}}
{{- end -}}

{{/*
Validate values for autoscaling
*/}}
{{- define "modern-web.validateValues.autoscaling" -}}
{{- if .Values.autoscaling.enabled -}}
{{- if or (lt .Values.autoscaling.minReplicas 1) (lt .Values.autoscaling.maxReplicas .Values.autoscaling.minReplicas) -}}
{{- fail "autoscaling.minReplicas must be at least 1 and autoscaling.maxReplicas must be greater than autoscaling.minReplicas" -}}
{{- end -}}
{{- end -}}
{{- end -}}