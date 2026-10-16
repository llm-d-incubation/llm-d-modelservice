#!/usr/bin/env bash
# Check that failed Helm rendering cannot be reported as successful generation.
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/examples"
cat > "$test_dir/bin/helm" <<'STUB'
#!/usr/bin/env bash
printf 'simulated Helm failure\n' >&2
exit 42
STUB
chmod +x "$test_dir/bin/helm"
cd "$test_dir"
status=0
PATH="$test_dir/bin:$PATH" bash "$repo/hack/generate-example-output.sh" > output.log 2>&1 || status=$?
if [[ "$status" != 42 ]]; then
  echo "Expected Helm exit status 42, got $status" >&2
  exit 1
fi
if grep -q '^Generated:' output.log; then
  echo 'Failed rendering was reported as generated' >&2
  exit 1
fi
if [[ -e examples/output-dra.yaml ]]; then
  echo 'Generation continued after the first failure' >&2
  exit 1
fi
echo 'Helm failure propagation passed'
