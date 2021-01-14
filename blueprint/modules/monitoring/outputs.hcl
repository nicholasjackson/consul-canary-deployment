output "GRAFANA_HTTP_ADDR" {
  value = "${docker_ip()}:8080"
}

output "GRAFANA_USER" {
  value = "admin"
}

output "GRAFANA_PASWORD" {
  value = "admin"
}
