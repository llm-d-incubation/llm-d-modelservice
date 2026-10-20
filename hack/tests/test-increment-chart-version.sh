#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
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
for invalid in v0.5.0-rc.1 1.2.3+build 1.2 invalid v01.2.3; do
  for bump in patch minor major; do
    printf 'version: "%s"\n' "$invalid" > charts/llm-d-modelservice/Chart.yaml
    cp charts/llm-d-modelservice/Chart.yaml before.yaml
    if bash "$repo/hack/increment-chart-version.sh" "$bump" > output.log 2>&1; then
      echo "Unexpected success for $invalid $bump" >&2
      exit 1
    fi
    cmp before.yaml charts/llm-d-modelservice/Chart.yaml
    if grep -q 'Version updated:' output.log; then
      echo 'Rejected version was reported as updated' >&2
      exit 1
    fi
  done
done
echo 'Six version bumps and 15 rejected version checks passed'
