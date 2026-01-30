# Multinode with Monitoring Example

Multi-node deployment using LeaderWorkerSet with Prometheus monitoring for large models.

## Architecture

- 1 LeaderWorkerSet with 8 workers (1 leader + 7 workers)
- 8 GPUs total (tensor parallelism = 4)
- Prometheus monitoring enabled
- Suitable for 70B parameter models

## Components Used

- Nvidia accelerator
- Multinode (LeaderWorkerSet)
- Monitoring (PodMonitor)

## Resource Configuration

- Workers: 8 (1 leader + 7 workers)
- GPU per worker: 1
- Total GPUs: 8
- Memory per worker: 80Gi
- CPU per worker: 32 cores
- Tensor parallelism: 4

## Prerequisites

- Kubernetes cluster with 8+ Nvidia GPUs
- LeaderWorkerSet CRD installed
- Prometheus Operator installed
- Nvidia device plugin installed

## Install Dependencies

```bash
# LeaderWorkerSet
kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/v0.3.0/manifests.yaml

# Prometheus Operator
helm install prometheus prometheus-community/kube-prometheus-stack

Deploy

kubectl apply -k kustomize/overlays/examples/multinode-monitoring/

Verify

# Check LeaderWorkerSet
kubectl get leaderworkerset

# Check all worker pods
kubectl get pods -l llm-d.ai/role=decode

# Should see 8 pods (1 leader + 7 workers)

# Check monitoring
kubectl get podmonitor

View Metrics

kubectl port-forward svc/prometheus-operated 9090:9090

Monitor distributed inference metrics:
- Per-worker GPU utilization
- Inter-worker communication latency
- Tensor parallel efficiency

Clean Up

kubectl delete -k kustomize/overlays/examples/multinode-monitoring/