# Google TPU Accelerator

Support for Google Cloud TPUs (Tensor Processing Units).

## Prerequisites

- Google Kubernetes Engine (GKE) cluster with TPU node pools
- TPU drivers installed (automatic on GKE TPU nodes)
- JAX or TensorFlow framework support

## GPU Resource Name

- `google.com/tpu`

## Special Configuration

TPUs require specific configurations:
- TPU-optimized frameworks (JAX, TensorFlow)
- vLLM may have limited TPU support
- Different pod topology requirements
- TPU slices for multi-chip configurations

## Usage

```yaml
resources:
- ../../accelerators/google-tpu

# Likely need TPU-specific image and configuration
patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: replace
        path: /spec/template/spec/containers/0/image
        value: "your-tpu-optimized-image:latest"

Supported TPU Versions

- TPU v5e (Cloud TPU v5 Lite)
- TPU v5p (Cloud TPU v5)
- TPU v4

TPU Topology

TPUs are typically allocated in slices:
- Single TPU chip: 1 chip
- TPU Pod slice: 8, 16, 32, 64+ chips

For multi-chip, use LeaderWorkerSet or multi-host configurations.

Node Selection

TPU pods require specific node selectors:

patches:
- target:
    kind: Deployment
    name: modelservice-decode
    patch: |-
    - op: add
        path: /spec/template/spec/nodeSelector
        value:
        cloud.google.com/gke-tpu-accelerator: tpu-v5-lite-podslice
        cloud.google.com/gke-tpu-topology: 2x2x1

Verify

# Check TPU nodes
kubectl get nodes -l cloud.google.com/gke-accelerator

# Check TPU resources
kubectl describe node <tpu-node-name> | grep google.com/tpu