# Kustomize Structure Summary

  ## Complete Inventory

  ### Base Layer
  -  ServiceAccount
  -  Decode Deployment (replicas=0)
  -  Prefill Deployment (replicas=0)
  -  Decode LeaderWorkerSet (replicas=0)
  -  Prefill LeaderWorkerSet (replicas=0)
  -  ConfigMaps (model, parallelism, routing)

  ### Accelerators (6)
  1.  nvidia - Nvidia GPUs (CUDA)
  2.  intel-xe - Intel Data Center GPU Max
  3.  intel-i915 - Intel Integrated Graphics
  4.  intel-gaudi - Intel Gaudi AI Accelerators
  5.  amd - AMD GPUs (ROCm)
  6.  google-tpu - Google Cloud TPUs

  ### Components (6)
  1.  multinode - LeaderWorkerSet for multi-GPU
  2.  monitoring - Prometheus PodMonitor
  3.  dra - Dynamic Resource Allocation
  4.  routing-proxy - NIXL routing sidecar
  5.  prefill-disaggregation - Separate prefill pods
  6.  requester - Fast Model Actuation (FMA)

  ### Examples (8)
  1.  single-node-nvidia - Basic deployment
  2.  multinode-nvidia - Multi-GPU with LWS
  3.  pd-disaggregation - Prefill/Decode split
  4.  with-monitoring - Prometheus metrics
  5.  with-dra - Dynamic GPU allocation
  6.  intel-xpu - Intel GPU deployment
  7.  multinode-monitoring - Large model + metrics
  8.  fma-requester - Fast Model Actuation


  ## Feature Parity with Helm
   All Helm features supported
   All accelerator types supported
   All deployment modes supported
   All optional features available as components
   Multiple complete examples provided
