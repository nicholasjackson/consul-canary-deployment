//
// Create a single node Kubernetes cluster.
//
k8s_cluster "dc1" {
  driver  = "k3s"
  version = "v1.0.1"

  nodes = 1

  network {
    name = "network.${var.consul_network}"
  }

  image {
    name = "hashicorpdev/consul"
  }
}

