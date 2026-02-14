# Kustomize Deployment for llm-d-modelservice

Deploy llm-d-modelservice using Kustomize with support for multiple accelerators, deployment modes, and optional features.

## Quick Start

Deploy a single-node model with Nvidia GPU:

```bash
kubectl apply -k kustomize/overlays/examples/single-node-nvidia/

Directory Structure

kustomize/
├── base/                    # Base resources (all disabled by default)
│   ├── config/             # ConfigMap generators
│   ├── resources/          # Base Kubernetes resources
│   └── kustomization.yaml
│
├── accelerators/           # Hardware accelerator support
│   ├── nvidia/            # Nvidia GPUs (CUDA)
│   ├── intel-xe/          # Intel Data Center GPU Max
│   ├── intel-i915/        # Intel Integrated Graphics
│   ├── intel-gaudi/       # Intel Gaudi AI Accelerators
│   ├── amd/               # AMD GPUs (ROCm)
│   └── google-tpu/        # Google Cloud TPUs
│
├── components/            # Optional features (composable)
│   ├── multinode/         # LeaderWorkerSet for multi-GPU
│   ├── monitoring/        # Prometheus PodMonitor
│   ├── dra/               # Dynamic Resource Allocation
│   ├── routing-proxy/     # NIXL routing sidecar
│   ├── prefill-disaggregation/  # Enable prefill pods
│   └── requester/         # Fast Model Actuation (FMA)
│
└── overlays/
    └── examples/          # Complete deployment examples
        ├── single-node-nvidia/       # Basic single GPU
        ├── multinode-nvidia/         # Multi-GPU with LWS
        ├── pd-disaggregation/        # Prefill/Decode split
        ├── with-monitoring/          # Prometheus metrics
        ├── with-dra/                 # Dynamic GPU allocation
        ├── intel-xpu/                # Intel GPU deployment
        ├── multinode-monitoring/     # Large model + metrics
        └── fma-requester/            # Fast Model Actuation

Architecture Overview

Base Layer

Base resources define all possible Kubernetes objects with everything disabled (replicas=0):
- ServiceAccount
- Decode Deployment
- Prefill Deployment
- Decode LeaderWorkerSet
- Prefill LeaderWorkerSet

Base is never deployed directly. It's a building block for overlays.

Accelerator Layer

Accelerator overlays add hardware-specific configuration:
- GPU resource limits (e.g., nvidia.com/gpu, gpu.intel.com/xe)
- Required environment variables
- Node affinity/selectors

Component Layer

Components are composable features that can be mixed and matched:
- Enable/disable optional features
- Add init containers, sidecars
- Modify resource types (Deployment ↔ LeaderWorkerSet)

Overlay Layer

Overlays combine accelerators + components + custom configuration for complete deployments.

Supported Accelerators

| Accelerator | Resource Name      | Special Requirements       |
|-------------|--------------------|----------------------------|
| Nvidia GPU  | nvidia.com/gpu     | None (default)             |
| Intel XE    | gpu.intel.com/xe   | Env vars (auto-configured) |
| Intel i915  | gpu.intel.com/i915 | Env vars (auto-configured) |
| Intel Gaudi | habana.ai/gaudi    | Custom image required      |
| AMD GPU     | amd.com/gpu        | ROCm image required        |
| Google TPU  | google.com/tpu     | JAX/TF image required      |

Available Components

Multinode

Enables multi-GPU deployment using LeaderWorkerSet:
- Disables single-pod Deployments
- Enables LeaderWorkerSet resources
- Configures worker group size

Use when: Training or serving large models across multiple GPUs

Monitoring

Adds Prometheus monitoring:
- Creates PodMonitor resources
- Exposes vLLM metrics
- Requires Prometheus Operator

Use when: Production deployments needing observability

DRA (Dynamic Resource Allocation)

Uses Kubernetes DRA for GPU allocation:
- More flexible than standard resource limits
- Request specific GPU models/topologies
- Requires K8s 1.26+ and DRA driver

Use when: Need fine-grained GPU control

Routing Proxy

Adds NIXL routing sidecar:
- Handles request routing
- Enables KV cache transfer
- Required for P/D disaggregation

Use when: Using prefill/decode disaggregation

Prefill Disaggregation

Enables separate prefill pods:
- Allows independent scaling
- Different resources for prefill vs decode
- Requires routing-proxy component

Use when: High throughput, long prompts, or different hardware per phase

Requester (FMA)

Fast Model Actuation dual-pod architecture:
- Lightweight requester orchestrates workers
- Dynamic worker lifecycle
- Efficient multi-model serving

Use when: Serverless inference, fast cold starts

Example Deployments

Single Node (Simplest)

kubectl apply -k kustomize/overlays/examples/single-node-nvidia/

What you get:
- 1 decode pod
- 1 Nvidia GPU
- No monitoring or special features

---
Multi-Node (Large Models)

kubectl apply -k kustomize/overlays/examples/multinode-nvidia/

What you get:
- LeaderWorkerSet with 4 workers (1 leader + 3 workers)
- 4 GPUs total
- Tensor parallelism across GPUs

---
Prefill/Decode Disaggregation (High Throughput)

kubectl apply -k kustomize/overlays/examples/pd-disaggregation/

What you get:
- 3 prefill pods (process prompts)
- 2 decode pods (generate tokens)
- NIXL routing between them
- Independent scaling

---
With Monitoring (Production)

kubectl apply -k kustomize/overlays/examples/with-monitoring/

What you get:
- 2 decode pods
- Prometheus PodMonitor
- Metrics exposed on /metrics

---
Intel XPU

kubectl apply -k kustomize/overlays/examples/intel-xpu/

What you get:
- 1 decode pod with Intel GPU
- Intel-specific environment variables
- Optimized for Intel Data Center GPU Max

---
Creating Custom Deployments

Method 1: Copy and Modify Example

# Copy an example
cp -r kustomize/overlays/examples/single-node-nvidia kustomize/overlays/my-deployment

# Edit configuration
vim kustomize/overlays/my-deployment/kustomization.yaml

# Deploy
kubectl apply -k kustomize/overlays/my-deployment/

Method 2: Compose from Scratch

mkdir -p kustomize/overlays/my-custom-deployment

cat > kustomize/overlays/my-custom-deployment/kustomization.yaml <<YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: my-namespace

# Choose accelerator
resources:
- ../../accelerators/nvidia

# Add optional components
components:
- ../../components/monitoring
- ../../components/routing-proxy

# Customize configuration
configMapGenerator:
- name: model-config
    behavior: merge
    literals:
    - modelName=my-org/my-model
    - modelUri=hf://my-org/my-model
    - modelSize=100Gi

# Enable and configure pods
patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/replicas
        value: 2
    - op: add
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: "64Gi"
YAML

kubectl apply -k kustomize/overlays/my-custom-deployment/

Common Customizations

Change Model

configMapGenerator:
- name: model-config
    behavior: merge
    literals:
    - modelName=meta-llama/Llama-2-13b-hf
    - modelUri=hf://meta-llama/Llama-2-13b-hf
    - modelSize=50Gi

Scale Replicas

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/replicas
        value: 5

Change GPU Count

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/template/spec/containers/0/resources/limits/nvidia.com~1gpu
        value: "2"

Use Custom Image

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/template/spec/containers/0/image
        value: "my-registry/vllm:custom"

Add Environment Variables

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
        name: MY_CUSTOM_VAR
        value: "my-value"

Migration from Helm

If you're currently using the Helm chart:

1. Export Current Values

helm get values my-release > current-values.yaml

2. Choose Matching Overlay

- Single node → single-node-nvidia
- Multi-node → multinode-nvidia
- P/D disaggregation → pd-disaggregation
- With monitoring → with-monitoring

3. Map Helm Values to Kustomize

| Helm Value                           | Kustomize Equivalent             |
|--------------------------------------|----------------------------------|
| modelArtifacts.name                  | ConfigMap modelName              |
| modelArtifacts.uri                   | ConfigMap modelUri               |
| decode.replicas                      | Patch decode Deployment replicas |
| multinode: true                      | Include multinode component      |
| decode.monitoring.podmonitor.enabled | Include monitoring component     |
| accelerator.type                     | Choose accelerator overlay       |

4. Deploy with Kustomize

kubectl apply -k kustomize/overlays/<chosen-overlay>/