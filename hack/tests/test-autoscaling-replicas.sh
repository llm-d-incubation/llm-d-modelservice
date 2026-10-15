#!/usr/bin/env bash
# Render both workload kinds to check who owns the replica count.
set -euo pipefail
cd "$(dirname "$0")/../.."

for role in decode prefill encode; do
  for kind in deployment lws; do
    multinode=false
    [[ "$kind" == lws ]] && multinode=true
    for replicas in 0 3; do
      for enabled in false true; do
        rendered=$(helm template test charts/llm-d-modelservice \
          --show-only "templates/$role-$kind.yaml" \
          --set "$role.create=true" --set "multinode=$multinode" \
          --set "$role.replicas=$replicas" \
          --set "$role.autoscaling.enabled=$enabled")
        actual=$(printf '%s\n' "$rendered" | sed -n 's/^  replicas: //p')
        expected=$replicas
        [[ "$enabled" == true ]] && expected=''
        if [[ "$actual" != "$expected" ]]; then
          echo "$role $kind: autoscaling=$enabled replicas=$replicas: expected '$expected', got '$actual'" >&2
          exit 1
        fi
      done
    done
  done
done
echo '24 autoscaling replica checks passed'
