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

ModelService operates under the assumption that `llm-d-deployer` has been installed in a Kuberentes cluster, which installs the required prerequisites and CRDs. Read the [`llm-d-deployer` Quickstart](https://github.com/llm-d/llm-d-deployer/blob/main/quickstart/README.md) for more information. This helm chart requires external CRDs to be installed for usage.

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
Below are the values you can set.
| Key                                    | Description                                                                                                       | Type         | Default                                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------------|--------------|---------------------------------------------|
| `modelArtifacts.uri`                   | Model artifacts URI. Current formats supported include `hf://`, `pvc://`, and `oci://`                            | string       | N/A                                         |
| `modelArtifacts.size`                  | Size used to create an emptyDir volume for downloading the model.                                                 | string       | N/A                                         |
| `modelArtifacts.authSecretName`        | The name of the Secret containing `HF_TOKEN` for `hf://` artifacts that require a token for downloading a model.  | string       | N/A                                         |
| `multinode`                            | Determines whether to create P/D using Deployments (false) or LeaderWorkerSets (true)                             | bool         | `false`                                     |
| `routing.modelName`                    | The name for the `"model"` parameter in the OpenAI request                                                        | string       | N/A                                         |
| `routing.servicePort`                  | The port the routing proxy sidecar listens on. <br>If there is no sidecar, this is the port the request goes to.Ω | int          | N/A                                         |
| `routing.proxy.image`                  | Image used for the sidecar                                                                                        | string       | `ghcr.io/llm-d/llm-d-routing-sidecar:0.0.6` |
| `routing.proxy.targetPort`             | The port the vLLM decode container listens on. <br>If proxy is present, it will forward request to this port.     | string       | N/A                                         |
| `routing.proxy.debugLevel`             | Debug level of the routing proxy                                                                                  | int          | 5                                           |
| `routing.proxy.parentRefs[*].name`     | The name of the inference gateway                                                                                 | string       | N/A                                         |
| `routing.inferencePool.create`         | If true, creates an InferencePool object                                                                          | bool         | `true`                                      |
| `routing.inferencePool.extensionRef`   | Name of of an epp service to use instead of the default one created by this chart.                                | string       | N/A                                         |
| `routing.inferenceModel.create`        | If true, creates an InferenceModel object                                                                         | bool         | `false`                                     |
| `routing.httpRoute.create`             | If true, creates an HTTPRoute object                                                                              | bool         | `true`                                      |
| `routing.httpRoute.backendRefs`        | Override for HTTPRoute.backendRefs                                                                                | List         | []                                          |
| `routing.httpRoute.matches`            | Override for HTTPRoute.backendRefs[*].matches where backendRefs are created by this chart.                        | Dict         | {}                                          |
| `routing.epp.create`                   | If true, creates EPP objects                                                                                      | bool         | `true`                                      |
| `routing.epp.service.permissions`      | Role to be bound to the epp service account in place of the default created by this chart.                        | string       | N/A                                         |
| `routing.epp.service.type`             | Type of Service created for the Inference Scheduler (Endpoint Picker) deployment                                  | string       | ClusterIP                                   |
| `routing.epp.service.port`             | The port the Inference Scheduler listens on                                                                       | int          | 9002                                        |
| `routing.epp.service.targetPort`       | The target port the Inference Scheduler listens on                                                                | int          | 9002                                        |
| `routing.epp.service.appProtocol`      | The app portocol the Inference Scheduler uses                                                                     | int          | 9002                                        |
| `routing.epp.image`                    | Image to be used for the epp container                                                                            | string       | ghcr.io/llm-d/llm-d-inference-scheduler:0.0.4` |
| `routing.epp.replicas`                 | Number of replicas for the Inference Scheduler pod                                                                | int          | 1                                           |
| `routing.epp.debugLevel`               | Debug level used to start the Inference Scheduler pod                                                             | int          | 4                                           |
| `routing.epp.disableReadinessProbe`    | Disable readiness probe creation for the Inference Scheduler pod. <br>Set this to `true` if you want to debug on Kind. | bool         | `false`                                     |
| `routing.epp.disableLivenessProbe`     | Disable liveness probe creation for the Inference Scheduler pod. <br>Set this to `true` if you want to debug on Kind.  | bool         | `false`                                     |
| `routing.epp.env`                      | List of environment variables                                                                                          | List         | []                                     |
| `decode.create`                        | If true, creates decode Deployment or LeaderWorkerSet                                                             | List         | `true`                                      |
| `decode.annotations`                   | Annotations that should be added to the Deployment or LeaderWorkerSet                                             | Dict         | {}                                          |
| `decode.replicas`                      | Number of replicas for decode pods                                                                                | int          | 1                                           |
| `decode.containers[*].name`            | Name of the container for the decode deployment/LWS                                                               | string       | N/A                                         |
| `decode.containers[*].image`           | Image of the container for the decode deployment/LWS                                                              | string       | N/A                                         |
| `decode.containers[*].args`            | List of arguments for the decode container.                                                                       | List[string] | []                                          |
| `decode.containers[*].modelCommand`    | Nature of the command. One of `vllmServe`, `imageDefault` or `custom`                                             | string       | `imageDefault`                              |
| `decode.containers[*].command`         | List of commands for the decode container.                                                                        | List[string] | []                                          |
| `decode.containers[*].ports`           | List of ports for the decode container.                                                                           | List[Port]   | []                                          |
| `decode.parallelism.data`              | Amount of data parallelism                                                                                        | int          | 1                                           |
| `decode.parallelism.tensor`            | Amount of tensor parallelism                                                                                      | int          | 1                                           |
| `decode.acceleratorTypes.labelKey`     | Key of label on node that identifies the hosted GPU type                                                          | string       | N/A                                         |
| `decode.acceleratorTypes.labelValue`   | Value of label on node that identifies type of hosted GPU                                                         | string       | N/A                                         |
| `prefill`                              | Same fields supported in `decode`                                                                                 | See above    | See above                                   |

## Contribute

We welcome contributions in the form of a GitHub issue or pull request. Please open a ticket if you see a gap in your use case as we continue to evolve this project.

## Contact
Get involved or ask questions in the `#sig-model-service` channel in the `llm-d` Slack workspace! Details on how to join the workspace can be found [here](https://github.com/llm-d/llm-d?tab=readme-ov-file#contribute).