# Intel i915 Accelerator

Support for Intel Integrated Graphics (i915 driver).

## Prerequisites

- Kubernetes nodes with Intel integrated graphics
- Intel GPU device plugin installed
- i915 kernel driver loaded

## Install Intel GPU Device Plugin

```bash
kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/nfd_labeled_nodes

GPU Resource Name

- gpu.intel.com/i915

Special Configuration

Same as Intel XE, requires:
- VLLM_USE_V1=1
- TORCH_LLM_ALLREDUCE=1
- VLLM_WORKER_MULTIPROC_METHOD=spawn

Usage

resources:
- ../../accelerators/intel-i915

Supported GPUs

- Intel Iris Xe Graphics
- Intel UHD Graphics
- Intel HD Graphics (newer generations)

Notes

- Integrated GPUs typically have less memory than discrete GPUs
- Suitable for smaller models or development/testing
- May have lower performance compared to discrete GPUs

Verify

kubectl get nodes -o json | jq '.items[].status.allocatable | select(.["gpu.intel.com/i915"] != null)'