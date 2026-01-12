# Routing Proxy Component

Adds NIXL routing sidecar for request routing and P/D disaggregation.

## What it does

- Adds routing-proxy as init container to all pods
- Configures NIXL connector for routing
- Enables communication between prefill and decode pods

## When to use

- **Required** for Prefill/Decode disaggregation
- Optional for single-pod deployments (adds routing capabilities)

## How it works

┌─────────────────────────────────┐
│  Pod                             │
│  ┌────────────────────────────┐ │
│  │ routing-proxy init         │ │
│  │ - Listens on port 8000     │ │
│  │ - Routes to vLLM on 8200   │ │
│  │ - Handles P/D routing      │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ vLLM container             │ │
│  │ - Listens on 8200          │ │
│  └────────────────────────────┘ │
└─────────────────────────────────┘

## Usage

Include this component in your overlay:

```yaml
components:
- ../../components/routing-proxy

Configuration

The routing proxy is configured with:
- --port=8000: External port for incoming requests
- --vllm-port=8200: Internal port where vLLM listens (8000 for prefill)
- --connector=nixlv2: NIXL v2 protocol for P/D routing
- --zap-encoder=json: JSON logging
- --zap-log-level=debug: Debug logging level

Customization

Change Log Level

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/template/spec/initContainers/0/args/4
        value: --zap-log-level=info

Enable Secure Proxy

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: add
        path: /spec/template/spec/initContainers/0/args/-
        value: --secure-proxy=true

Verify

# Check init container is present
kubectl get pod <pod-name> -o jsonpath='{.spec.initContainers[*].name}'

# Check logs
kubectl logs <pod-name> -c routing-proxy
