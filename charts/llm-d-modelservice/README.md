
# llm-d-modelservice Helm Chart

![Version: 0.0.9](https://img.shields.io/badge/Version-0.0.9-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart for ModelService in llm-d

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Jing Chen | <jing.chen2@ibm.com> | <https://github.com/jgchn> |
| Michael Kalantar | <kalantar@us.ibm.com> | <https://github.com/kalantar> |

---

## TL;DR

```console
helm repo add llm-d-modelservice https://llm-d-incubation.github.io/llm-d-modelservice/
helm repo update
helm install my-modelservice-release llm-d-modelservice/llm-d-modelservice
```

## Prerequisites

ModelService operates under the assumption that `llm-d-infra` has been installed in a Kubernetes cluster, which installs the required prerequisites and CRDs. Please check out the [`llm-d-infra` repo](https://github.com/llm-d-incubation/llm-d-infra/) for more information.

At a minimal, the following should be installed:
1. Kubernetes Gateway API CRDs

    ```
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
    ```

2. Kubernetes Gateway API Inference Extension CRDs

    ```
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v0.4.0/manifests.yaml

    ```

See [examples](/examples) for how to use this Helm chart.

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| decode.containers[0].image |  | string | `"ghcr.io/llm-d/llm-d-inference-sim:0.0.4"` |
| decode.containers[0].modelCommand |  | string | `"imageDefault"` |
| decode.containers[0].mountModelVolume |  | bool | `true` |
| decode.containers[0].name |  | string | `"vllm"` |
| decode.containers[0].ports[0].containerPort |  | int | `5557` |
| decode.containers[0].ports[0].protocol |  | string | `"TCP"` |
| decode.create |  | bool | `true` |
| decode.replicas |  | int | `1` |
| modelArtifacts.size |  | string | `"5Mi"` |
| modelArtifacts.uri |  | string | `"hf://random/modelid"` |
| multinode |  | bool | `false` |
| prefill.containers[0].image |  | string | `"ghcr.io/llm-d/llm-d-inference-sim:0.0.4"` |
| prefill.containers[0].modelCommand |  | string | `"imageDefault"` |
| prefill.containers[0].mountModelVolume |  | bool | `true` |
| prefill.containers[0].name |  | string | `"vllm"` |
| prefill.containers[0].ports[0].containerPort |  | int | `5557` |
| prefill.containers[0].ports[0].protocol |  | string | `"TCP"` |
| prefill.create |  | bool | `true` |
| prefill.replicas |  | int | `1` |
| routing.epp.create |  | bool | `true` |
| routing.epp.debugLevel |  | int | `4` |
| routing.epp.disableLivenessProbe |  | bool | `false` |
| routing.epp.disableReadinessProbe |  | bool | `false` |
| routing.epp.env | Default environment variables for endpoint picker, use `defaultEnvVarsOverride` to override default behavior by defining the same variable again. Ref: https://github.com/llm-d/llm-d-inference-scheduler/blob/main/docs/architecture.md#scorers--configuration | list | `[{"name":"ENABLE_KVCACHE_AWARE_SCORER","value":"false"},{"name":"ENABLE_LOAD_AWARE_SCORER","value":"true"},{"name":"ENABLE_PREFIX_AWARE_SCORER","value":"true"},{"name":"ENABLE_SESSION_AWARE_SCORER","value":"false"},{"name":"KVCACHE_AWARE_SCORER_WEIGHT","value":"1"},{"name":"KVCACHE_INDEXER_REDIS_ADDR"},{"name":"LOAD_AWARE_SCORER_WEIGHT","value":"1"},{"name":"PD_ENABLED","value":"false"},{"name":"PD_PROMPT_LEN_THRESHOLD","value":"10"},{"name":"PREFILL_ENABLE_KVCACHE_AWARE_SCORER","value":"false"},{"name":"PREFILL_ENABLE_LOAD_AWARE_SCORER","value":"false"},{"name":"PREFILL_ENABLE_PREFIX_AWARE_SCORER","value":"false"},{"name":"PREFILL_ENABLE_SESSION_AWARE_SCORER","value":"false"},{"name":"PREFILL_KVCACHE_AWARE_SCORER_WEIGHT","value":"1"},{"name":"PREFILL_KVCACHE_INDEXER_REDIS_ADDR"},{"name":"PREFILL_LOAD_AWARE_SCORER_WEIGHT","value":"1"},{"name":"PREFILL_PREFIX_AWARE_SCORER_WEIGHT","value":"1"},{"name":"PREFILL_SESSION_AWARE_SCORER_WEIGHT","value":"1"},{"name":"PREFIX_AWARE_SCORER_WEIGHT","value":"2"},{"name":"SESSION_AWARE_SCORER_WEIGHT","value":"1"}]` |
| routing.epp.image |  | string | `"ghcr.io/llm-d/llm-d-inference-scheduler:0.0.3"` |
| routing.epp.replicas |  | int | `1` |
| routing.epp.service.appProtocol |  | string | `"http2"` |
| routing.epp.service.port |  | int | `9002` |
| routing.epp.service.targetPort |  | int | `9002` |
| routing.epp.service.type |  | string | `"ClusterIP"` |
| routing.httpRoute.create |  | bool | `true` |
| routing.httpRoute.matches[0].path.type |  | string | `"PathPrefix"` |
| routing.httpRoute.matches[0].path.value |  | string | `"/"` |
| routing.inferencePool.create |  | bool | `true` |
| routing.modelName |  | string | `"random/modelId"` |
| routing.parentRefs[0].group |  | string | `"gateway.networking.k8s.io"` |
| routing.parentRefs[0].kind |  | string | `"Gateway"` |
| routing.parentRefs[0].name |  | string | `"inference-gateway"` |
| routing.proxy.image |  | string | `"ghcr.io/llm-d/llm-d-routing-sidecar:0.0.6"` |
| routing.proxy.targetPort |  | int | `8200` |
| routing.servicePort |  | int | `8000` |

## Contribute

We welcome contributions in the form of a GitHub issue or pull request. Please open a ticket if you see a gap in your use case as we continue to evolve this project.

## Contact
Get involved or ask questions in the `#sig-model-service` channel in the `llm-d` Slack workspace! Details on how to join the workspace can be found [here](https://github.com/llm-d/llm-d?tab=readme-ov-file#contribute).
