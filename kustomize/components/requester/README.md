# FMA Requester Component

Enables Fast Model Actuation (FMA) using a dual-pod architecture.

## What is FMA?

Fast Model Actuation is a pattern where:
- **Requester pod**: Lightweight pod handling request orchestration
- **Worker pod**: Heavy inference pod (separate, managed by requester)

## Architecture

┌─────────────────────────┐
│ Requester Pod           │
│ - Handles requests      │
│ - Orchestrates workers  │
│ - Lightweight (250Mi)   │
│ - 1 GPU                 │
└────────┬────────────────┘
        │
        │ Manages/coordinates
        ↓
┌─────────────────────────┐
│ Worker Pods             │
│ - Heavy inference       │
│ - Spawned on-demand     │
│ - Managed by requester  │
└─────────────────────────┘

## What it does

- Creates a ReplicaSet for the requester pod
- Disables standard decode Deployment (replicas=0)
- Requester manages inference workers dynamically

## When to use

- Fast model loading/unloading
- Dynamic worker scaling
- Resource-efficient multi-model serving
- Pay-per-use inference patterns

## Prerequisites

- FMA requester image available
- Understanding of FMA architecture
- Compatible worker configuration

## Usage

Include this component in your overlay:

```yaml
components:
- ../../components/requester

Note: This disables the standard decode Deployment. The requester manages workers separately.

Configuration

The requester uses:
- Probes port: 8080 (health checks)
- SPI port: 8081 (Service Provider Interface)
- Resources: 1 GPU, 1 CPU, 250Mi memory

Customization

Override requester configuration:

patches:
- target:
    kind: ReplicaSet
    name: modelservice-decode-requester
    patch: |-
    - op: replace
        path: /spec/replicas
        value: 2
    - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: "512Mi"

Verify

# Check requester pod
kubectl get replicaset modelservice-decode-requester
kubectl get pods -l llm-d.ai/component=fma-requester

# Check requester logs
kubectl logs -l llm-d.ai/component=fma-requester

# Check health endpoint
kubectl port-forward <requester-pod> 8080:8080
curl http://localhost:8080/health

References

  - Fast Model Actuation Documentation
  - https://github.com/llm-d-incubation/llm-d-fast-model-actuation-requester