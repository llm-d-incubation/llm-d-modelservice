# Loading a model directly from a PVC

Downloading large models from Hugging Face can take a significant amount of time. If a PVC containing the model files is already pre-populated, then mounting this path and supplying that to vLLM can drastically shorten the engine's warm up time.


## 1. How to download the model onto a PVC

There are some requirements for the PV or StorageClass. In particular, select a storage class that provides
- a retention policy of `Retain`, to ensure that the model downloaded remains on the PV despite no PVCs attached
- the desired access: **ReadWriteMany RWX** (preferred) vs. ReadWriteOnce RWO
  - this is to ensure that at least one pod can mount to the storage volume and download the model, which can be later read by another pod
  - RWX will also support multinode and multiple replicas, while RWO won't

You should then ask your administrator for a PVC that is available in your cluster. If such PVC is not present, the following example PVC spec is provided.

> You may use a RWO PVC, but after the pod downloads the model, you must delete the pod so that the vllm pods can claim the PVC. Also, a RWO PVC may not work for multinode examples and for models deployed with multiple replicas.

You can apply the following [PVC manifest](pvc.yaml), which is the bare minimal spec.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: model-pvc
spec:
  accessModes:
    - ReadWriteMany             # <--- Change to ReadWriteOnce if your StorageClass only provides RWO
  resources:
    requests:
      storage: 5Gi              # <--- make sure your PV has enough storage for this claim
  volumeName: model-pv          # <--- change this to reflect the name of the PV
  storageClass: standard        # <--- change this to reflect the storage class of your PV
```

```
alias k=kubectl
k apply -f examples/pvc/pvc.yaml
```

Assuming that a RWX PVC is now available, which allows many pods across nodes to read-write to the volume, create a pod using the following spec which downloads your desire model onto the PVC through an InitContainer. We will need to fetch the path of the model later by exec into the running container. Check out this [download-model.yaml](./download-model.yaml) for such manifest. You may need to edit the Python script which downloads the model with the name of your desired model. Also, some models require a token, which you must supply. Modify the Python script for your usecase.

```
k apply -f examples/pvc/download-model.yaml
```

Wait for the pod to be in the `Running` state.

```
NAME                                                   READY   STATUS    RESTARTS   AGE
model-downloader                                       1/1     Running   0          106s
```

Then, exec into the pod and `cd` into the cache dir path containing the model. The Python script downloads the model into the `/models` directory. Confirm that a `config.json` is present. `models` is the path you should use in the ModelService `uri`.

```
$ k exec -it model-downloader -- /bin/bash
$ cd models && ls
LICENSE.md  config.json         generation_config.json  pytorch_model.bin        tf_model.h5            vocab.json
README.md   flax_model.msgpack  merges.txt              special_tokens_map.json  tokenizer_config.json
```

> If using RWO: delete this pod so the pods created in the next step can claim this PVC. If you have a RWX PVC, then you do not need to delete the `model-downloader` pod.


## 2. Use ModelService to quickly mount the model

Examine [this values file](../values-pd.yaml) for an example of how to use a PVC. The only change is the URI, which should follow the following format.

```yaml
modelArtifacts:
  uri: pvc://pvc-name/<path/to/model>
```

You can install the ModelService quickly using this command:

```
helm install pvc-example llm-d-modelservice/llm-d-modelservice \
-f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-pd.yaml \
--set modelArtifacts.uri="pvc://pvc-name/<path/to/model>"
```

Examine [output-pvc.yaml](../output-pvc.yaml) to view the Kubernetes resources that will be applied upon the above command.

Note that the path after the `<pvc-name>` is the path on the PVC which the downloaded files can be found. If you don't know the path, create a debug pod (see an example manifest [here](./pvc-debugger.yaml)) and exec (`k exec -it pvc-debugger -- bin/bash`) into it to find out. The path should not contain the mountPath of that debug pod. For example, if inside the pod, the path is which model files can be found is `/mnt/huggingface/cache/models/`, then use just `huggingface/cache/models/` as the `<path/to/model>` because `/mnt` is specific to the mountPath of that debug pod.

Make sure that for the container of your interst in `prefill.containers` or `decode.containers`, there's a field called `mountModelVolume: true` ([see example](../values-pvc.yaml#L90)) for the volume mounts to be created correctly.

### Behavior
- A read-only PVC volume with the name `model-storage` is created for the deployment
- A read-only volumeMount with the mountPath: `model-cache` is created for each container where `mountModelVolume: true`
- `--model` arg for that container is set to `model-cache/<path/to/model>` where `mountModelVolume: true`

⚠️ You do **not** need to configure volumeMounts for containers where  `mountModelVolume: true`. ModelService will automatically populate the pod specification and mount the model files.

However, if you want to add your own volume specifications, you may do so under `decode.volumes`. If you would like to add more `volumeMounts` to a container, regardless whether if `mountModelVolume` is true, you may do so under `decode.containers`.

💡 You may optionally set the `--served-model-name`  in your container to be used for the OpenAI request, otherwise the request name must be a long string like `"model": "model-cache/<path/to/model>"`. Note that this argument is added automatically using the option `modelCommand: vllmServe` or `imageDefault`, using `routing.modelName` as the value to the `--served-model-name` argument.

> For security purposes, a read-only volume is mounted to the pods to prevent a pod from deleting the model files in case another model service installation uses the same PVC. If you would like to write to the PVC, you should not do so through ModelService, but rather through your own pod like the download-model/pvc-debugger without the read-only restriction.


## Use HF-downloaded models with PVCs

The above steps work for PVCs regardless of model format. If you know that the PVC contains models that are specifically downloaded from Hugging Face, and would like vLLM to support HF model formats specifically, you should use the `pvc+hf://` prefix so ModelService will set the appropriate `HF_*` environment variables.

Set the URI like the following

```yaml
modelArtifacts:
  uri: pvc+hf://pvc-name/path/to/hf_hub_cache/namespace/modelID
```

You can install the ModelService quickly using this command:

```
helm install pvc-hf-example llm-d-modelservice/llm-d-modelservice \
-f https://raw.githubusercontent.com/llm-d-incubation/llm-d-modelservice/refs/heads/main/examples/values-pd.yaml \
--set modelArtifacts.uri="pvc+hf://pvc-name/path/to/hf_hub_cache/namespace/modelID"
```

Make sure that for the container of your interst in `prefill.containers` or `decode.containers`, there's a field called `mountModelVolume: true` ([see example](../values-pvc.yaml#L90)) for the volume mounts to be created correctly.

### Behavior
- A read-only PVC volume with the name `model-storage` is created for the deployment
- A read-only volumeMount with the mountPath: `model-cache` is created for each container where `mountModelVolume: true`
- `HF_HUB_CACHE` environment variable for that container is set to `model-cache/path/to/hf_hub_cache` where `mountModelVolume: true`
- `--model` arugment is set to `namespace/modelID`