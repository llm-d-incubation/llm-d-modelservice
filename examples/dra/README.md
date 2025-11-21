# Dynamic Resource Allocation (DRA) Examples

## Introduction

[DRA](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/) is a Kubernetes feature that lets you request and share resources among Pods. These resources are often attached devices like hardware accelerators. DRA is GA in K8s v1.34.

In order to use DRA you need to have the following:

- K8s cluster with DRA enabled
- DRA resource driver for a GPU / accelerator
- Pod/Deployment requesting resources via `resourceClaims` or `resourceClaimTemplates`

To enable DRA in K8s cluster you can use `kubeadm` and [config file](dra.kubeadm.yaml).

This Helm Chart provides the following `dra` object which generates the pod's `resources.claims`, `resourceClaims` and `resourceClaimTemplates` automatically.

```yaml
dra:
  enabled: true  # true: use this block instead of the `accelerator`
  type: intel    # which claimTemplates entry to use
  claimTemplates:
  - name: intel
    class: gpu.intel.com
    match: "exactly"
    count: 1
    selectors: []
```

The `selectors` array contains a DeviceClaim objects which is defined [here](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#deviceclaim-v1-resource-k8s-io).

## Examples

The examples assumes you have `model-pvc` with the required models already downloaded.

### Single Intel GPU device

The deployment uses deviceClass `gpu.intel.com` which works for both `i915` and `xe` drivers.

```bash
helm install dra charts/llm-d-modelservice -f examples/values-dra.yaml --set modelArtifacts.uri="pvc+hf://model-pvc/meta-llama/Llama-3.1-8B-Instruct"
```

### Two Gaudi2 devices

In this examples the K8s pod requires two Gaudi2 devices. The model selection is done via `selectors` object. The DRA definition is as follows:

```yaml
dra:
  enabled: true
  type: intel-gaudi
  claimTemplates:
  - name: intel-gaudi
    class: gaudi.intel.com
    match: "exactly"
    count: 2
    selectors:
    - cel:
        expression: device.attributes["gaudi.intel.com"].model == 'Gaudi2'
```

The complete deployment is available in the file [intel-gaudi2-x2.yaml](./intel-gaudi2-x2.yaml) and can be deployed as follows.

```bash
helm install gaudi-dra charts/llm-d-modelservice -f examples/dra/intel-gaudi2-x2.yaml --set modelArtifacts.uri="pvc+hf://model-pvc/meta-llama/Llama-3.1-8B-Instruct"
```

## Verification

You can use the following command to verify that all the DRA objects are created correctly.

```bash
kubectl get resourceslices,resourceclaims,resourceclaimtemplates
NAME                                                          NODE        DRIVER          POOL        AGE
resourceslice.resource.k8s.io/arl762231-gpu.intel.com-psrnf   arl762231   gpu.intel.com   arl762231   23h

NAME                                                                                          STATE                AGE
resourceclaim.resource.k8s.io/dra-llm-d-modelservice-decode-99f4b654-intel-resource-clnd7bs   allocated,reserved   20m

NAME                                                                  AGE
resourceclaimtemplate.resource.k8s.io/intel-resource-claim-template   20m
```
