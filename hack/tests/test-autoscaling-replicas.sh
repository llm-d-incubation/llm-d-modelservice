#!/usr/bin/env bash
# Render workloads to check who owns the replica count.
set -euo pipefail
cd "$(dirname "$0")/../.."

checks=0
for role in decode prefill encode; do
  for kind in deployment lws requester-replicaset; do
    [[ "$kind" == requester-replicaset && "$role" != decode ]] && continue
    multinode=false
    [[ "$kind" == lws ]] && multinode=true
    for replicas in default null 0 3; do
      replica_args=()
      expected=1
      if [[ "$replicas" == default ]]; then
        [[ "$role" != decode ]] && expected=0
      else
        # Helm removes null values, exercising the template's missing key fallback.
        replica_args+=(--set "$role.replicas=$replicas")
        [[ "$replicas" != null ]] && expected=$replicas
      fi
      for enabled in false true; do
        rendered=$(helm template test charts/llm-d-modelservice \
          --show-only "templates/$role-$kind.yaml" \
          --set "$role.create=true" --set "multinode=$multinode" \
          --set "requester.enable=$([[ "$kind" == requester-replicaset ]] && echo true || echo false)" \
          "${replica_args[@]}" --set "$role.autoscaling.enabled=$enabled")
        actual=$(printf '%s\n' "$rendered" | sed -n 's/^  replicas: //p')
        wanted=$expected
        [[ "$enabled" == true ]] && wanted=''
        if [[ "$actual" != "$wanted" ]]; then
          echo "$role $kind: autoscaling=$enabled replicas=$replicas: expected '$wanted', got '$actual'" >&2
          exit 1
        fi
        checks=$((checks + 1))
      done
    done
  done
done
echo "$checks autoscaling replica checks passed"
