# Dynamic Resource Allocation (DRA) Examples


## DRA JSON schema

Currently the DRA JSON Schema is defined as below.

```json
"$defs": {
    "claimTemplate": {
        "additionalProperties": false,
        "type": "object",
        "properties": {
            "class": {"type": "string", "title": "class"},
            "count": { "type": "integer", "title": "count" },
            "match": { "type": "string", "title": "match" },
            "name": { "type": "string", "title": "name" },
            "selectors":  { "type": "array", "title": "selectors" }
        }
    }
},
"dra": {
    "additionalProperties": false,
    "required": [],
    "title": "dra",
    "type": "object",
    "properties": {
        "claimTemplates": {
            "additionalProperties": false,
            "required": [],
            "title": "claimTemplates",
            "type": "array",
            "items": {
                "$ref": "#/$defs/claimTemplate"
            }
        },
        "enabled": {
            "required": [],
            "title": "enabled",
            "type": "boolean"
        },
        "type": {
            "required": [],
            "title": "type",
            "type": "string"
        }
    }
}
```
The `selectors` array contains a DeviceClaim objects which is defined [here](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#deviceclaim-v1-resource-k8s-io).

## Examples

### Two Gaudi3 devices

In this examples the K8s pod requires two Gaudi3 devices. The DRA definition is as follows:

```yaml
dra:
  enabled: true
  type: "intel-gaudi3-x2"
  claimTemplates:
  - name: intel-gaudi3-x2
    class: gaudi.intel.com
    match: "exactly"
    count: 2
    selectors:
    - cel:
        expression: device.attributes["gaudi.intel.com"].model == 'Gaudi3'
```

The complete deployment is available in the file [intel-gaudi3-x2.yaml](./intel-gaudi3-x2.yaml)
