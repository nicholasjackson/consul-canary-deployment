network "docs" {
  subnet = "10.6.0.0/16"
}

variable "docs_network" {
  default = "docs"
}

docs "docs" {
  path  = "./pages"
  port  = 18080
  open_in_browser = true

  index_title = "Canary_Deployments"
  index_pages = [ 
    "index",
  ]

  network {
    name = "network.docs"
  }
}

container "tools" {
  image   {
    name = "shipyardrun/tools:latest"
  }
  
  network {
    name = "network.${var.docs_network}"
  }

  command = ["tail", "-f", "/dev/null"]

  # Working files
  volume {
    source      = "../../app"
    destination = "/app"
  }

  # Shipyard config for Kube 
  volume {
    source      = k8s_config_docker("dc1")
    destination = "/root/.config/kubeconfig.yaml"
  }
  
  env {
    key = "KUBECONFIG"
    value = "/root/.config/kubeconfig.yaml"
  }
  
  env {
    key = "HOST"
    value = shipyard_ip()
  }
  
  env {
    key = "CONSUL_HTTP_ADDR"
    value = "http://${shipyard_ip()}:8500"
  }
}