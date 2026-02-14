# DRA (Dynamic Resource Allocation) Component

Enables GPU allocation via Kubernetes Dynamic Resource Allocation instead of standard resource limits.

## What it does

- Creates ResourceClaimTemplate for GPU allocation
- Replaces `nvidia.com/gpu` resource limits with resourceClaims
- Provides more flexible GPU scheduling

## Benefits over Standard Resource Limits

- **Fine-grained control**: Request specific GPU models, memory sizes
- **Multi-GPU topologies**: Request specific GPU interconnect topologies
- **Dynamic allocation**: GPUs allocated on-demand
- **Better scheduling**: More intelligent GPU placement

## Prerequisites

- Kubernetes 1.26+ with DRA enabled
- DRA-capable GPU driver/plugin (e.g., NVIDIA DRA driver)
- ResourceClass configured in cluster

## Install NVIDIA DRA Driver (Example)

```bash
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-dra-driver/main/deployments/static/nvidia-dra-driver.yaml

Usage

Include this component in your overlay:

components:
- ../../components/dra

Note: This component removes standard nvidia.com/gpu resource limits and replaces them with DRA claims.

Customization

Request Specific GPU Model

# In your overlay
patches:
- target:
    kind: ResourceClaimTemplate
    name: gpu-claim-template
    patch: |-
    - op: add
        path: /spec/spec/parametersRef
        value:
        apiGroup: gpu.resource.nvidia.com
        kind: GpuClaimParameters
        name: a100-80gb

Request Multiple GPUs

patches:
- target:
    kind: ResourceClaimTemplate
    name: gpu-claim-template
    patch: |-
    - op: add
        path: /spec/spec/count
        value: 2

Verify

# Check ResourceClaimTemplate
kubectl get resourceclaimtemplate

# Check ResourceClaims created
kubectl get resourceclaim

# Check pod using claim
kubectl describe pod <pod-name>

See Also

- https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/
- https://github.com/NVIDIA/k8s-dra-driver