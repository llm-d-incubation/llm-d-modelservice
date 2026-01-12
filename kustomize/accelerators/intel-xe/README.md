# Intel XE Accelerator

Support for Intel Data Center GPU Max Series (XE architecture).

## Prerequisites

- Kubernetes cluster with Intel Data Center GPUs
- Intel GPU device plugin installed
- Intel GPU driver installed on nodes

## Install Intel GPU Device Plugin

```bash
kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/nfd_labeled_nodes

GPU Resource Name

- gpu.intel.com/xe

Special Configuration

Intel XE GPUs require specific environment variables for vLLM:
- VLLM_USE_V1=1: Use vLLM v1 API
- TORCH_LLM_ALLREDUCE=1: Enable optimized all-reduce for distributed inference
- VLLM_WORKER_MULTIPROC_METHOD=spawn: Use spawn method for multiprocessing

These are automatically configured by this accelerator overlay.

Usage

# overlays/my-deployment/kustomization.yaml
resources:
- ../../accelerators/intel-xe

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/replicas
        value: 1

Supported GPUs

- Intel Data Center GPU Max 1100
- Intel Data Center GPU Max 1550

Verify

# Check GPU nodes
kubectl get nodes -o json | jq '.items[].status.allocatable | select(.["gpu.intel.com/xe"] != null)'

# Check GPU allocation in pod
kubectl describe pod <pod-name> | grep gpu.intel.com/xe