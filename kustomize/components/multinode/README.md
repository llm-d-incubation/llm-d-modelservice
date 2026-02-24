# Multinode Component

This component enables multi-node deployment using LeaderWorkerSet (LWS).

## What it does

- Disables single-node Deployments (sets replicas to 0)
- Enables LeaderWorkerSet resources
- Configures worker group size based on parallelism

## Usage

Include this component in your overlay:

```yaml
components:
- ../../components/multinode

Configuration

The default configuration creates:
- 1 LeaderWorkerSet replica
- Worker group size of 2 (1 leader + 1 worker)

To customize, add patches in your overlay:

patches:
- target:
    kind: LeaderWorkerSet
    name: modelservice-decode-lws
    patch: |-
    - op: replace
        path: /spec/replicas
        value: 2
    - op: replace
        path: /spec/leaderWorkerTemplate/size
        value: 4  # 1 leader + 3 workers

Prerequisites

- LeaderWorkerSet CRD installed in cluster
- Kustomize v3.7.0+ (for component support)

See Also

- https://github.com/kubernetes-sigs/lws