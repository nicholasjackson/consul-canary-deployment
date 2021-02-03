resource "helm_release" "certmanager" {
  depends_on = [google_container_node_pool.mycluster]
  name       = "certmanager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  
  values = [
    file("../helm/cert-manager-values.yaml")
  ]
}

resource "helm_release" "consul" {
  depends_on = [google_container_node_pool.mycluster]
  name       = "consul"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  
  values = [
    file("../helm/consul-values.yaml")
  ]
}

resource "helm_release" "consul-smi" {
  depends_on = [helm_release.consul, helm_release.certmanager]
  name       = "consul-smi"

  repository = "https://nicholasjackson.io/smi-controller-sdk/"
  chart      = "smi-controller"
  
  values = [
    file("../helm/consul-smi-controller.yaml")
  ]
}
