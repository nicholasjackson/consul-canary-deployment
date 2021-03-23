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
    "configuration",
    "flagger",
    "application",
    "load_generation",
    "grafana",
    "canary",
    "rollback",
    "summary"
  ]

  network {
    name = "network.${var.docs_network}"
  }
}
