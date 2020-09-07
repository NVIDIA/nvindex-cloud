# Configure the Google Cloud provider
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "primary" {
  name                      		= var.cluster_name

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate 	= false
    }
  }
}

# CPU Pool - Master pool for Kubernetes
resource "google_container_node_pool" "cpu_pool" {
  name                  = "${var.cluster_name}-cpu-pool"
  cluster               = google_container_cluster.primary.name
  initial_node_count    = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    preemptible  = var.preemptible
    machine_type = "n1-standard-8"
    disk_size_gb = 16
    disk_type    = "pd-ssd"
    image_type   = var.image_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/devstorage.read_only",
   ]
  }
}

# GPU Pool - this is where NVIDIA IndeX will be running:
resource "google_container_node_pool" "gpu_pool" {
  name                  = "${var.cluster_name}-gpu-pool"
  cluster               = google_container_cluster.primary.name
  initial_node_count    = var.gpu_pool_init_count

  autoscaling {
    min_node_count = var.gpu_pool_min_count
    max_node_count = var.gpu_pool_max_count
  }

  node_config {
    preemptible  = var.preemptible
    machine_type = var.gpu_node_machine_type
    disk_size_gb = 16
    image_type   = var.image_type
    disk_type    = "pd-ssd"

    guest_accelerator = [{
        count   = var.gpu_node_accelerator_count
        type    = var.gpu_node_accelerator_type
    }]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/devstorage.read_only",
   ]
  }
}

resource "null_resource" "cluster_done" {
  depends_on = [google_container_node_pool.cpu_pool, google_container_node_pool.gpu_pool]

  # A few things left to do after the node pools are up.
  provisioner "local-exec" {
    command = "python3 finalize.py --cluster ${google_container_cluster.primary.name} --zone ${var.zone} --image ${var.image_type}"
  }
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}
