# Intel Gaudi Accelerator

Support for Intel Gaudi AI Accelerators (Gaudi 2, Gaudi 3).

## Prerequisites

- Kubernetes cluster with Intel Gaudi accelerators
- Habana device plugin installed
- Habana software stack installed on nodes

## Install Habana Device Plugin

```bash
kubectl apply -f https://vault.habana.ai/artifactory/docker-k8s-device-plugin/habana-k8s-device-plugin.yaml

GPU Resource Name

- habana.ai/gaudi

Special Configuration

Intel Gaudi typically requires Habana-optimized containers and libraries:
- Use Habana-optimized PyTorch
- Habana SynapseAI SDK
- May need different vLLM image or backend

Usage

resources:
- ../../accelerators/intel-gaudi

# Likely need custom image for Gaudi
patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/template/spec/containers/0/image
        value: "your-gaudi-optimized-vllm:latest"

Supported Hardware

- Intel Gaudi 2
- Intel Gaudi 3

Memory

- Gaudi 2: 96GB HBM2E per accelerator
- Gaudi 3: Higher memory capacity

Verify

kubectl get nodes -o json | jq '.items[].status.allocatable | select(.["habana.ai/gaudi"] != null)'