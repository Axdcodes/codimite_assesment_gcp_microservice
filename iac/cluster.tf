resource "google_container_cluster" "cluster" {
  name       = "${local.project}-${var.environment}-cluster"
  location   = var.region
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnets.name


  node_pool {
    name               = "${local.project}-${var.environment}-general-node-pool"
    initial_node_count = 2
    node_config {
      machine_type = "e2-medium"
      oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }

  node_pool {
    name               = "${local.project}-${var.environment}-cpu-node-pool"
    initial_node_count = 2
    node_config {
      machine_type = "n2-highcpu-4"
      oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }
}
