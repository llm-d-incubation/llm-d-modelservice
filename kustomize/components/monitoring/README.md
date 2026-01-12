# Monitoring Component

Enables Prometheus monitoring via PodMonitor resources.

## What it does

- Creates PodMonitor resources for decode and prefill pods
- Configures metrics scraping from vLLM containers
- Ensures pods have named metrics ports

## Prerequisites

- Prometheus Operator installed in cluster
- PodMonitor CRD available

## Install Prometheus Operator

```bash
# Using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

Usage

Include this component in your overlay:

components:
- ../../components/monitoring

Metrics Scraped

- Port: metrics (8200 for decode, 8000 for prefill)
- Path: /metrics
- Interval: 30s
- Timeout: 10s

Customization

Override scraping configuration in your overlay:

patches:
- target:
    kind: PodMonitor
    name: modelservice-decode-monitor
    patch: |-
    - op: replace
        path: /spec/podMetricsEndpoints/0/interval
        value: 15s

Verify

# Check PodMonitors created
kubectl get podmonitor

# Check if Prometheus is scraping
kubectl port-forward svc/prometheus-operated 9090:9090
# Visit http://localhost:9090 and search for vllm metrics