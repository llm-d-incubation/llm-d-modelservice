# llm-d-modelservice

**ModelService** is a Helm chart that simplifies LLM deployment on llm-d by declaratively managing Kubernetes resources for serving base models. It enables reproducible, scalable, and tunable model deployments through modular presets, and clean integration with `llm-d` ecosystem components (including vLLM, Gateway API Inference Extension, LeaderWorkerSet). It provides an opinionated but flexible path for deploying, benchmarking, and tuning LLM inference workloads.

The ModelService Helm Chart proposal is accepted on June 10, 2025. Read more about the roadmap, motivation, and other alternatives considered [here](https://github.com/llm-d/llm-d/blob/main/docs/proposals/modelservice.md).

TL;DR:

Active scenarios supported:
- P/D disaggregation
- Multi-node inference, utilizing data parallelism
- Dynamic Resource Allocation (DRA) for flexible accelerator management

Integration with `llm-d` components:
- Quickstart guide in `llm-d-infra` depends on ModelService
- Flexible configuration of `llm-d-inference-scheduler` for routing
- Features `llm-d-routing-sidecar` in P/D disaggregation
- Utilized in benchmarking experiments in `llm-d-benchmark`
- Effortless use of `llm-d-inference-sim` for CPU-only workloads
- Allows to use `llm-d-fast-model-actuation`. More information about the fast model loading techniques [here](https://github.com/llm-d-incubation/llm-d-fast-model-actuation)

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

Note that when using the GAIE [inferencepool chart](https://github.com/kubernetes-sigs/gateway-api-inference-extension/tree/main/config/charts/inferencepool) together with the modelservice chart the following relationships will exist:

- The modelservice field `modelArtifact.routing.servicePort` should match the GAIE field `inferencePool.targetPortNumber` (for InferencePool v1alpha2) or be an entry in the list `inferencePool.targets` (for InferencePool v1).
- The modelservice field `modelArtifact.labels` should match the GAIE field, `inferencePool.modelServers.matchLabels`.
Note that the field `llm-d.ai/role` will be addition in addition to the labels specified in the `modelArtifacts.labels` field.

### HTTPRoute

In addition to deploying the GAIE chart, an `HTTPRoute` is typically required to connect the `Gateway` to the `InferencePool`. Creating an HTTPRoute is not part of either chart. Some examples are provided [here](examples/README.md#httproute-examples).

## Examples

See [examples](/examples) for how to use this Helm chart. Some examples contain placeholders for components such as the gateway name. Use the `--set` flag to override placeholders. For example,

```
helm install cpu-only llm-d-modelservice -f examples/values-cpu.yaml --set prefill.replicas=0 --set "routing.parentRefs[0].name=MYGATEWAY"
```

Check Helm's [official docs](https://helm.sh/docs/intro/using_helm/) for more guidance.

## Values
Below are the values you can set.
| Key                                    | Description                                                                                                       | Type            | Default                                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------------|-----------------|---------------------------------------------|
| `modelArtifacts.name`                  | name of model in the form namespace/modelId. Required.                                                            | string          | N/A                                         |
| `modelArtifacts.uri`                   | Model artifacts URI. Current formats supported include `hf://`, `pvc://`, and `oci://`                            | string          | N/A                                         |
| `modelArtifacts.size`                  | Size used to create an emptyDir volume for downloading the model.                                                 | string          | N/A                                         |
| `modelArtifacts.authSecretName`        | The name of the Secret containing `HF_TOKEN` for `hf://` artifacts that require a token for downloading a model.  | string          | N/A                                         |
| `modelArtifacts.mountPath`             | Path to mount the volume created to store models                                                                  | string          | /model-cache                                |
| `multinode`                            | Determines whether to create P/D using Deployments (false) or LeaderWorkerSets (true)                             | bool            | `false`                                     |
| `routing.servicePort`                  | The port the routing proxy sidecar listens on. <br>If there is no sidecar, this is the port the request goes to.  | int             | N/A                                         |
| `routing.proxy.image`                  | Image used for the sidecar                                                                                        | map          | See values.yaml                             |
| `routing.proxy.targetPort`             | The port the vLLM decode container listens on. <br>If proxy is present, it will forward request to this port.     | string          | N/A                                         |
| `routing.proxy.debugLevel`             | Debug level of the routing proxy                                                                                  | int             | 5                                           |
| `routing.proxy.parentRefs[*].name`     | The name of the inference gateway                                                                                 | string          | N/A                                         |
| `decode.create`                        | If true, creates decode Deployment or LeaderWorkerSet                                                             | List            | `true`                                      |
| `decode.annotations`                   | Annotations that should be added to the Deployment or LeaderWorkerSet                                             | Dict            | {}                                          |
| `decode.tolerations`                   | Tolerations that should be added to the Deployment or LeaderWorkerSet                                             | List            | []                                          |
| `decode.replicas`                      | Number of replicas for decode pods                                                                                | int             | 1                                           |
| `decode.extraConfig`                   | Extra pod configuration                                                                                           | dict            | {}                                          |
| `decode.containers[*].name`            | Name of the container for the decode deployment/LWS                                                               | string          | N/A                                         |
| `decode.containers[*].image`           | Image of the container for the decode deployment/LWS                                                              | map          | See values.yaml                             |
| `decode.containers[*].args`            | List of arguments for the decode container.                                                                       | List[string]    | []                                          |
| `decode.containers[*].modelCommand`    | Nature of the command. One of `vllmServe`, `imageDefault` or `custom`                                             | string          | `imageDefault`                              |
| `decode.containers[*].command`         | List of commands for the decode container.                                                                        | List[string]    | []                                          |
| `decode.containers[*].ports`           | List of ports for the decode container.                                                                           | List[Port]      | []                                          |
| `decode.containers[*].extraConfig`     | Extra container configuration                                                                                     | dict            | {}                                          |
| `decode.initContainers`.               | List of initContainers that should be added (in addition to routing proxy if enabled)                             | List[Container] | N/A                                         |
| `decode.parallelism.tensor`            | Amount of tensor parallelism                                                                                      | int             | 1                                           |
| `decode.parallelism.data`              | Amount of data parallelism                                                                                        | int             | 1                                           |
| `decode.parallelism.dataLocal`         | Amount of data local parallelism                                                                                  | int             | 1                                           |
| `decode.parallelism.workers`           | Number of workers over which data parallelism is implemented                                                      | int             | 1                                           |
| `decode.acceleratorTypes.labelKey`     | Key of label on node that identifies the hosted GPU type                                                          | string          | N/A                                         |
| `decode.acceleratorTypes.labelValue`   | Value of label on node that identifies type of hosted GPU                                                         | string          | N/A                                         |
| `decode.resourceClaims`                | List of non-accelerator ResourceClaims to create and attach to decode pods                                        | List            | []                                          |
| `prefill`                              | Same fields supported in `decode`                                                                                 | See above       | See above                                   |
| `prefill.resourceClaims`               | List of non-accelerator ResourceClaims to create and attach to prefill pods                                       | List            | []                                          |
| `accelerator.type`                     | Accelerator type (nvidia, intel-gaudi, intel-i915, intel-xe, amd, google)                                         | string          | N/A                                         |
| `accelerator.dra`                      | Enable Dynamic Resource Allocation (DRA) for accelerators. When true, uses ResourceClaimTemplates instead of device plugins | bool            | `false`                                     |
| `accelerator.resourceClaimTemplates`   | Map of accelerator types to ResourceClaimTemplate definitions for DRA mode                                        | map             | See values.yaml                             |
| `extraObjects`                         | Additional Kubernetes objects to be deployed alongside the main application                                       | List            | []                                          |

### Accelerator Resource Configuration

The chart automatically calculates accelerator resources (e.g., `nvidia.com/gpu`, `google.com/tpu`) based on parallelism settings. However, you can override this by explicitly setting resources in your container spec.

**Precedence:**
1. If you explicitly set `resources.limits.<accelerator>` in your container spec, that value is used
2. Otherwise, the value is auto-calculated from `parallelism.tensor * parallelism.dataLocal`
  a. If you use this strategy, vLLM parallelism arguments like `--tensor-parallel-size` and `--data-parallel-size-local` and the corresponding value will be added automatically to the first container

**Example - Auto-calculated (default):**
```yaml
decode:
  parallelism:
    tensor: 4
  containers:
    - name: vllm
      # nvidia.com/gpu will be auto-set to 4
```

**Example - User override:**
```yaml
decode:
  parallelism:
    tensor: 8  # Used for --tensor-parallel-size
  containers:
    - name: vllm
      resources:
        limits:
          google.com/tpu: "4"  # Explicitly set (TPUs: TP=8 needs 4 TPUs)
```

This is useful for accelerators like TPUs where tensor parallelism does not equal the number of accelerators.

### Dynamic Resource Allocation (DRA)

The chart supports Kubernetes Dynamic Resource Allocation for flexible accelerator management. Enable DRA mode with `accelerator.dra: true`.

**DRA vs Device Plugin Mode:**

| Aspect | Device Plugin (default) | DRA Mode (`accelerator.dra: true`) |
|--------|------------------------|-----------------------------------|
| Accelerator allocation | Via `resources.limits` (e.g., `nvidia.com/gpu: 4`) | Via ResourceClaims and ResourceClaimTemplates |
| Device count | Manual or auto-calculated | Auto-calculated from parallelism settings |
| Flexibility | Standard device plugin constraints | Advanced selection criteria via claim templates |
| Non-accelerator resources | Specified in `resources.limits/requests` | Specified in `resources.limits/requests` (pass-through) |

**Example - DRA Mode:**
```yaml
accelerator:
  type: intel-gaudi
  dra: true  # Enable DRA
  resourceClaimTemplates:
    intel-gaudi:
      name: gaudi-claim-template
      class: gaudi.intel.com
      match: "exactly"
      count: 2  # Optional override; auto-calculated from parallelism if omitted

decode:
  parallelism:
    tensor: 2
    dataLocal: 1
  containers:
    - name: vllm
      resources:
        limits:
          cpu: "4"       # Non-accelerator resources work normally
          memory: "16Gi"
        requests:
          cpu: "2"
          memory: "8Gi"
        claims:          # Optional: add non-accelerator claims
        - name: custom-resource-claim
  resourceClaims:        # Define non-accelerator claims here
  - name: custom-resource-claim
    resourceClaimTemplateName: my-custom-template
```

**Key Points:**
- When `accelerator.dra: true`, do NOT specify accelerator resources in `resources.limits` (e.g., don't use `nvidia.com/gpu`)
- Accelerator allocation is handled automatically via claims
- Device count is auto-calculated as `parallelism.tensor * parallelism.dataLocal` unless explicitly overridden in `resourceClaimTemplates[].count`
- CPU, memory, and other non-accelerator resources are specified normally in `resources.limits/requests`
- User-defined claims for non-accelerator resources (e.g., RDMA, custom devices) can be added via `resourceClaims` and referenced in `resources.claims`

## Contribute

We welcome contributions to llm-d-modelservice! Please see our [Contributing Guide](CONTRIBUTING.md) for detailed information on how to contribute to this project, including guidelines for submitting issues, pull requests, and development setup.

Please open a ticket if you see a gap in your use case as we continue to evolve this project.

## Contact
Get involved or ask questions in the `#sig-model-service` channel in the `llm-d` Slack workspace! Details on how to join the workspace can be found [here](https://llm-d.ai/docs/community).
