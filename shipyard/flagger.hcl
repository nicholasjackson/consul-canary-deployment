helm "flagger" {
  depends_on = ["module.consul_stack"]
  cluster = "k8s_cluster.dc1"
  chart = "github.com/fluxcd/flagger/charts//flagger"

  values = "${file_dir()}/../helm/flagger-values.yaml"
}

#k8s_config "flagger-crds" {
#  cluster = "k8s_cluster.dc1"
#  paths = [
#    "${file_dir()}/../setup/flagger-crds.yaml",
#  ]
#
#  wait_until_ready = true
#}