k8s_config "grafana_secret" {
  cluster = "k8s_cluster.${var.monitoring_k8s_cluster}"

  paths = [
    "./k8sconfig/grafana_secret.yaml",
  ]

  wait_until_ready = true
}

helm "grafana" {
  cluster = "k8s_cluster.${var.monitoring_k8s_cluster}"

  chart = "github.com/grafana/helm-charts/charts//grafana"
  values = "./helm/grafana_values.yaml"
}

ingress "grafana" {
  target = "k8s_cluster.${var.monitoring_k8s_cluster}"
  service = "svc/grafana"

  port {
    local = 80
    remote = 80
    host = 8080
  }
  
  network {
    name = "network.${var.monitoring_network}"
  }
}
