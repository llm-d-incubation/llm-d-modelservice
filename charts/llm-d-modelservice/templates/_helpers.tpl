{{/*
Expand the name of the chart.
*/}}
{{- define "llm-d-modelservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 55 chars because some Kubernetes name fields are limited to 63 (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
We use 55 because we add up to 8 characters (`-prefill`)
*/}}
{{- define "llm-d-modelservice.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 55 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 55 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 55 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
Truncated to 63 characrters because Kubernetes label values are limited to this
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
      - --connector={{ .proxy.connector | default "nixlv2" }}
      - -v={{ default 5 .proxy.debugLevel }}
      {{- if hasKey .proxy "secure" }}
      - --secure-proxy={{ .proxy.secure }}
      {{- end }}
      {{- if hasKey .proxy "prefillerUseTLS" }}
      - --prefiller-use-tls={{ .proxy.prefillerUseTLS }}
      {{- end }}
      {{- if hasKey .proxy "certPath" }}
      - --cert-path={{ .proxy.certPath }}
      {{- end }}
    image: {{ required "routing.proxy.image must be specified" .proxy.image }}
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
{{- $limits := dict }}
{{- if and .resources .resources.limits }}
{{- $limits = deepCopy .resources.limits }}
{{- end }}
{{- if gt (int $tensorParallelism) 1 }}
{{- $limits = mergeOverwrite $limits (dict "nvidia.com/gpu" $tensorParallelism) }}
{{- end }}
{{- $requests := dict }}
{{- if and .resources .resources.requests }}
{{- $requests = deepCopy .resources.requests }}
{{- end }}
{{- if gt (int $tensorParallelism) 1 }}
{{- $requests = mergeOverwrite $requests (dict "nvidia.com/gpu" $tensorParallelism) }}
{{- end }}
resources:
  limits:
    {{- toYaml $limits | nindent 4 }}
  requests:
    {{- toYaml $requests | nindent 4 }}
{{- end }}

{{/* EPP name */}}
{{- define "llm-d-modelservice.eppName" -}}
{{ include "llm-d-modelservice.fullname" . }}-epp
{{- end }}

{{/* prefill name */}}
{{- define "llm-d-modelservice.prefillName" -}}
{{ include "llm-d-modelservice.fullname" . }}-prefill
{{- end }}

{{/* decode name */}}
{{- define "llm-d-modelservice.decodeName" -}}
{{ include "llm-d-modelservice.fullname" . }}-decode
{{- end }}

{{/* P/D service account name */}}
{{- define "llm-d-modelservice.pdServiceAccountName" -}}
{{ include "llm-d-modelservice.fullname" . }}
{{- end }}

{{/* EPP service account name */}}
{{- define "llm-d-modelservice.eppServiceAccountName" -}}
{{ include "llm-d-modelservice.eppName" . }}
{{- end }}

{{/* EPP service name */}}
{{- define "llm-d-modelservice.eppServiceName" -}}
{{ include "llm-d-modelservice.eppName" . }}
{{- end }}

{{/* EPP role name */}}
{{- define "llm-d-modelservice.eppRoleName" -}}
{{ include "llm-d-modelservice.eppName" . }}
{{- end }}

{{/* EPP rolebinding name */}}
{{- define "llm-d-modelservice.eppRoleBindingName" -}}
{{ include "llm-d-modelservice.eppName" . }}
{{- end }}

{{/* EPP Config name */}}
{{- define "llm-d-modelservice.eppConfigName" -}}
{{ include "llm-d-modelservice.eppName" . }}
{{- end }}

{{/* default inference pool name */}}
{{- define "llm-d-modelservice.inferencePoolName" -}}
{{- if .Values.routing.inferencePool.name -}}
{{- .Values.routing.inferencePool.name }}
{{- else -}}
{{ include "llm-d-modelservice.fullname" . }}
{{- end }}
{{- end }}

{{/* default inference model name */}}
{{- define "llm-d-modelservice.inferenceModelName" -}}
{{- if .Values.routing.inferenceModel.name -}}
{{- .Values.routing.inferenceModel.name }}
{{- else -}}
{{ include "llm-d-modelservice.fullname" . }}
{{- end -}}
{{- end }}

{{/* default http route name */}}
{{- define "llm-d-modelservice.httpRouteName" -}}
{{ include "llm-d-modelservice.fullname" . }}
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
{{/* supports pvc or pvc+hf prefixes */}}
{{- else if hasPrefix "pvc" $protocol }}
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
{{- if or .container.volumeMounts .container.mountModelVolume }}
volumeMounts:
{{- end }}
{{- /* user supplied volume mount in values */}}
{{- with .container.volumeMounts }}
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- /* what we add if mounModelVolume is true */}}
{{- if .container.mountModelVolume }}
  - name: model-storage
    mountPath: {{ .Values.modelArtifacts.mountPath }}
{{- end }}
{{- end }}

{{/*
Pod elements of deployment/lws spec template
context is a pdSpec
*/}}
{{- define "llm-d-modelservice.modelPod" -}}
  {{- with .pdSpec.extraConfig }}
    {{ include "common.tplvalues.render" ( dict "value" . "context" $ ) | nindent 2 }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.imagePullSecrets instead */ -}}
  {{- with .pdSpec.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.scheulerName instead */ -}}
  {{- if or .pdSpec.schedulerName .Values.schedulerName }}
  schedulerName: {{ .pdSpec.schedulerName | default .Values.schedulerName }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.securityContext instead */ -}}
  {{- with .pdSpec.podSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "llm-d-modelservice.pdServiceAccountName" . }}
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
  {{- with .container.extraConfig }}
    {{ include "common.tplvalues.render" ( dict "value" . "context" $ ) | nindent 2 }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.securityContext instead */ -}}
  {{- with .container.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.imagePullPolicy instead */ -}}
  {{- with .container.imagePullPolicy }}
  imagePullPolicy: {{ . }}
  {{- end }}
  {{- /* handle command and args */}}
  {{- include "llm-d-modelservice.command" . | nindent 2 }}
  {{- /* insert user's env for this container */}}
  env:
  {{- with .container.env }}
    {{- include "common.tplvalues.render" ( dict "value" . "context" $ ) | nindent 2 }}
  {{- end }}
  {{- (include "llm-d-modelservice.parallelismEnv" .) | nindent 2 }}
  {{- /* insert envs based on what modelArtifact prefix */}}
  {{- (include "llm-d-modelservice.hfEnv" .) | nindent 2 }}
  {{- with .container.ports }}
  ports:
    {{- include "common.tplvalues.render" ( dict "value" . "context" $ ) | nindent 2 }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.livenessProbe instead */ -}}
  {{- with .container.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.readinessProbe instead */ -}}
  {{- with .container.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.startupProbe instead */ -}}
  {{- with .container.startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- (include "llm-d-modelservice.resources" (dict "resources" .container.resources "parallelism" .parallelism)) | nindent 2 }}
  {{- include "llm-d-modelservice.mountModelVolumeVolumeMounts" (dict "container" .container "Values" .Values) | nindent 2 }}
  {{- /* DEPRECATED; use extraConfig.workingDir instead */ -}}
  {{- with .container.workingDir }}
  workingDir: {{ . }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.stdin instead */ -}}
  {{- with .container.stdin }}
  stdin: {{ . }}
  {{- end }}
  {{- /* DEPRECATED; use extraConfig.tty instead */ -}}
  {{- with .container.tty }}
  tty: {{ . }}
  {{- end }}
{{- end }} {{- /* define "llm-d-modelservice.container" */}}

{{- define "llm-d-modelservice.argsByProtocol" -}}
{{- $parsedArtifacts := regexSplit "://" .Values.modelArtifacts.uri -1 -}}
{{- $protocol := first $parsedArtifacts -}}
{{- $other := last $parsedArtifacts -}}
{{- if eq $protocol "hf" -}}
{{- /* $other is the the model */}}
  {{- if .modelArg }}
  - --model
  {{- end }}
  - {{ include "common.tplvalues.render" ( dict "value" $other "context" $ ) }}
{{- else if eq $protocol "pvc" }}
{{- /* $other is the PVC claim and the path to the model */}}
{{- $claimpath := regexSplit "/" $other 2 -}}
{{- $path := last $claimpath -}}
  {{- if .modelArg }}
  - --model
  {{- end }}
  - {{ .Values.modelArtifacts.mountPath }}/{{ $path }}
{{- else if eq $protocol "pvc+hf" }}
{{- $claimpath := regexSplit "/" $other -1 -}}
{{- $length := len $claimpath }}
{{- $namespace := index $claimpath (sub $length 2) -}}
{{- $modelID := last $claimpath -}}
  {{- if .modelArg }}
  - --model
  {{- end }}
  - {{ $namespace }}/{{ $modelID }}
{{- else if eq $protocol "oci" }}
{{- /* TBD */}}
{{- fail "arguments for oci:// not implemented" }}
{{- end }}
{{- end }} {{- /* define "llm-d-modelservice.argsByProtocol" */}}

{{- define "llm-d-modelservice.vllmServeModelCommand" -}}
{{- /* override command and set model and --port arguments */}}
command: ["vllm", "serve"]
args:
{{- (include "llm-d-modelservice.argsByProtocol" .) }}
  - --port
  - {{ (include "llm-d-modelservice.vllmPort" .) | quote }}
  {{- $tensorParallelism := int (include "llm-d-modelservice.tensorParallelism" .container.parallelism) -}}
  {{- if gt (int $tensorParallelism) 1 }}
  - --tensor-parallel-size
  - "$TP_SIZE"
  {{- end }}
  - --served-model-name
  - {{ .Values.modelArtifacts.name | quote }}
{{- with .container.args }}
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }} {{- /* define "llm-d-modelservice.vllmServeModelCommand" */}}

{{- define "llm-d-modelservice.imageDefaultModelCommand" -}}
{{- /* no command needed, set --model and --port arguments */}}
args:
{{- (include "llm-d-modelservice.argsByProtocol" (merge . (dict "modelArg" true))) }}
  - --port
  - {{ (include "llm-d-modelservice.vllmPort" .) | quote }}
  {{- $tensorParallelism := int (include "llm-d-modelservice.tensorParallelism" .container.parallelism) -}}
  {{- if gt (int $tensorParallelism) 1 }}
  - --tensor-parallel-size
  - "$TP_SIZE"
  {{- end }}
  - --served-model-name
  - {{ .Values.modelArtifacts.name | quote }}
{{- with .container.args }}
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }} {{- /* define "llm-d-modelservice.imageDefaultModelCommand" */}}

{{- define "llm-d-modelservice.customModelCommand" -}}
{{- /* use provided command and args (fail if no command) */}}
{{- if not .container.command }}
{{- fail "When .container.modelCommand not set or `custom`, a `command` is required." }}
{{- else }}
{{- with .container.command }}
command:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .container.args }}
args:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }} {{- /* define "llm-d-modelservice.modelCommandCustom" */}}

{{/*
Container elements of deployment/lws spec template
context is a dict with helm root context plus:
   key - "container"; value - container spec
   key - "roll"; value - either "decode" or "prefill"
   key - "parallelism"; value - $.Values.decode.parallelism
*/}}
{{- define "llm-d-modelservice.command" -}}
{{- $modelCommand := default "custom" .container.modelCommand -}}
{{- if eq $modelCommand "vllmServe" }}
{{- include "llm-d-modelservice.vllmServeModelCommand" . }}
{{- else if eq $modelCommand "imageDefault" }}
{{- include "llm-d-modelservice.imageDefaultModelCommand" . }}
{{- else if eq $modelCommand "custom" }}
{{- include "llm-d-modelservice.customModelCommand" . }}
{{- else }}
{{- fail ".container.modelCommand is not as expected. Valid values are `vllmServe`, `imageDefault` and `custom`." }}
{{- end }}
{{- end }} {{- /* define "llm-d-modelservice.command" */}}

{{- define "llm-d-modelservice.hfEnv" -}}
{{- $parsedArtifacts := regexSplit "://" .Values.modelArtifacts.uri -1 -}}
{{- $protocol := first $parsedArtifacts -}}
{{- $other := last $parsedArtifacts -}}
{{- if contains "hf" $protocol }}
{{- if eq $protocol "hf" }}
{{- if .container.mountModelVolume }}
- name: HF_HOME
  value: {{ .Values.modelArtifacts.mountPath }}
{{- end }}
{{- end }}
{{- if eq $protocol "pvc+hf" }}
{{- $claimpath := regexSplit "/" $other -1 -}}
{{- $length := len $claimpath }}
{{- $start := 1 }}
{{- $end := sub $length 2 }}
{{- $middle := slice $claimpath $start $end }}
{{- $hfhubcache := join "/" $middle }}
{{- if .container.mountModelVolume }}
- name: HF_HUB_CACHE
  value: /model-cache/{{ $hfhubcache }}
{{- end }}
{{- end }}
{{- end }}
{{- with .Values.modelArtifacts.authSecretName }}
- name: HF_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: HF_TOKEN
{{- end }}
{{- end }} {{- /* define "llm-d-modelservice.hfEnv" */}}

{{- define "llm-d-modelservice.parallelismEnv" -}}
- name: DP_SIZE
  value: {{ include "llm-d-modelservice.dataParallelism" .parallelism | quote }}
- name: TP_SIZE
  value: {{ include "llm-d-modelservice.tensorParallelism" .parallelism | quote }}
{{- end }} {{- /* define "llm-d-modelservice.parallelismEnv" */}}
