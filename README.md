# llm-d-modelservice

**ModelService** is a Helm chart that simplifies LLM deployment on llm-d by declaratively managing Kubernetes resources for serving base models. It enables reproducible, scalable, and tunable model deployments through modular presets, and clean integration with `llm-d` ecosystem components (including vLLM, Gateway API Inference Extension, LeaderWorkerSet). It provides an opinionated but flexible path for deploying, benchmarking, and tuning LLM inference workloads.

The ModelService Helm Chart proposal is accepted on June 10, 2025. Read more about the roadmap, motivation, and other alternatives considered [here](https://github.com/llm-d/llm-d/blob/dev/docs/proposals/modelservice.md).

TL;DR:

Active scearios supported
- P/D disaggregation using deployments
- P/D disaggregation using LeaderWorkerSets
- One pod per DP rank (in progress)

Near future roadmap
- Migrate `llm-d-deployer` and quickstart to use this helm chart

## Getting started

Add this repository to Helm.

```
helm repo add llm-d-modelservice https://llm-d-incubation.github.io/llm-d-modelservice/
helm repo update
```

This helm chart requires external CRDs to be installed for usage.

1. Install Kubernetes Gateway API CRDs

    ```
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
    ```

2. Install Kubernetes Gateway API Inference Extension CRDs

    ```
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v0.4.0/manifests.yaml

    ```


See [examples](https://llm-d-incubation.github.io/llm-d-modelservice/charts/llm-d-modelservice/examples) for how to use this Helm chart.

## Values
Below are the values you can set.
| Key                                    | Description                                                                                                       | Type         | Default                                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------------|--------------|---------------------------------------------|
| `multinode`                            | Determines whether to create P/D using Deployments (false) or LWS (true)                                          | bool         | `false`                                     |
| `inferencePool`                        | If true, creates a InferencePool object                                                                           | bool         | `false`                                     |
| `httpRoute`                            | If true, creates a HTTPRoute object                                                                               | bool         | `false`                                     |
| `routing.modelName`                    | The name for the `"model"` parameter in the OpenAI request                                                        | string       | N/A                                         |
| `routing.servicePort`                  | The port the routing proxy sidecar listens on. <br>If there is no sidecar, this is the port the request goes to.Ω | int          | N/A                                         |
| `routing.proxy.image`                  | Image used for the sidecar                                                                                        | string       | `ghcr.io/llm-d/llm-d-routing-sidecar:0.0.6` |
| `routing.proxy.targetPort`             | The port the vLLM decode container listens on. <br>If proxy is present, it will forward request to this port.     | string       | N/A                                         |
| `routing.proxy.debugLevel`             | Debug level of the routing proxy                                                                                  | int          | 5                                           |
| `routing.proxy.parentRefs[*].name`     | The name of the inference gateway                                                                                 | string       | N/A                                         |
| `modelArtifacts.uri`                   | Model artifacts URI. Current formats supported include `hf://`, `pvc://`, and `oci://`                            | string       | N/A                                         |
| `modelArtifacts.authSecretName`        | The name of the Secret containing `HF_TOKEN` for `hf://` artifacts that require a token for downloading a model.  | string       | N/A                                         |
| `modelArtifacts.size`                  | Size used to create an emptyDir volume for downloading the model from HF.                                         | string       | N/A                                         |
| `decode.replicas`                      | Number of replicas for decode pods                                                                                | int          | 1                                           |
| `decode.containers[*].name`            | Name of the container for the decode deployment/LWS                                                               | string       | N/A                                         |
| `decode.containers[*].image`           | Image of the container for the decode deployment/LWS                                                              | string       | N/A                                         |
| `decode.containers[*].args`            | List of arguments for the decode container.                                                                       | List[string] | []                                          |
| `decode.containers[*].command`         | List of commands for the decode container.                                                                        | List[string] | []                                          |
| `decode.containers[*].ports`           | List of ports for the decode container.                                                                           | List[Port]   | []                                          |
| `prefill`                              | Same fields supported in `decode`                                                                                 | See above    | See above                                   |
| `endpointPicker.service.permissions`          | Role created for the Inference Scheduler                                  | string       | N/A                                   |
| `endpointPicker.service.type`          | Type of Service created for the Inference Scheduler (Endpoint Picker) deployment                                  | string       | ClusterIP                                   |
| `endpointPicker.service.port`          | The port the Inference Scheduler listens on                                                                       | int          | 9002                                        |
| `endpointPicker.service.targetPort`    | The target port the Inference Scheduler listens on                                                                | int          | 9002                                        |
| `endpointPicker.service.appProtocol`   | The app portocol the Inference Scheduler uses                                                                     | int          | 9002                                        |
| `endpointPicker.replicas`              | Number of replicas for the Inference Scheduler pod                                                                | int          | 1                                           |
| `endpointPicker.debugLevel`            | Debug level used to start the Inference Scheduler pod                                                             | int          | 4                                           |
| `endpointPicker.disableReadinessProbe` | Disable readiness probe creation for the Inference Scheduler pod. <br>Set this to `true` if you want to debug on Kind.    | bool         | `false`                                     |
| `endpointPicker.disableLivenessProbe`  | Disable liveness probe creation for the Inference Scheduler pod. <br>Set this to `true` if you want to debug on Kind.     | bool         | `false`                                     |


## Contribute

We welcome contributions in the form of a GitHub issue or pull request. Please open a ticket if you see a gap in your use case as we continue to evolve this project.

## Contact
Get involved or ask questions in the `#sig-model-service` channel in the `llm-d` Slack workspace! Details on how to join the workspace can be found [here](https://github.com/llm-d/llm-d?tab=readme-ov-file#contribute).