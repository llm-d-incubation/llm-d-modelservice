# Single Node Nvidia GPU Deployment

This example demonstrates a simple single-node deployment with Nvidia GPU.

## Prerequisites
- Kubernetes cluster with Nvidia GPU support
- Nvidia device plugin installed
- Kustomize v3.7.0+

## Deploy

```bash
kubectl apply -k kustomize/overlays/examples/single-node-nvidia/

Preview

kustomize build kustomize/overlays/examples/single-node-nvidia/

Verify

kubectl get deployments -n default
kubectl get pods -n default
kubectl get configmaps -n default

Customize

Edit the kustomization.yaml to modify:
- Model name and URI
- Resource limits (CPU, memory, GPU count)
- Namespace

Clean Up

kubectl delete -k kustomize/overlays/examples/single-node-nvidia/