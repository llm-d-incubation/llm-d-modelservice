# Prefill/Decode Disaggregation Example

This example demonstrates P/D disaggregation architecture with separate prefill and decode pods.

## Architecture

┌─────────────────┐      ┌─────────────────┐
│ Prefill Pods    │      │ Decode Pods     │
│ (3 replicas)    │      │ (2 replicas)    │
│                 │      │                 │
│ Process prompts │──────│ Generate tokens │
│ Create KV cache │ KV   │ Use KV cache    │
│                 │cache │                 │
│ 1 GPU           │      │ 1 GPU           │
│ 24Gi memory     │      │ 32Gi memory     │
└─────────────────┘      └─────────────────┘
        ↓                        ↓
    NIXL routing proxy connects them

## Components Used

- Nvidia accelerator
- Routing proxy (NIXL v2)
- Prefill disaggregation

## Resource Configuration

**Prefill pods (compute-heavy):**
- Replicas: 3
- GPU: 1 per pod
- Memory: 24Gi
- CPU: 12 cores

**Decode pods (memory-heavy):**
- Replicas: 2
- GPU: 1 per pod
- Memory: 32Gi (more for KV cache)
- CPU: 16 cores

## Prerequisites

- Kubernetes cluster with Nvidia GPUs
- At least 5 GPUs total (3 for prefill + 2 for decode)
- Nvidia device plugin installed

## Deploy

```bash
kubectl apply -k kustomize/overlays/examples/pd-disaggregation/

Verify

# Check all pods running
kubectl get pods -l llm-d.ai/inferenceServing=true

# Should see 3 prefill + 2 decode pods
kubectl get pods -l llm-d.ai/role=prefill
kubectl get pods -l llm-d.ai/role=decode

# Check routing proxy logs
kubectl logs <prefill-pod> -c routing-proxy
kubectl logs <decode-pod> -c routing-proxy

When to Use

- High throughput requirements
- Long input prompts (prefill-heavy)
- Need independent scaling of prefill vs decode
- Different hardware for each phase
- Production workloads with varying prompt/generation lengths

Scaling

Scale prefill and decode independently:

# Scale prefill for more prompt processing
kubectl scale deployment modelservice-prefill --replicas=5

# Scale decode for more generation capacity
kubectl scale deployment modelservice-decode --replicas=4

Clean Up

kubectl delete -k kustomize/overlays/examples/pd-disaggregation/