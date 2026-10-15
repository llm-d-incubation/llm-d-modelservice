#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
cd "$test_dir"
git init -q
mkdir -p charts/llm-d-modelservice
for prefix in '' v; do
  for bump in patch minor major; do
    case "$bump" in
      patch) expected="${prefix}1.2.4" ;;
      minor) expected="${prefix}1.3.0" ;;
      major) expected="${prefix}2.0.0" ;;
    esac
    printf 'version: "%s1.2.3"\n' "$prefix" > charts/llm-d-modelservice/Chart.yaml
    bash "$repo/hack/increment-chart-version.sh" "$bump" >/dev/null
    actual=$(yq e '.version' charts/llm-d-modelservice/Chart.yaml)
    if [[ "$actual" != "$expected" ]]; then
      echo "$prefix $bump: expected $expected, got $actual" >&2
      exit 1
    fi
  done
done
echo 'All six chart version bumps passed'
