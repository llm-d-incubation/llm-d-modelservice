# Multinode Nvidia GPU Deployment

This example demonstrates a multi-node deployment using LeaderWorkerSet with Nvidia GPUs.

## Prerequisites
- Kubernetes cluster with Nvidia GPU support
- Nvidia device plugin installed
- LeaderWorkerSet CRD installed
- Kustomize v3.7.0+

## What This Deploys

- 1 LeaderWorkerSet with 4 workers (1 leader + 3 workers)
- Each worker has 1 Nvidia GPU
- Tensor parallelism = 2
- Total of 4 GPUs used

## Install LeaderWorkerSet CRD

```bash
kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/v0.3.0/manifests.yaml

Deploy

kubectl apply -k kustomize/overlays/examples/multinode-nvidia/

Preview

kustomize build kustomize/overlays/examples/multinode-nvidia/

Verify

# Check LeaderWorkerSet
kubectl get leaderworkerset -n default

# Check pods created by LWS
kubectl get pods -n default -l llm-d.ai/role=decode

# Check resources
kubectl describe leaderworkerset modelservice-decode-lws -n default

Customize

Edit kustomization.yaml to modify:
- Number of replicas
- Worker group size (leaderWorkerTemplate.size)
- Tensor parallelism (TP_SIZE env var)
- GPU count per worker
- Memory/CPU limits

Example: 8 GPUs with TP=4

patches:
- target:
    kind: LeaderWorkerSet
    name: modelservice-decode-lws
    patch: |-
    - op: replace
        path: /spec/leaderWorkerTemplate/size
        value: 8  # 1 leader + 7 workers
    - op: replace
        path: /spec/leaderWorkerTemplate/workerTemplate/spec/containers/0/env/1/value
        value: "4"  # TP_SIZE

Clean Up

kubectl delete -k kustomize/overlays/examples/multinode-nvidia/

Notes

- The Deployment resources are still created but with replicas=0 (disabled)
- Only LeaderWorkerSet resources are active
- All workers in a group share the same pod spec