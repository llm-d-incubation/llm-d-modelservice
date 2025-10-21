# llm-d-modelservice

**ModelService** is a Helm chart that simplifies LLM deployment on llm-d by declaratively managing Kubernetes resources for serving base models. It enables reproducible, scalable, and tunable model deployments through modular presets, and clean integration with `llm-d` ecosystem components (including vLLM, Gateway API Inference Extension, LeaderWorkerSet). It provides an opinionated but flexible path for deploying, benchmarking, and tuning LLM inference workloads.

The ModelService Helm Chart proposal is accepted on June 10, 2025. Read more about the roadmap, motivation, and other alternatives considered [here](https://github.com/llm-d/llm-d/blob/main/docs/proposals/modelservice.md).

TL;DR:

Active scenarios supported:
- P/D disaggregation
- Multi-node inference, utilizing data parallelism
- One pod per DP rank

Integration with `llm-d` components:
- Quickstart guide in `llm-d-infra` depends on ModelService
- Flexible configuration of `llm-d-inference-scheduler` for routing
- Features `llm-d-routing-sidecar` in P/D disaggregation
- Utilized in benchmarking experiments in `llm-d-benchmark`
- Effortless use of `llm-d-inference-sim` for CPU-only workloads

## Getting started

Add this repository to Helm.

```
helm repo add llm-d-modelservice https://llm-d-incubation.github.io/llm-d-modelservice/
helm repo update
```

ModelService operates under the assumption that `llm-d-infra` has been installed in a Kubernetes cluster, which installs the required prerequisites and CRDs. Read the [`llm-d` Guides](https://github.com/llm-d/llm-d/blob/main/guides/README.md) for more information.

## Routing

Once a model is deployed, inference requests must be routed to it. To do this, the Kubernetes Gateway API Inference Extension (GAIE) Helm charts can be used. These charts are defined [here](https://github.com/kubernetes-sigs/gateway-api-inference-extension/tree/main/config/charts/). For example, to create an InferencePool, use the chart oci://registry.k8s.io/gateway-api-inference-extension/charts/inferencepool.

### Relationships

Note that when using the GAIE InferencePool chart together with the Modelservice chart the following relationships will exist:

- The modelservice field `modelArtifact.routing.servicePort` should match the GAIE field `inferencePool.targetPortNumber` or be an entry in the list `inferencePool.targets` (depending on the apiVersion of InferencePool).
- The modelservice field `modelArtifact.labels` should match the GAIE field, `inferencePool.modelServers.matchLabels`.

### HTTPRoute

In addition to deploying the GAIE chart, an `HTTPRoute` is typically required to connect the `Gateway` to the `InferencePool`. Creating an HTTPRoute is not part of either chart. Some examples are provided [here](https://github.com/llm-d-incubation/llm-d-modelservice/blob/main/examples/README.md#httproute)

## Examples

See [examples](/examples) for how to use this Helm chart. Some examples contain placeholders for components such as the gateway name. Use the `--set` flag to override placeholders. For example,

```
helm install cpu-only llm-d-modelservice -f examples/values-cpu.yaml --set prefill.replicas=0 --set "routing.parentRefs[0].name=MYGATEWAY"
```

Check Helm's [official docs](https://helm.sh/docs/intro/using_helm/) for more guidance.

## Values
Below are the values you can set.
| Key                                    | Description                                                                                                       | Type         | Default                                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------------|--------------|---------------------------------------------|
| `modelArtifacts.name`                  | name of model in the form namespace/modelId. Required.                                                            | string       | N/A                                         |
| `modelArtifacts.uri`                   | Model artifacts URI. Current formats supported include `hf://`, `pvc://`, and `oci://`                            | string       | N/A                                         |
| `modelArtifacts.size`                  | Size used to create an emptyDir volume for downloading the model.                                                 | string       | N/A                                         |
| `modelArtifacts.authSecretName`        | The name of the Secret containing `HF_TOKEN` for `hf://` artifacts that require a token for downloading a model.  | string       | N/A                                         |
| `modelArtifacts.mountPath`             | Path to mount the volume created to store models                                                                  | string       | /model-cache                                |
| `multinode`                            | Determines whether to create P/D using Deployments (false) or LeaderWorkerSets (true)                             | bool         | `false`                                     |
| `routing.servicePort`                  | The port the routing proxy sidecar listens on. <br>If there is no sidecar, this is the port the request goes to.  | int          | N/A                                         |
| `routing.proxy.image`                  | Image used for the sidecar                                                                                        | string       | `ghcr.io/llm-d/llm-d-routing-sidecar:0.0.6` |
| `routing.proxy.targetPort`             | The port the vLLM decode container listens on. <br>If proxy is present, it will forward request to this port.     | string       | N/A                                         |
| `routing.proxy.debugLevel`             | Debug level of the routing proxy                                                                                  | int          | 5                                           |
| `routing.proxy.parentRefs[*].name`     | The name of the inference gateway                                                                                 | string       | N/A                                         |
| `decode.create`                        | If true, creates decode Deployment or LeaderWorkerSet                                                             | List         | `true`                                      |
| `decode.annotations`                   | Annotations that should be added to the Deployment or LeaderWorkerSet                                             | Dict         | {}                                          |
| `decode.tolerations`                   | Tolerations that should be added to the Deployment or LeaderWorkerSet                                             | List         | []                                          |
| `decode.replicas`                      | Number of replicas for decode pods                                                                                | int          | 1                                           |
| `decode.extraConfig`                   | Extra pod configuration                                                                                           | dict         | {}                                          |
| `decode.containers[*].name`            | Name of the container for the decode deployment/LWS                                                               | string       | N/A                                         |
| `decode.containers[*].image`           | Image of the container for the decode deployment/LWS                                                              | string       | N/A                                         |
| `decode.containers[*].args`            | List of arguments for the decode container.                                                                       | List[string] | []                                          |
| `decode.containers[*].modelCommand`    | Nature of the command. One of `vllmServe`, `imageDefault` or `custom`                                             | string       | `imageDefault`                              |
| `decode.containers[*].command`         | List of commands for the decode container.                                                                        | List[string] | []                                          |
| `decode.containers[*].ports`           | List of ports for the decode container.                                                                           | List[Port]   | []                                          |
| `decode.containers[*].extraConfig`     | Extra container configuration                                                                                     | dict         | {}                                          |
| `decode.parallelism.data`              | Amount of data parallelism                                                                                        | int          | 1                                           |
| `decode.parallelism.tensor`            | Amount of tensor parallelism                                                                                      | int          | 1                                           |
| `decode.acceleratorTypes.labelKey`     | Key of label on node that identifies the hosted GPU type                                                          | string       | N/A                                         |
| `decode.acceleratorTypes.labelValue`   | Value of label on node that identifies type of hosted GPU                                                         | string       | N/A                                         |
| `prefill`                              | Same fields supported in `decode`                                                                                 | See above    | See above                                   |
| `extraObjects`                         | Additional Kubernetes objects to be deployed alongside the main application                                        | List         | []                                          |

## Contribute

We welcome contributions to llm-d-modelservice! Please see our [Contributing Guide](CONTRIBUTING.md) for detailed information on how to contribute to this project, including guidelines for submitting issues, pull requests, and development setup.

Please open a ticket if you see a gap in your use case as we continue to evolve this project.

## Contact
Get involved or ask questions in the `#sig-model-service` channel in the `llm-d` Slack workspace! Details on how to join the workspace can be found [here](https://llm-d.ai/docs/community).
