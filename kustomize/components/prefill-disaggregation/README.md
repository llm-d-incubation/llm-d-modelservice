# Prefill Disaggregation Component

Enables prefill pods for Prefill/Decode disaggregation architecture.

## What it does

- Enables prefill Deployment (sets replicas > 0)
- Allows independent scaling of prefill and decode pods

## When to use

- High-throughput scenarios
- Long prompts (prefill-heavy workload)
- Need to scale prefill and decode independently
- Different hardware for prefill vs decode

## Architecture

┌──────────────┐      ┌──────────────┐
│ Prefill Pods │      │  Decode Pods │
│              │      │              │
│ Process      │      │ Generate     │
│ prompts  ────┼──────┼→ tokens      │
│ Create KV    │ KV   │ Use KV cache │
│ cache        │ cache│              │
└──────────────┘      └──────────────┘

## Prerequisites

- **Routing proxy component** is required
- Handles KV cache transfer between prefill and decode
- Use `routing-proxy` component

## Usage

Include this component with routing-proxy:

```yaml
components:
- ../../components/routing-proxy
- ../../components/prefill-disaggregation

Default Configuration

- Prefill Deployment: replicas = 1
- Prefill LWS: replicas = 0 (single-node by default)

Scaling

Scale Prefill Pods

patches:
- target:
    kind: Deployment
    name: modelservice-prefill
    patch: |-
    - op: replace
        path: /spec/replicas
        value: 3  # 3 prefill pods

Multinode Prefill

Use with multinode component:

components:
- ../../components/multinode
- ../../components/routing-proxy
- ../../components/prefill-disaggregation

patches:
# Enable prefill LWS
- target:
    kind: LeaderWorkerSet
    name: modelservice-prefill-lws
    patch: |-
    - op: replace
        path: /spec/replicas
        value: 2

Resource Planning

Prefill-heavy workload:
- More prefill pods
- Higher compute GPUs for prefill
- Less memory per prefill pod

Decode-heavy workload:
- More decode pods
- Higher memory GPUs for decode
- More memory per decode pod

Verify

# Check both prefill and decode pods running
kubectl get pods -l llm-d.ai/role=prefill
kubectl get pods -l llm-d.ai/role=decode

# Check routing proxy logs
kubectl logs <prefill-pod> -c routing-proxy
kubectl logs <decode-pod> -c routing-proxy