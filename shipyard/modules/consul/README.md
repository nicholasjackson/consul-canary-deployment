# Module to install Kubernetes and Consul Service Mesh

This module creates a Kubernetes cluster and installs and configures
Consul Service Mesh with CRDs enabled.

## Created resources
* Kubernetes cluster
* Consul Helm Chart
* Consul Ingress running on port 8500

## Variables

To use this module the following resources are required:

* consul_k8s_cluster - name of the network the resources should be attached to
* consul_network - name of the network the resources should be attached to

Optionally you can override the following variables:

* consul_helm_values - path to a file containing Helm values for the Consul Helm chart

## Usage

This module can be consumed by using the module stanza

```
module "consul" {
  source = "./module_path_or_github"
}
```
