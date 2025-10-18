#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
CHART_PATH="charts/llm-d-modelservice"
TESTS_DIR="tests"

# Colors for readable output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Running Helm template rendering tests..."
echo "========================================"

# --- Test Case 1: Default Behavior ---
# Description: When no accelerator resource count is specified, it should default to the tensorParallelism size.
# Expected: nvidia.com/gpu: "4"
echo -n "TEST 1: Default accelerator resource count... "

RENDERED_DEFAULT=$(helm template ${CHART_PATH} -f ${CHART_PATH}/values.yaml -f ${TESTS_DIR}/test-values-default.yaml --show-only templates/decode-deployment.yaml)

# Check if the limits and requests for nvidia.com/gpu are both "4"
LIMIT_COUNT_DEFAULT=$(echo "$RENDERED_DEFAULT" | awk '/limits:/{flag=1;next}/requests:/{flag=0}flag' | grep 'nvidia.com/gpu:' | awk '{print $2}' | tr -d '"')
REQUEST_COUNT_DEFAULT=$(echo "$RENDERED_DEFAULT" | awk '/requests:/{flag=1;next}flag' | grep 'nvidia.com/gpu:' | awk '{print $2}' | tr -d '"')

if [ "$LIMIT_COUNT_DEFAULT" == "4" ] && [ "$REQUEST_COUNT_DEFAULT" == "4" ]; then
    echo -e "${GREEN}PASSED${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "  Expected GPU count: 4, but got Limits: ${LIMIT_COUNT_DEFAULT:-not found}, Requests: ${REQUEST_COUNT_DEFAULT:-not found}"
    exit 1
fi

# --- Test Case 2: User Override Behavior ---
# Description: When an accelerator resource count is specified by the user, it should be respected.
# Expected: nvidia.com/gpu: "2"
echo -n "TEST 2: User-override accelerator resource count... "

RENDERED_OVERRIDE=$(helm template ${CHART_PATH} -f ${CHART_PATH}/values.yaml -f ${TESTS_DIR}/test-values-override.yaml --show-only templates/decode-deployment.yaml)

# Check if the limits and requests for nvidia.com/gpu are both "8"
LIMIT_COUNT_OVERRIDE=$(echo "$RENDERED_OVERRIDE" | awk '/limits:/{flag=1;next}/requests:/{flag=0}flag' | grep 'nvidia.com/gpu:' | awk '{print $2}' | tr -d '"')
REQUEST_COUNT_OVERRIDE=$(echo "$RENDERED_OVERRIDE" | awk '/requests:/{flag=1;next}flag' | grep 'nvidia.com/gpu:' | awk '{print $2}' | tr -d '"')

if [ "$LIMIT_COUNT_OVERRIDE" == "8" ] && [ "$REQUEST_COUNT_OVERRIDE" == "8" ]; then
    echo -e "${GREEN}PASSED${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "  Expected GPU count: 8, but got Limits: ${LIMIT_COUNT_OVERRIDE:-not found}, Requests: ${REQUEST_COUNT_OVERRIDE:-not found}"
    exit 1
fi


echo "========================================"
echo -e "${GREEN}All tests passed successfully!${NC}"
