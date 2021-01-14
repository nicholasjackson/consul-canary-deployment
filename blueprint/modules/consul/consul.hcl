//
// Install Consul using the helm chart.
//
helm "consul" {
  cluster = "k8s_cluster.dc1"

  // chart = "github.com/hashicorp/consul-helm?ref=crd-controller-base"
  chart = "github.com/hashicorp/consul-helm?ref=v0.28.0"
  values = "./helm/consul-values.yaml"

  health_check {
    timeout = "60s"
    pods = ["app=consul"]
  }
}

k8s_ingress "consul-http" {
  cluster = "k8s_cluster.dc1"

  network {
    name = "network.${var.consul_network}"
  }

  service  = "consul-ui"

  port {
    local  = 80
    remote = 80
    host   = 8500
  }
}
