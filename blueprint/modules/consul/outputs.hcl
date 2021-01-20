output "KUBECONFIG" {
  value = k8s_config("${var.consul_k8s_cluster}")
}

output "CONSUL_HTTP_ADDR" {
  value = "${docker_ip()}:8500"
}
