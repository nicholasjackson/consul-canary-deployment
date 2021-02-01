# Set the environment variables GOOGLE_PROJECT AND GOOGLEG_REGION
provider "google" {}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account for GKE cluster"
}

resource "google_container_cluster" "mycluster" {
  name               = var.name
  location           = var.location
  initial_node_count = 1
  remove_default_node_pool = true

  // initial node pool is scaled to 0 after creation
  // the following block stops terraform thinking the resource
  // is out of sync and needs to be recreated
  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }

  network    = "default"
  subnetwork = "default"

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }
}

resource "google_container_node_pool" "mycluster" {
  name       = "${var.name}-node-pool"
  location   = var.location
  cluster    = google_container_cluster.mycluster.name
  node_count = var.nodes
    
  max_pods_per_node = 110

  node_config {
    machine_type = var.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

data "google_client_config" "provider" {}

# Configure the Kubernetes and Helm providers using the data from the cluster
provider "kubernetes" {
  host  = "https://${google_container_cluster.mycluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.mycluster.master_auth[0].cluster_ca_certificate,
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.mycluster.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.mycluster.master_auth[0].cluster_ca_certificate,
    )
  }
}
