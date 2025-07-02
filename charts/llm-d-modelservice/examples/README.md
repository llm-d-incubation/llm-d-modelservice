# Examples

This folder contains example values file and their rendered templates.

```
cd charts
helm install [RELEASE-NAME] llm-d-modelservice/llm-d-modelservice -f [VALUES-FILEPATH]
```

Note: `alias k=kubectl`

1. `vllm-sim` in Kind

    Make sure there is a gateway (Kgteway or Istio) deployed in the cluster. Follow [these instructions](https://gateway-api-inference-extension.sigs.k8s.io/guides/#__tabbed_3_2) on how to set up a gateway. Once done, update `routing.parentRefs[*].name` in this [values file](values-vllm-sim.yaml#L18) to use the name for the Gateway (`llm-d-inference-gateway-istio`) in the cluster.


    Dry run:

    ```
    helm template vllm-sim llm-d-modelservice/llm-d-modelservice -f llm-d-modelservice/examples/values-vllm-sim.yaml > llm-d-modelservice/examples/output-vllm-sim.yaml
    ```

    Install in a Kind cluster:

    ```
    helm install vllm-sim llm-d-modelservice/llm-d-modelservice -f llm-d-modelservice/examples/values-vllm-sim.yaml
    ```

    Port forward the inference gateway service.

    ```
    k port-forward svc/llm-d-inference-gateway-istio 8000:80
    ```

    Send a request.

    ```
    curl http://localhost:8000/v1/completions -vvv \
        -H "Content-Type: application/json" \
        -H "x-model-name: random" \
        -d '{
        "model": "random",
        "prompt": "Hello, "
    }'
    ```

    Expect to see a response like the following.

    ```
    {"id":"chatcmpl-05cfe79c-234d-4898-b781-3fa59ba7be49","created":1750969231,"model":"random","choices":[{"index":0,"finish_reason":"stop","text":"Alas, poor Yorick! I knew him, Horatio: A fellow of infinite jest"}]}
    ```


2. `facebook/opt-125m`: downloads a model from Hugging Face. Ensure that the name of the Gateway is correct in [this](values-facebook.yaml#L16) values file.

    Dry-run:

    ```
    helm template facebook llm-d-modelservice/llm-d-modelservice -f llm-d-modelservice/examples/values-facebook.yaml > llm-d-modelservice/examples/output-facebook.yaml
    ```

    or install in a cluster


    ```
    helm install facebook llm-d-modelservice/llm-d-modelservice -f llm-d-modelservice/examples/values-facebook.yaml
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