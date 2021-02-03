# Creating an demo environment with Terraform

This example will create a Kubernetes cluster in GCP and provision all the required software ready to run the example.

## Requirements
* GCP account
* gcloud CLI [https://cloud.google.com/sdk/gcloud](https://cloud.google.com/sdk/gcloud)
* Terraform > 0.13.x [https://releases.hashicorp.com/terraform/](https://releases.hashicorp.com/terraform/)

## Creating the environment

To create the environment, first initalaize terraform to download any required plugins

```shell
terraform init
```

```shell
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/helm...
- Finding latest version of hashicorp/google...
- Finding latest version of hashicorp/kubernetes...
- Installing hashicorp/helm v2.0.2...
- Installed hashicorp/helm v2.0.2 (signed by HashiCorp)
- Installing hashicorp/google v3.54.0...
- Installed hashicorp/google v3.54.0 (signed by HashiCorp)
- Installing hashicorp/kubernetes v2.0.1...
- Installed hashicorp/kubernetes v2.0.1 (signed by HashiCorp)

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, we recommend adding version constraints in a required_providers block
in your configuration, with the constraint strings suggested below.

* hashicorp/google: version = "~> 3.54.0"
* hashicorp/helm: version = "~> 2.0.2"
* hashicorp/kubernetes: version = "~> 2.0.1"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

You can then run a `terraform apply`, apply will show you the resources Terraform will create before 
creating them.

```shell
terraform apply
```

After the list of resources you will be prompted to confirm creation, type `yes`.

```shell
data.google_client_config.provider: Refreshing state...

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # data.kubernetes_secret.grafana will be read during apply
  # (config refers to values not yet known)
 <= data "kubernetes_secret" "grafana"  {
      + data = (sensitive value)
      + id   = (known after apply)
      + type = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "grafana"
          + resource_version = (known after apply)
          + self_link        = (known after apply)
          + uid              = (known after apply)
        }
    }

...

  # helm_release.promtail will be created
  + resource "helm_release" "promtail" {
      + atomic                     = false
      + chart                      = "promtail"
      + cleanup_on_fail            = false
      + create_namespace           = false
      + dependency_update          = false
      + disable_crd_hooks          = false
      + disable_openapi_validation = false
      + disable_webhooks           = false
      + force_update               = false
      + id                         = (known after apply)
      + lint                       = false
      + max_history                = 0
      + metadata                   = (known after apply)
      + name                       = "promtail"
      + namespace                  = "default"
      + recreate_pods              = false
      + render_subchart_notes      = true
      + replace                    = false
      + repository                 = "https://grafana.github.io/helm-charts"
      + reset_values               = false
      + reuse_values               = false
      + skip_crds                  = false
      + status                     = "deployed"
      + timeout                    = 300
      + values                     = [
          + <<~EOT
                ---
                config:
                  lokiAddress: "http://loki:3100/loki/api/v1/push"
            EOT,
        ]
      + verify                     = false
      + version                    = "3.0.4"
      + wait                       = true
    }

Plan: 10 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:


```

Once complete Terraform will output some information such as the default username and password for Grafana.

```shell
...

helm_release.consul-smi: Creation complete after 15s [id=consul-smi]
helm_release.prometheus: Creation complete after 1m28s [id=prometheus]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

grafana_password = F3NocuMjnrDDlOSZ1GptyGkhDLVK7ZPtwf5zvpOi
grafana_username = admin
info =
  To configure kubectl you can run the following command:

  ./helper fetch_config

  To connect to services running in the cluster run the command:

  ./helper.sh expose

  to use kubectl to forward ports.

location = europe-west1-b
name = consul-canary
project = consul-canary
```

You will also need to configure `kubectl` to install the applictaion.

## Configuring `kubectl`

In order to interact with the cluster you can run the following command:

```
./helper.sh fetch_config 
```

`helper.sh` is a simple bash script which wraps the `gcloud cli`

## Exposing Grafana and Consul

The environment does not publically expose any services, these can be accessed using `kubectl port-forward`.
 
To expose the services:
* Grafana - http://localhost:8080
* Prometheus - http://localhost:9090
* Consul - http://localhost:8500
* Web App - http://localhost:9091

run the following command:

```shell
./helper.sh expose
```

## Clean up

Running cloud resources incurs cost, remember to clean up once you are done with the cluster.

```shell
terraform destroy
```

```shell
data.google_client_config.provider: Refreshing state... [id=projects/consul-canary/regions/europe-west1/zones/]
google_service_account.default: Refreshing state... [id=projects/consul-canary/serviceAccounts/service-account-id@consul-canary.iam.gserviceaccount.com]
google_container_cluster.mycluster: Refreshing state... [id=projects/consul-canary/locations/europe-west1-b/clusters/consul-canary]
google_container_node_pool.mycluster: Refreshing state... [id=projects/consul-canary/locations/europe-west1-b/clusters/consul-canary/nodePools/consul-canary-node-pool]
helm_release.loki: Refreshing state... [id=loki]
helm_release.prometheus: Refreshing state... [id=prometheus]
helm_release.promtail: Refreshing state... [id=promtail]
helm_release.consul: Refreshing state... [id=consul]
helm_release.certmanager: Refreshing state... [id=certmanager]
helm_release.grafana: Refreshing state... [id=grafana]
helm_release.consul-smi: Refreshing state... [id=consul-smi]
data.kubernetes_secret.grafana: Refreshing state... [id=default/grafana]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

...
```
