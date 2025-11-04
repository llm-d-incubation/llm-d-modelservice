{{/* DRA resources */}}

{{- define "llm-d-modelservice.draResources" -}}
{{- $claim := dict }}
{{- range .Values.dra.claimTemplates }}
{{- if eq $.Values.dra.type .name }}
{{- $claim = dict "name" .name }}
{{- end -}}
{{- end -}}
resources:
  claims:
  - name: {{ $claim.name }}-resource-claim
{{- end }}

{{- define "llm-d-modelservice.draResourceClaims" -}}
{{- $claim := dict }}
{{- range .Values.dra.claimTemplates }}
{{- if eq $.Values.dra.type .name }}
{{- $claim = dict "name" .name }}
{{- end -}}
{{- end -}}
resourceClaims:
- name: {{ $claim.name }}-resource-claim
  resourceClaimTemplateName: {{ $claim.name }}-resource-claim-template
{{- end }}

{{- /* https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#deviceclaim-v1-resource-k8s-io */}}
{{- /* Only subset of the features will be supported for now */ -}}
{{- define "llm-d-modelservice.draResourceClaimDeviceClaim" -}}
{{- $claim := dict }}
{{- range .Values.dra.claimTemplates }}
{{- if eq $.Values.dra.type .name }}
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
