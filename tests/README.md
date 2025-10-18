# Template Rendering Tests

**Note:** This is a temporary and basic test suite to validate the chart's rendering logic. It is intended as a stopgap solution until a more formal testing framework like [helm-unittest](https://github.com/helm-unittest/helm-unittest) is adopted by the project.

## Purpose

This test suite uses `helm template` to render the chart with different value configurations and verifies that the output Kubernetes manifests are generated correctly.

## How to Run

From the root directory of the `llm-d-modelservice` repository, execute the script:

```bash
./tests/run-template-tests.sh
```

The script will run a series of test cases and report whether they passed or failed.
