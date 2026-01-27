{{/*
DRA (Dynamic Resource Allocation) Helper Functions
*/}}

{{/* Check if DRA is enabled */}}
{{- define "llm-d-modelservice.draEnabled" -}}
{{- if .Values.accelerator.dra -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* Get accelerator type */}}
{{- define "llm-d-modelservice.acceleratorType" -}}
{{- .Values.accelerator.type | default "nvidia" -}}
{{- end }}

{{/* Get accelerator claim name based on type */}}
{{- define "llm-d-modelservice.acceleratorClaimName" -}}
{{- $acceleratorType := include "llm-d-modelservice.acceleratorType" . -}}
{{- if hasKey .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $template := index .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $template.name | default (printf "%s-claim" $acceleratorType) -}}
{{- else -}}
  {{- printf "%s-claim" $acceleratorType -}}
{{- end -}}
{{- end }}

{{/* Get accelerator claim template name */}}
{{- define "llm-d-modelservice.acceleratorClaimTemplateName" -}}
{{- $acceleratorType := include "llm-d-modelservice.acceleratorType" . -}}
{{- if hasKey .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $template := index .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $template.name | default (printf "%s-claim-template" $acceleratorType) -}}
{{- else -}}
  {{- printf "%s-claim-template" $acceleratorType -}}
{{- end -}}
{{- end }}

{{/* Get DRA claim count (auto-calculate from parallelism if not set) */}}
{{- define "llm-d-modelservice.draClaimCount" -}}
{{- $acceleratorType := include "llm-d-modelservice.acceleratorType" . -}}
{{- $count := 1 -}}
{{- if hasKey .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $template := index .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- if hasKey $template "count" -}}
    {{- $count = $template.count -}}
  {{- else -}}
    {{- /* Auto-calculate from parallelism */}}
    {{- $count = int (include "llm-d-modelservice.numGpuPerWorker" .parallelism) -}}
  {{- end -}}
{{- else -}}
  {{- $count = int (include "llm-d-modelservice.numGpuPerWorker" .parallelism) -}}
{{- end -}}
{{- $count -}}
{{- end }}

{{/* Generate pod-level resourceClaims (merges accelerator + user-defined claims) */}}
{{- define "llm-d-modelservice.podResourceClaims" -}}
{{- $claims := list -}}
{{- $draEnabled := eq (include "llm-d-modelservice.draEnabled" .) "true" -}}
{{- if $draEnabled -}}
  {{- $claimName := include "llm-d-modelservice.acceleratorClaimName" . -}}
  {{- $templateName := include "llm-d-modelservice.acceleratorClaimTemplateName" . -}}
  {{- $claims = append $claims (dict "name" $claimName "resourceClaimTemplateName" $templateName) -}}
{{- end -}}
{{- if .pdSpec.resourceClaims -}}
  {{- $claims = concat $claims .pdSpec.resourceClaims -}}
{{- end -}}
{{- if $claims -}}
resourceClaims:
{{- toYaml $claims | nindent 2 }}
{{- end -}}
{{- end }}

{{/* Generate container-level resource claims (merges accelerator + user-defined claims) */}}
{{- define "llm-d-modelservice.containerResourceClaims" -}}
{{- $claims := list -}}
{{- $draEnabled := eq (include "llm-d-modelservice.draEnabled" .) "true" -}}
{{- if $draEnabled -}}
  {{- $claimName := include "llm-d-modelservice.acceleratorClaimName" . -}}
  {{- $claims = append $claims (dict "name" $claimName) -}}
{{- end -}}
{{- if and .resources .resources.claims -}}
  {{- if kindIs "slice" .resources.claims -}}
    {{- $claims = concat $claims .resources.claims -}}
  {{- else -}}
    {{- fail "resources.claims must be a list of objects with 'name' field, e.g., [{\"name\": \"claim-name\"}]" -}}
  {{- end -}}
{{- end -}}
{{- if $claims -}}
claims:
{{- toYaml $claims | nindent 2 }}
{{- end -}}
{{- end }}

{{/* Get DRA ResourceClaimTemplate configuration for the current accelerator type */}}
{{- define "llm-d-modelservice.draResourceClaimTemplateConfig" -}}
{{- $acceleratorType := include "llm-d-modelservice.acceleratorType" . -}}
{{- $config := dict -}}
{{- if hasKey .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $config = index .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
{{- end -}}
{{- $config | toJson -}}
{{- end }}
