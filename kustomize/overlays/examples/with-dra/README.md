# Dynamic Resource Allocation (DRA) Example

Demonstrates GPU allocation using Kubernetes DRA instead of standard resource limits.

## What's Different

Instead of:
```yaml
resources:
limits:
    nvidia.com/gpu: "1"

Uses:
resourceClaims:
- name: gpu-claim
    source:
    resourceClaimTemplateName: gpu-claim-template

Benefits

- Request specific GPU models (A100, H100, etc.)
- Request GPU memory sizes
- Request GPU topologies (NVLink, PCIe)
- More intelligent scheduling
- Better multi-GPU configurations

Prerequisites

- Kubernetes 1.26+ with DRA feature enabled
- NVIDIA DRA driver installed

Install NVIDIA DRA Driver

kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-dra-driver/main/deployments/static/nvidia-dra-driver.yaml

Deploy

kubectl apply -k kustomize/overlays/examples/with-dra/

Verify

# Check ResourceClaimTemplate
kubectl get resourceclaimtemplate

# Check ResourceClaims created for pods
kubectl get resourceclaim

# Check pod using DRA
kubectl describe pod <pod-name>
# Should see "Claims:" section instead of GPU in resources

Customize for Specific GPU

Request A100-80GB GPUs:

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

Clean Up

kubectl delete -k kustomize/overlays/examples/with-dra/

Reference
- https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/