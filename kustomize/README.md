# Kustomize Deployment for llm-d-modelservice

Deploy llm-d-modelservice using Kustomize with support for multiple accelerators and deployment modes. Overlays are aligned 1:1 with [llm-d guides](https://github.com/llm-d/llm-d/tree/main/guides).

## Quick Start

```bash
# Deploy inference-scheduling with Nvidia GPUs
kubectl apply -k kustomize/overlays/inference-scheduling/nvidia/

# Deploy P/D disaggregation with Nvidia GPUs
kubectl apply -k kustomize/overlays/pd-disaggregation/nvidia/

# Deploy simulated accelerators (no GPU required)
kubectl apply -k kustomize/overlays/simulated-accelerators/
```

## Directory Structure

```
kustomize/
├── base/                              # Base resources (all disabled by default)
│   ├── resources/                     # Deployments, LWS, ServiceAccount
│   ├── config/                        # ConfigMap generators
│   └── monitoring/                    # PodMonitors (always included)
│
├── accelerators/                      # Hardware accelerator support
│   ├── nvidia/                        # Nvidia GPUs (CUDA)
│   ├── nvidia-dra/                    # Nvidia GPUs with Dynamic Resource Allocation
│   ├── amd/                           # AMD GPUs (ROCm)
│   ├── amd-dra/                       # AMD GPUs with Dynamic Resource Allocation
│   ├── intel-xe/                      # Intel Data Center GPU Max
│   ├── intel-i915/                    # Intel Integrated Graphics
│   ├── intel-gaudi/                   # Intel Gaudi AI Accelerators
│   └── google-tpu/                    # Google Cloud TPUs
│
└── overlays/                          # Guide-aligned deployment overlays
    ├── inference-scheduling/          # Intelligent Inference Scheduling
    ├── pd-disaggregation/             # Prefill/Decode Disaggregation
    ├── wide-ep-lws/                   # Wide Expert Parallelism with LWS
    ├── workload-autoscaling/          # Autoscaling with WVA
    ├── simulated-accelerators/        # Accelerator Simulation (no GPU)
    ├── tiered-prefix-cache/           # Prefix Cache Offloading
    ├── precise-prefix-cache-aware/    # Precise Prefix Cache Routing
    └── predicted-latency-based-scheduling/  # Predicted Latency (placeholder)
```

## Architecture

### Base Layer

Base resources define all possible Kubernetes objects with everything disabled (replicas=0):
- ServiceAccount
- Decode Deployment + Prefill Deployment
- Decode LeaderWorkerSet + Prefill LeaderWorkerSet
- PodMonitors for Prometheus monitoring (always included)
- ConfigMaps (model, parallelism, routing)

Base is never deployed directly. It is a building block for accelerators and overlays.

### Accelerator Layer

Accelerator overlays add hardware-specific configuration on top of base:

| Accelerator | Resource Name      | DRA Available |
|-------------|--------------------|---------------|
| Nvidia GPU  | nvidia.com/gpu     | Yes           |
| AMD GPU     | amd.com/gpu        | Yes           |
| Intel XE    | gpu.intel.com/xe   | No            |
| Intel i915  | gpu.intel.com/i915 | No            |
| Intel Gaudi | habana.ai/gaudi    | No            |
| Google TPU  | google.com/tpu     | No            |

### Overlay Layer

Each overlay maps to an [llm-d guide](https://github.com/llm-d/llm-d/tree/main/guides) and contains accelerator sub-variants:

| Overlay | Guide | Accelerator Variants |
|---------|-------|---------------------|
| `inference-scheduling/` | Intelligent Inference Scheduling | nvidia, amd, intel-xpu, intel-gaudi, google-tpu |
| `pd-disaggregation/` | Prefill/Decode Disaggregation | nvidia, google-tpu, intel-xpu |
| `wide-ep-lws/` | Wide Expert Parallelism with LWS | nvidia |
| `workload-autoscaling/` | Autoscaling with WVA | nvidia |
| `simulated-accelerators/` | Accelerator Simulation | (none - CPU only) |
| `tiered-prefix-cache/` | Prefix Cache Offloading | nvidia |
| `precise-prefix-cache-aware/` | Precise Prefix Cache Routing | nvidia, intel-xpu |
| `predicted-latency-based-scheduling/` | Predicted Latency Scheduling | nvidia (placeholder) |

## Creating Custom Deployments

Copy an existing overlay and modify it:

```bash
# Copy an overlay as starting point
cp -r kustomize/overlays/inference-scheduling/nvidia kustomize/overlays/my-deployment

# Edit configuration
vim kustomize/overlays/my-deployment/kustomization.yaml

# Deploy
kubectl apply -k kustomize/overlays/my-deployment/
```

### Common Customizations

**Change Model:**
```yaml
configMapGenerator:
  - name: model-config
    behavior: merge
    literals:
      - modelName=meta-llama/Llama-3.3-70B-Instruct
      - modelUri=hf://meta-llama/Llama-3.3-70B-Instruct
      - modelSize=150Gi
```

**Scale Replicas:**
```yaml
patches:
  - target:
      kind: Deployment
      name: modelservice-decode
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 4
```

**Use DRA (Dynamic Resource Allocation):**
```yaml
# Reference the DRA variant of an accelerator
resources:
  - ../../accelerators/nvidia-dra
```

## Migration from Helm

| Helm Value                           | Kustomize Equivalent                         |
|--------------------------------------|----------------------------------------------|
| modelArtifacts.name                  | ConfigMap `modelName`                        |
| modelArtifacts.uri                   | ConfigMap `modelUri`                         |
| decode.replicas                      | Patch decode Deployment replicas             |
| accelerator.type                     | Choose accelerator directory                 |
| accelerator.dra                      | Use `accelerators/<type>-dra/`               |
| decode.monitoring.podmonitor.enabled | Monitoring included in base by default       |
