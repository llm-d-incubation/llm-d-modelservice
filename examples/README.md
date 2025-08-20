# Examples

This folder contains example values file and their rendered templates. It assumes you have added the
`llm-d-modelservice` repository to Helm:

```
helm repo add llm-d-modelservice https://llm-d-incubation.github.io/llm-d-modelservice/
helm repo update
```

Note: `alias k=kubectl`

> If you only want to deploy model instances without routing support, append `--set inferencePool=false --set httpRoute=false` to the example commands.

## Available Examples

| Example | Description | Hardware Requirements |
|---------|-------------|----------------------|
| [`values-cpu.yaml`](#1-cpu-only) | CPU-only inference example | Single node, no GPU required |
| [`values-pd.yaml`](#2-pd-disaggregation) | Prefill/decode disaggregation example | Multi-GPU, demonstrates P/D splitting |
| [`values-xpu.yaml`](#5-intel-xpu-examples) | Intel XPU single-node example | Intel Data Center GPU Max |
| [`wide-ep-lws/`](#3-wide-expert-parallelism-epdp-with-leaderworkerset) | Wide Expert Parallelism with LeaderWorkerSet | Multi-node, multi-GPU cluster |
| [`pvc/`](#4-loading-a-model-from-a-pvc) | Persistent volume examples | Shows different storage options |

## Usage Examples

### 1. CPU-only

Make sure there is a gateway (Kgateway or Istio) deployed in the cluster. Follow [these instructions](https://gateway-api-inference-extension.sigs.k8s.io/guides/#__tabbed_3_2) on how to set up a gateway. Once done, update `routing.parentRefs[*].name` in this [values file](values-cpu.yaml#L18) to use the name for the Gateway (`llm-d-inference-gateway-istio`) in the cluster or override with the `--set "routing.parentRefs[0].name=MYGATEWAY"` flag.


Dry run:

```
helm template cpu-sim llm-d-modelservice/llm-d-modelservice -f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-cpu.yaml
```

To install, use `helm install` instead of `helm template`:

```
helm install cpu-sim llm-d-modelservice/llm-d-modelservice -f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-cpu.yaml
```

Port forward the inference gateway service.

```
k port-forward svc/llm-d-inference-gateway-istio 8000:80
```

Send a request.

```
curl http://localhost:8000/v1/completions -vvv \
    -H "Content-Type: application/json" \
    -H "x-model-name: random/model" \
    -d '{
    "model": "random/model",
    "prompt": "Hello, "
}'
```

Expect to see a response like the following.

```
{"id":"chatcmpl-05cfe79c-234d-4898-b781-3fa59ba7be49","created":1750969231,"model":"random","choices":[{"index":0,"finish_reason":"stop","text":"Alas, poor Yorick! I knew him, Horatio: A fellow of infinite jest"}]}
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


Port forward the inference gateway service.

```
k port-forward svc/llm-d-inference-gateway-istio 8000:80
```

Send a request,

```
curl http://localhost:8000/v1/completions -vvv \
    -H "Content-Type: application/json" \
    -H "x-model-name: facebook/opt-125m" \
    -d '{
    "model": "facebook/opt-125m",
    "prompt": "Hello, "
}'
```

and expect the following response

```
{"choices":[{"finish_reason":"length","index":0,"logprobs":null,"prompt_logprobs":null,"stop_reason":null,"text":" That is my dad. He was a wautdig with a shooting blade on"}],"created":1751031325,"id":"cmpl-aca48bc2-fe95-4c3b-843d-1dbcf94c40c7","kv_transfer_params":null,"model":"facebook/opt-125m","object":"text_completion","usage":{"completion_tokens":16,"prompt_tokens":4,"prompt_tokens_details":null,"total_tokens":20}}
```


### 3. Wide Expert Parallelism (EP/DP) with LeaderWorkerSet

See https://github.com/tlrmchlsmth/llm-d-infra/blob/dev/quickstart/examples/wide-ep-lws/README.md


### 4. Loading a model from a PVC

See [this README](./pvc/README.md).


### 5. Intel XPU Examples

For Intel XPU (Data Center GPU Max) deployments:

Deploy the intel-gpu-plugin daemonset.

```
kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin?ref=v0.30.0'
```

Single-node XPU deployment.

```
helm install llm-xpu ../charts/llm-d-modelservice -f values-xpu.yaml --namespace llm-d --create-namespace

```

Get the name of decode pod.

```
kubectl get pods -n llm-d -l llm-d.ai/role=decode
```

Port forward the decode pod.

```
kubectl port-forward -n llm-d pod/$decode_pod_name 8080:8200 &
```

Send a request,

```
curl -X POST "http://localhost:8080/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B",
        "messages": [
        {"role": "user", "content": "Hello!"}
        ],
        "max_tokens": 50,
        "temperature": 0.7
    }'
```

and expect the following response

```
{"id":"chatcmpl-ebda7f789d434895afec746173e2a4ce","object":"chat.completion","created":1755679402,"model":"deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B","choices":[{"index":0,"message":{"role":"assistant","content":"Alright, the user said \"Hello!\" and I replied \"Hello! How can I assist you today?\" That's a friendly way to start, let them know I'm here to help.\n\nI should ask them how they're doing or what they need","refusal":null,"annotations":null,"audio":null,"function_call":null,"tool_calls":[],"reasoning_content":null},"logprobs":null,"finish_reason":"length","stop_reason":null}],"service_tier":null,"system_fingerprint":null,"usage":{"prompt_tokens":7,"total_tokens":57,"completion_tokens":50,"prompt_tokens_details":null},"prompt_logprobs":null,"kv_transfer_params":null}(base)
```


## Troubleshooting:

Differences between your environment and that in which the above examples were tested may mean the need to modify the input values files. Some common examples we are seen are:

- Is the inference gateway listed  in `routing.parentRefs` correct?
- Do the labels/values in `acceleratorTypes` match those assigned to nodes in your cluster?