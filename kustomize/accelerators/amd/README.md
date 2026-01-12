# AMD GPU Accelerator

Support for AMD GPUs (Radeon Instinct MI series).

## Prerequisites

- Kubernetes cluster with AMD GPUs
- AMD GPU device plugin installed
- ROCm driver installed on nodes

## Install AMD GPU Device Plugin

```bash
kubectl apply -f https://raw.githubusercontent.com/ROCm/k8s-device-plugin/master/k8s-ds-amdgpu-dp.yaml

GPU Resource Name

- amd.com/gpu

Special Configuration

AMD GPUs use ROCm instead of CUDA:
- Ensure vLLM image supports ROCm
- May need ROCm-specific environment variables
- ROCm version compatibility with GPU

Usage

resources:
- ../../accelerators/amd

# May need ROCm-specific image
patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
   - op: replace
     path: /spec/template/spec/containers/0/image
     value: "vllm/vllm-openai:latest-rocm"
   - op: replace
     path: /spec/replicas
     value: 1

Supported GPUs

- AMD Instinct MI300X
- AMD Instinct MI250X
- AMD Instinct MI210
- AMD Instinct MI100

Memory

- MI300X: 192GB HBM3
- MI250X: 128GB HBM2e
- MI210: 64GB HBM2e

Verify

# Check GPU nodes
kubectl get nodes -o json | jq '.items[].status.allocatable | select(.["amd.com/gpu"] != null)'

# Check ROCm info on node
kubectl debug node/<node-name> -it --image=ubuntu -- rocm-smi