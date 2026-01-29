{{/*
DRA (Dynamic Resource Allocation) Helper Functions
*/}}

{{/* Check if DRA is enabled */}}
{{- define "llm-d-modelservice.draEnabled" -}}
{{- $draEnabled := false -}}
{{- if and .role (eq .role "decode") -}}
  {{- if and .Values.decode.accelerator (hasKey .Values.decode.accelerator "dra") -}}
    {{- $draEnabled = .Values.decode.accelerator.dra -}}
  {{- else -}}
    {{- $draEnabled = .Values.accelerator.dra | default false -}}
  {{- end -}}
{{- else if and .role (eq .role "prefill") -}}
  {{- if and .Values.prefill.accelerator (hasKey .Values.prefill.accelerator "dra") -}}
    {{- $draEnabled = .Values.prefill.accelerator.dra -}}
  {{- else -}}
    {{- $draEnabled = .Values.accelerator.dra | default false -}}
  {{- end -}}
{{- else -}}
  {{- $draEnabled = .Values.accelerator.dra | default false -}}
{{- end -}}
{{- if $draEnabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* Get accelerator type */}}
{{- define "llm-d-modelservice.acceleratorType" -}}
{{- if and .role (eq .role "decode") -}}
  {{- if and .Values.decode.accelerator (hasKey .Values.decode.accelerator "type") -}}
    {{- .Values.decode.accelerator.type -}}
  {{- else -}}
    {{- .Values.accelerator.type | default "nvidia" -}}
  {{- end -}}
{{- else if and .role (eq .role "prefill") -}}
  {{- if and .Values.prefill.accelerator (hasKey .Values.prefill.accelerator "type") -}}
    {{- .Values.prefill.accelerator.type -}}
  {{- else -}}
    {{- .Values.accelerator.type | default "nvidia" -}}
  {{- end -}}
{{- else -}}
  {{- .Values.accelerator.type | default "nvidia" -}}
{{- end -}}
{{- end }}

{{/* Get accelerator claim name based on type */}}
{{- define "llm-d-modelservice.acceleratorClaimName" -}}
{{- $acceleratorType := include "llm-d-modelservice.acceleratorType" . -}}
{{- $role := .role | default "" -}}
{{- if hasKey .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $template := index .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- if $role -}}
    {{- if $template.name -}}
      {{- printf "%s-%s-claim" (trimSuffix "-claim-template" $template.name) $role -}}
    {{- else -}}
      {{- printf "%s-%s-claim" $acceleratorType $role -}}
    {{- end -}}
  {{- else -}}
    {{- $template.name | default (printf "%s-claim" $acceleratorType) -}}
  {{- end -}}
{{- else -}}
  {{- if $role -}}
    {{- printf "%s-%s-claim" $acceleratorType $role -}}
  {{- else -}}
    {{- printf "%s-claim" $acceleratorType -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{/* Get accelerator claim template name */}}
{{- define "llm-d-modelservice.acceleratorClaimTemplateName" -}}
{{- $acceleratorType := include "llm-d-modelservice.acceleratorType" . -}}
{{- $role := .role | default "" -}}
{{- if hasKey .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- $template := index .Values.accelerator.resourceClaimTemplates $acceleratorType -}}
  {{- if $role -}}
    {{- if $template.name -}}
      {{- printf "%s-%s" $template.name $role -}}
    {{- else -}}
      {{- printf "%s-%s-claim-template" $acceleratorType $role -}}
    {{- end -}}
  {{- else -}}
    {{- $template.name | default (printf "%s-claim-template" $acceleratorType) -}}
  {{- end -}}
{{- else -}}
  {{- if $role -}}
    {{- printf "%s-%s-claim-template" $acceleratorType $role -}}
  {{- else -}}
    {{- printf "%s-claim-template" $acceleratorType -}}
  {{- end -}}
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

{{/* Generate resourceClaims Variable (merges accelerator + user-defined claims) */}}
{{- define "llm-d-modelservice.resourceClaimsBase" -}}
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
{{- toYaml $claims }}
{{- end -}}
{{- end }}

{{- define "llm-d-modelservice.podResourceClaims" -}}
{{- $claimList := include "llm-d-modelservice.resourceClaimsBase" . -}}
{{- if $claimList -}}
resourceClaims:
{{- $claimList | nindent 2 }}
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
