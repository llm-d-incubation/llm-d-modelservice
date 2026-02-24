 # Monitoring Enabled Example

Single-node deployment with Prometheus monitoring enabled.

## What's Included

- Nvidia GPU support
- Prometheus PodMonitor for metrics scraping
- 2 decode pod replicas
- Llama-2-7B model

## Prerequisites

- Kubernetes cluster with Nvidia GPUs
- Prometheus Operator installed
- At least 2 GPUs

## Install Prometheus Operator

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

Deploy

kubectl apply -k kustomize/overlays/examples/with-monitoring/

Verify Monitoring

# Check PodMonitors created
kubectl get podmonitor

# Check Prometheus targets
kubectl port-forward svc/prometheus-operated 9090:9090

# Visit http://localhost:9090/targets
# Should see modelservice-decode-monitor and modelservice-prefill-monitor

View Metrics

Access Prometheus UI:
kubectl port-forward svc/prometheus-operated 9090:9090

Example queries:
- vllm_num_requests_running - Active requests
- vllm_time_to_first_token_seconds - TTFT latency
- vllm_time_per_output_token_seconds - Generation speed
- vllm_cache_usage - KV cache utilization

Grafana Dashboard

Access Grafana (if installed with kube-prometheus-stack):
kubectl port-forward svc/prometheus-grafana 3000:80

Default credentials: admin / prom-operator

Clean Up

kubectl delete -k kustomize/overlays/examples/with-monitoring/