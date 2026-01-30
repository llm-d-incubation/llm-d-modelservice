# Fast Model Actuation (FMA) Requester Example

Demonstrates FMA dual-pod architecture for dynamic model serving.

## Architecture

Client Request
    ↓
┌──────────────────────┐
│ Requester Pod        │
│ - Request handling   │
│ - Worker management  │
│ - 1 replica          │
│ - 1 GPU, 512Mi RAM   │
└──────────────────────┘
    ↓
Spawns workers on-demand
    ↓
┌──────────────────────┐
│ Worker Pods          │
│ - Inference execution│
│ - Dynamic lifecycle  │
│ - Managed by FMA     │
└──────────────────────┘

## Components Used

- Nvidia accelerator
- FMA Requester component
- Standard decode Deployment (disabled)

## What Happens

1. Requester pod receives requests
2. Requester spawns worker pods as needed
3. Workers execute inference
4. Workers can be scaled down when idle
5. Fast model loading/unloading

## Prerequisites

- Kubernetes cluster with Nvidia GPUs
- FMA requester image available
- Understanding of FMA lifecycle

## Deploy

```bash
kubectl apply -k kustomize/overlays/examples/fma-requester/

Verify

# Check requester ReplicaSet and pod
kubectl get replicaset modelservice-decode-requester
kubectl get pods -l llm-d.ai/component=fma-requester

# Standard decode Deployment should be disabled
kubectl get deployment modelservice-decode
# Should show 0/0 replicas

# Check requester health
REQUESTER_POD=$(kubectl get pods -l llm-d.ai/component=fma-requester -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward $REQUESTER_POD 8080:8080 &
curl http://localhost:8080/health

Send Requests

The requester exposes SPI on port 8081:

kubectl port-forward $REQUESTER_POD 8081:8081 &

# Send inference request (example - actual API depends on FMA implementation)
curl -X POST http://localhost:8081/v1/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "gpt2",
    "prompt": "Hello, world!",
    "max_tokens": 50
}'

Monitor Worker Pods

FMA requester may spawn worker pods dynamically:

# Watch for worker pods being created/destroyed
kubectl get pods -w -l llm-d.ai/role=decode

Benefits

- Fast cold starts: Quick model loading
- Resource efficiency: Workers only run when needed
- Multi-model serving: Requester can manage multiple models
- Pay-per-use: Workers scale to zero when idle

Use Cases

- Serverless inference
- Multi-tenant model serving
- Development/testing environments
- Cost-optimized deployments

Configuration

The requester is configured with:
- 1 replica (can be increased for HA)
- 1 GPU (for managing workers)
- 512Mi memory
- 2 CPU cores

Workers are configured separately by the requester based on the FMA configuration.

Clean Up

kubectl delete -k kustomize/overlays/examples/fma-requester/

Notes

- Standard decode Deployment is disabled (replicas=0) when using FMA
- Worker lifecycle is managed by the requester, not Kubernetes directly
- Requires FMA-compatible model and configuration
- Check FMA requester logs for worker spawning events

References

- FMA Requester Component README
- https://github.com/llm-d-incubation/llm-d-fast-model-actuation-requester