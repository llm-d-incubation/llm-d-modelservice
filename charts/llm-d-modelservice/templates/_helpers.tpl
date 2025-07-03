{{/*
Expand the name of the chart.
*/}}
{{- define "llm-d-modelservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "llm-d-modelservice.fullname" -}}
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
{{- define "llm-d-modelservice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create common labels for the resources managed by this chart.
*/}}
{{- define "llm-d-modelservice.labels" -}}
helm.sh/chart: {{ include "llm-d-modelservice.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Create sanitized model name (DNS compliant) */}}
{{- define "llm-d-modelservice.sanitizedModelName" -}}
  {{- $name := .Release.Name | lower | trim -}}
  {{- $name = regexReplaceAll "[^a-z0-9_.-]" $name "-" -}}
  {{- $name = regexReplaceAll "^[\\-._]+" $name "" -}}
  {{- $name = regexReplaceAll "[\\-._]+$" $name "" -}}
  {{- $name = regexReplaceAll "\\." $name "-" -}}

  {{- if gt (len $name) 63 -}}
    {{- $name = substr 0 63 $name -}}
  {{- end -}}

{{- $name -}}
{{- end }}

{{/* Create common shared by prefill and decode deployment/LWS */}}
{{- define "llm-d-modelservice.pdlabels" -}}
llm-d.ai/inferenceServing: "true"
llm-d.ai/model: {{ (include "llm-d-modelservice.fullname" .) -}}
{{- end }}

{{/* Create labels for the prefill deployment/LWS */}}
{{- define "llm-d-modelservice.prefilllabels" -}}
{{ include "llm-d-modelservice.pdlabels" . }}
llm-d.ai/role: prefill
{{- end }}

{{/* Create labels for the decode deployment/LWS */}}
{{- define "llm-d-modelservice.decodelabels" -}}
{{ include "llm-d-modelservice.pdlabels" . }}
llm-d.ai/role: decode
{{- end }}

{{/* Create node affinity from acceleratorTypes in Values */}}
{{- define "llm-d-modelservice.acceleratorTypes" -}}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
          - key: {{ .labelKey }}
            operator: In
            {{- with .labelValues }}
            values:
            {{- toYaml . | nindent 14 }}
            {{- end }}
{{- end }}

{{/* Create the init container for the routing proxy/sidecar for decode pods */}}
{{- define "llm-d-modelservice.routingProxy" -}}
initContainers:
  - name: routing-proxy
    args:
      - --port={{ default 8080 .servicePort }}
      - --vllm-port={{ default 8200 .proxy.targetPort }}
      - --connector=nixlv2
      - -v={{ default 5 .proxy.debugLevel }}
    image: {{ default "ghcr.io/llm-d/llm-d-routing-sidecar:0.0.6" .proxy.image }}
    imagePullPolicy: Always
    ports:
      - containerPort: {{ default 8080 .servicePort }}
    resources: {}
    restartPolicy: Always
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
{{- end }}

{{/* Desired P/D tensor parallelism -- user set or defaults to 1 */}}
{{- define "llm-d-modelservice.tensorParallelism" -}}
{{- if and . .tensor }}{{ .tensor }}{{ else }}1{{ end }}
{{- end }}

{{/* Desired P/D data parallelism -- user set or defaults to 1 */}}
{{- define "llm-d-modelservice.dataParallelism" -}}
{{- if and . .data }}{{ .data }}{{ else }}1{{ end }}
{{- end }}

{{/* Desired P/D data local parallelism -- user set or defaults to 1 */}}
{{- define "llm-d-modelservice.dataLocalParallelism" -}}
{{- if and . .dataLocal }}{{ .dataLocal }}{{ else }}1{{ end }}
{{- end }}

{{/*
Port on which vllm container should listen.
Context is helm root context plus key "role" ("decode" or "prefill")
*/}}
{{- define "llm-d-modelservice.vllmPort" -}}
{{- if eq .role "prefill" }}{{ .Values.routing.servicePort }}{{ else }}{{ .Values.routing.proxy.targetPort }}{{ end }}
{{- end }}

{{/* P/D deployment container resources */}}
{{- define "llm-d-modelservice.resources" -}}
{{- $tensorParallelism := int (include "llm-d-modelservice.tensorParallelism" .parallelism) -}}
{{- $dataLocalParallelism := int (include "llm-d-modelservice.dataLocalParallelism" .parallelism) -}}
{{- $limits := dict }}
{{- if and .resources .resources.limits }}
{{- $limits = deepCopy .resources.limits }}
{{- end }}
{{- if or (gt (int $tensorParallelism) 1) (gt (int $dataLocalParallelism) 1) }}
{{- $limits = mergeOverwrite $limits (dict "nvidia.com/gpu" (mul $tensorParallelism $dataLocalParallelism)) }}
{{- end }}
{{- $requests := dict }}
{{- if and .resources .resources.requests }}
{{- $requests = deepCopy .resources.requests }}
{{- end }}
{{- if or (gt (int $tensorParallelism) 1) (gt (int $dataLocalParallelism) 1) }}
{{- $requests = mergeOverwrite $requests (dict "nvidia.com/gpu" (mul $tensorParallelism $dataLocalParallelism)) }}
{{- end }}
resources:
  limits:
    {{- toYaml $limits | nindent 4 }}
  requests:
    {{- toYaml $requests | nindent 4 }}
{{- end }}

{{/* P/D service account name */}}
{{- define "llm-d-modelservice.pdServiceAccountName" -}}
{{ include "llm-d-modelservice.fullname" . }}-sa
{{- end }}

{{/* 
EPP service account name 
Context is helm root context
*/}}
{{- define "llm-d-modelservice.eppServiceAccountName" -}}
{{ include "llm-d-modelservice.fullname" . }}-epp-sa
{{- end }}

{{/*
Volumes for PD containers based on model artifact prefix
Context is .Values.modelArtifacts
*/}}
{{- define "llm-d-modelservice.mountModelVolumeVolumes" -}}
{{- $parsedArtifacts := regexSplit "://" .uri -1 -}}
{{- $protocol := first $parsedArtifacts -}}
{{- $path := last $parsedArtifacts -}}
{{- if eq $protocol "hf" -}}
- name: model-storage
  emptyDir: 
    sizeLimit: {{ default "0" .size }}
{{- else if eq $protocol "pvc" }}
{{- $parsedArtifacts := regexSplit "/" $path -1 -}}
{{- $claim := first $parsedArtifacts -}}
- name: model-storage
  persistentVolumeClaim:
    claimName: {{ $claim }}
    readOnly: true
{{- else if eq $protocol "oci" }}
- name: model-storage
  image:
    reference: {{ $path }}
    pullPolicy: {{ default "Always" .imagePullPolicy }}
{{- end }}
{{- end }}

{{/*
VolumeMount for a PD container
Supplies model-storage mount if mountModelVolume: true for the container
*/}}
{{- define "llm-d-modelservice.mountModelVolumeVolumeMounts" -}}
{{- if or .volumeMounts .mountModelVolume }}
volumeMounts:
{{- end }}
{{- /* user supplied volume mount in values */}}
{{- with .volumeMounts }}
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- /* what we add if mounModelVolume is true */}}
{{- if .mountModelVolume }}
  - name: model-storage
    mountPath: /model-cache
{{- end }}
{{- end }}

{{/*
Pod elements of deployment/lws spec template
context is a pdSpec
*/}}
{{- define "llm-d-modelservice.modelPod" -}}
  {{- with .pdSpec.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  serviceAccountName: {{ include "llm-d-modelservice.pdServiceAccountName" . }}
  {{- with .pdSpec.podSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .pdSpec.acceleratorTypes }}
  {{- include "llm-d-modelservice.acceleratorTypes" . | nindent 2 }}
  {{- end -}}
  {{- /* define volume for the pd pod. Create a volume depending on the model artifact uri type */}}
  volumes:
  {{- if or .pdSpec.volumes }}
    {{- toYaml .pdSpec.volumes | nindent 4 }}
  {{- end -}}
  {{ include "llm-d-modelservice.mountModelVolumeVolumes" .Values.modelArtifacts | nindent 4}}
{{- end }} 

{{/*
Container elements of deployment/lws spec template
context is a dict with helm root context plus:
   key - "container"; value - container spec
   key - "roll"; value - either "decode" or "prefill"
   key - "parallelism"; value - $.Values.decode.parallelism
*/}}
{{- define "llm-d-modelservice.container" -}}
- name: {{ default "vllm" .container.name }}
  image: {{ required "image of container is required" .container.image }}
  {{- with .container.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .container.imagePullPolicy }}
  imagePullPolicy: {{ . }}
  {{- end }}
  {{- with .container.command }}
  command:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  args:
  {{- if not (default false .Values.scriptedStart) }}
  - {{ .Values.routing.modelName | quote }}
  - --port
  - {{ (include "llm-d-modelservice.vllmPort" .) | quote }}
  {{- end }}
  {{- with .container.args }}
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- /* insert user's env for this container */}}
  {{- if or .container.env .container.mountModelVolume }}
  env:
  {{- end }}
  {{- with .container.env }}
    {{- toYaml . | nindent 2 }}
  {{- end }}
  - name: DP_SIZE
    value: {{ include "llm-d-modelservice.dataParallelism" .parallelism | quote }}
  - name: TP_SIZE
    value: {{ include "llm-d-modelservice.tensorParallelism" .parallelism | quote }}
  - name: DP_SIZE_LOCAL
    value: {{ include "llm-d-modelservice.dataLocalParallelism" .parallelism | quote }}
  {{- /* insert envs based on what modelArtifact prefix */}}
  {{- if .container.mountModelVolume }}
  - name: HF_HOME
    value: /model-cache
  {{- with .Values.modelArtifacts.authSecretName }}
  - name: HF_TOKEN
    valueFrom:
      secretKeyRef:
        name: {{ . }}
        key: HF_TOKEN
  {{- end }}
  {{- end }}
  {{- with .container.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with .container.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- (include "llm-d-modelservice.resources" (dict "resources" .container.resources "parallelism" .parallelism)) | nindent 2 }}
  {{- /* volumeMount */}}
  {{- if or .container.volumeMounts .container.mountModelVolume }}
  volumeMounts:
  {{- end -}}
  {{- /* user supplied volume mount in values */}}
  {{- with .container.volumeMounts }}
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- /* what we add if mounModelVolume is true */}}
  {{- if .container.mountModelVolume }}
  - name: model-storage
    mountPath: /model-cache
  {{- end }}
  {{- with .container.workingDir }}
  workingDir: {{ . }}
  {{- end }}
  {{- with .container.stdin }}
  stdin: {{ . }}
  {{- end }}
  {{- with .container.tty }}
  tty: {{ . }}
  {{- end }}
{{- end }} {{- /* define "llm-d-modelservice.container" */}}
