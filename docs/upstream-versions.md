# Upstream Dependency Version Tracking

> This file is the source of truth for the [upstream dependency monitor](../.github/workflows/upstream-monitor.md) workflow.
> Add your project's key upstream dependencies below. The monitor runs daily and creates GitHub issues when breaking changes are detected.

## Dependencies

| Dependency | Current Pin | Pin Type | File Location | Upstream Repo |
|-----------|-------------|----------|---------------|---------------|
| **LeaderWorkerSet (LWS)** | `v0.9.0` | tag | CRD doc links in `charts/llm-d-modelservice/values.yaml`; CRD `apiVersion: leaderworkerset.x-k8s.io/v1` in `templates/{decode,prefill}-lws.yaml` | kubernetes-sigs/lws |
