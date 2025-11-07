resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count = 1

  # basic networking - adjust for production
  ip_allocation_policy {}

  # Enable autoscaling and workload identity if desired
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Managed node pool with autoscaling enabled
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.zone
  node_count = 1

  node_config {
    machine_type = "e2-medium" # small for trial
    preemptible  = true        # optional: cheaper but ephemeral
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }
}
