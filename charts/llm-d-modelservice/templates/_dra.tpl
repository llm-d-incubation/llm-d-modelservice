{{/* DRA resources */}}

{{- define "llm-d-modelservice.draResources" -}}
{{- range .Values.dra.accelerator.claimTemplates }}
{{- if eq $.Values.dra.accelerator.type .name }}
  - name: {{ .name }}-resource-claim
{{- end -}}
{{- end -}}
{{- end }}

{{- define "llm-d-modelservice.existingDraResources" -}}
{{- range .Values.dra.existing.resourceClaimTemplates }}
  - name: {{ .claimTemplateName }}
{{- end }}
{{- end -}}

{{- define "llm-d-modelservice.draResourceClaims" -}}
{{- range .Values.dra.accelerator.claimTemplates }}
{{- if eq $.Values.dra.accelerator.type .name }}
- name: {{ .name }}-resource-claim
  resourceClaimTemplateName: {{ .name }}-resource-claim-template
{{- end }}
{{- end }}
{{- end -}}

{{- define "llm-d-modelservice.existingDraResourceClaims" -}}
{{- range .Values.dra.existing.resourceClaimTemplates }}
- name: {{ .claimTemplateName }}
  resourceClaimTemplateName: {{ .claimTemplateName }}
{{- end }}
{{- end -}}

{{- /* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#deviceclaim-v1-resource-k8s-io */}}
{{- /* Only subset of the features will be supported for now */ -}}
{{- define "llm-d-modelservice.draResourceClaimDeviceClaim" -}}
{{- $claim := dict }}
{{- range .Values.dra.accelerator.claimTemplates }}
{{- if eq $.Values.dra.accelerator.type .name }}
{{- $claim = dict "name" .name "class" .class "match" .match "count" .count "selectors" .selectors }}
{{- end -}}
{{- end -}}
requests:
- name: {{ $claim.name }}
  {{ $claim.match }}:
    deviceClassName: {{ $claim.class }}
    count: {{ $claim.count }}
    {{- if $claim.selectors }}
    selectors:
    {{- toYaml $claim.selectors | nindent 4 }}
    {{- end }}
{{- end }}
