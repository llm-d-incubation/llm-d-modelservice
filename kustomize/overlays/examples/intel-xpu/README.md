# Intel XPU (Data Center GPU) Example

Deployment example for Intel Data Center GPU Max Series.

## What's Included

- Intel XE GPU support
- Required environment variables (VLLM_USE_V1, etc.)
- TinyLlama-1.1B model
- Single decode pod

## Prerequisites

- Kubernetes cluster with Intel Data Center GPUs
- Intel GPU device plugin installed
- Intel GPU drivers on nodes

## Install Intel GPU Device Plugin

```bash
kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/nfd_labeled_nodes

Deploy

kubectl apply -k kustomize/overlays/examples/intel-xpu/

Verify

# Check GPU allocation
kubectl describe pod <pod-name> | grep gpu.intel.com/xe

# Check environment variables
kubectl exec <pod-name> -- env | grep VLLM

Expected Environment

The Intel XE accelerator automatically sets:
- VLLM_USE_V1=1
- TORCH_LLM_ALLREDUCE=1
- VLLM_WORKER_MULTIPROC_METHOD=spawn

Supported Models

Intel XPU works best with:
- Smaller models (< 13B parameters)
- Models optimized for Intel GPUs
- Standard Hugging Face models

Performance Tips

- Use BF16 precision for better performance
- Enable Flash Attention if supported
- Use tensor parallelism for larger models

Clean Up

kubectl delete -k kustomize/overlays/examples/intel-xpu/