# Examples

This folder contains example values file and their rendered templates. It assumes you have added the
`llm-d-modelservice` repository to Helm:

```
helm repo add llm-d-modelservice https://llm-d-incubation.github.io/llm-d-modelservice/
helm repo update
```

## Available Examples

| Example | Description | Hardware Requirements |
|---------|-------------|----------------------|
| [`values-cpu.yaml`](#1-cpu-only) | CPU-only inference example | Single node, no GPU required |
| [`values-pd.yaml`](#2-pd-disaggregation) | Prefill/decode disaggregation example | Multi-GPU, demonstrates P/D splitting |
| [`values-xpu.yaml`](#5-intel-xpu-examples) | Intel XPU single-node example | Intel Data Center GPU Max |
| [`pvc/`](#4-loading-a-model-from-a-pvc) | Persistent volume examples | Shows different storage options |
| [`dra/`](#6-dynamic-resource-allocation) | Dynamic Resource Allocation (DRA) examples | Shows different DRA use cases |

All the examples assume a `Gateway` and GAIE configuration have been deployed.  See the [llm-d guides](https://github.com/llm-d/llm-d/tree/main/guides) for examples.  Further, an `HTTPRoute` must be deployed. Some examples of `HTTPRoute` is provided [below](https://github.com/llm-d-incubation/llm-d-modelservice/blob/main/examples/README.md#httproute).

## Usage Examples

### 1. CPU-only

Dry run:

```
helm template cpu-sim llm-d-modelservice/llm-d-modelservice -f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-cpu.yaml
```

To install, use `helm install` instead of `helm template`:

```
helm install cpu-sim llm-d-modelservice/llm-d-modelservice -f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-cpu.yaml
```

### 2. P/D disaggregation

Dry-run:

```
helm template pd llm-d-modelservice/llm-d-modelservice -f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-pd.yaml
```

or install in a cluster

```
helm install pd llm-d-modelservice/llm-d-modelservice -f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-pd.yaml
```

### 3. Loading a model from a PVC

See [this README](./pvc/README.md).

### 4. Intel XPU Examples

For Intel XPU (Data Center GPU Max) deployments:

Deploy the intel-gpu-plugin daemonset.

```
kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin?ref=v0.30.0'
```

Single-node XPU deployment.

```
helm install llm-xpu llm-d-modelservice/llm-d-modelservice -f values-xpu.yaml --namespace llm-d --create-namespace

```

Get the name of decode pod.

```
kubectl get pods -n llm-d -l llm-d.ai/role=decode
```

## HTTPRoute Examples

An `HTTPRoute` maps requests through a `Gateway` to an `InferencePool` which is, in turn, tied (via match labels) to a particular set of model servers.  Here are two examples.

#### Example: Route all requests to the same model

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mymodel-httproute
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: INSERT_GATEWAY_NAME
  rules:
  - backendRefs:
    - group: inference.networking.k8s.io
      kind: InferencePool
      name: INSERT_INFERENCEPOOL_NAME
      port: 8000
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /
```

For example, to call the OpenAI completions API, use `mymodel/v1/completions`

#### Example: Route requests with modified path

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: myhttproute
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: INSERT_GATEWAY_NAME
  rules:
  - backendRefs:
    - group: inference.networking.k8s.io
      kind: InferencePool
      name: INSERT_INFERENCEPOOL_NAME
      port: 8000
      weight: 1
    filters:
    - type: URLRewrite
      urlRewrite:
        path:
          replacePrefixMatch: /
          type: ReplacePrefixMatch
    matches:
    - path:
        type: PathPrefix
        value: /mymodel/
```
This route supports requests with the prefix `mymodel/`; for example, to call the OpenAI completions API, requests would be sent to: `mymodel/v1/completions`. The HTTPRoute maps rewrites such requests to `v1/completions` for the target model server.

### 6. Dynamic Resource Allocation

When `accelerator.dra` is `true`, accelerator resource (gpu) requirements are specified using _Dynamic Resource Allocation_. In particular, the `accelerator.type` is used to identify a `ResourceClaimTemplate` to create (from `accelerator.resourceClaimTemplates`). The vllm containers use `resources.claims` instead of `resources.limits` to request the necessary resources. For example, see `values-dra.yaml`.

## Troubleshooting:

Differences between your environment and that in which the above examples were tested may mean the need to modify the input values files. Some common examples we are seen are:

- Is the inference gateway listed in `routing.parentRefs` correct?
- Do the labels/values in `acceleratorTypes` match those assigned to nodes in your cluster?
