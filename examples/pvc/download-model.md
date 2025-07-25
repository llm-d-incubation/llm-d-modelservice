# Loading a model directly from a PVC

Downloading large models from Hugging Face can take a significant amount of time. If a PVC containing the model files is already pre-populated, then mounting this path and supplying that to vLLM can drastically shorten the engine's warm up time.


## 1. How to download the model onto a PVC

There are some requirements you may set for the PV, such as setting `persistentVolumeReclaimPolicy: Retain` so that after the downloaded model remains despite no PVCs attached to the PV. Contact your cluster administrator for such PV requirements.

You should then ask your administrator for a PVC that is available in your cluster. Assuming that at least a ReadWriteOnce (RWO) PVC is available, which allows read-write by a single node, you can create a pod using the following spec which downloads your desire model onto the PVC.

For example, you can apply the following PVC manifest, which is the bare minimal spec. Your cluster may require you to use a StorageClass.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: model-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

The following manifest is a pod which downloads the model on an InitContainer. We will need to fetch the path of the model later by exec into the running container. Check out this [download-model.yaml](./download-model.yaml) for such manifest.

```
alias k=kubectl
k apply -f download-model.yaml
```

And wait for the pod to be in the `Running` state.

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

Delete this pod so the pods created in the next step can claim this PVC. If you have a RMW PVC, then you do not need to delete the `model-downloader` pod.

```
k delete po model-downloader
```

Since the PVC is RWO, we can mount to this PVC in the next step.

## 2. Use ModelService to quickly mount the model

Examine [this values file](../values-pvc.yaml) for an example of how to use a PVC. Note that the path after the `<pvc-name>` is the path on the PVC which the downloaded files can be found. If you don't know the path, create a debug pod (see an example manifest [here](./pvc-debugger.yaml)) and exec (`k exec -it pvc-debugger -- bin/bash`) into it to find out. The path should not contain the mountPath of that debug pod. For example, if inside the pod, the path is which model files can be found is `/mnt/huggingface/cache/models/`, then use just `huggingface/cache/models/` as the `<path/to/model>` because `/mnt` is specific to the mountPath of that debug pod.

### URI format
"pvc://<pvc-name>/<path/to/model>"

Make sure that for the container of your interst in `prefill.containers` or `decode.containers`, there's a field called `mountModelVolume: true` ([see example](../values-pvc.yaml#L90)) for the volume mounts to be created correctly.

### Behavior
- A read-only PVC volume with the name model-storage is created for the deployment
- A read-only volumeMount with the mountPath: model-cache is created for each container where `mountModelVolume: true`
- `--model` args is set to `model-cache/<path/to/model>`

You may optionally set the `--served-model-name`  in your container to be used for the OpenAI request, otherwise the request name must be a long string like `"model": "model-cache/<path/to/model>`"`.

