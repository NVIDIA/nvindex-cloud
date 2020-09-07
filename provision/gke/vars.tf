variable "cluster_name" {
  description   = "Name of cluster to be created."
  default       = "nvindex-gke-cluster"
}

variable "project" {
  description   = "Project in which the Kubernetes cluster will be created. (required)"
}

variable "region" {
  description   = "Region in which the Kubernetes cluster will be created. (required)"
  default       = "us-central1"
}

variable "zone" {
  description   = "Zone in which the Kubernetes cluster will be created. (required)"
  default       = "us-central1-a"
}

variable "credentials_file_path" {
  default       =  "~/.config/gcloud/application_default_credential.json"
}

variable "gpu_pool_min_count" {
  description   = "Min size of GPU cluster"
  type          = number
  default       = 1
}

variable "gpu_pool_max_count" {
  description   = "Max size of GPU cluster"
  type          = number
  default       = 10
}

variable "gpu_pool_init_count" {
  description   = "Initial nodes in GPU cluster"
  default       = 1
  type          = number
}

variable "gpu_node_machine_type" {
  description   = "Machine type for GPU nodes"
  default       = "n1-standard-8"
}

variable "gpu_node_accelerator_count" {
  description   = "number of GPUs / node in the GPU pool"
  default       = 1
  type          = number
}

variable "gpu_node_accelerator_type" {
  description   = "GPU type to use in a node of the GPU pool"
  default       = "nvidia-tesla-t4"
}

variable "image_type" {
  description  = "OS to be used: UBUNTU|COS"
  default      = "UBUNTU"
}

variable "preemptible" {
	description  = "Use pre-emptible instances? (default: no)"
	type				 = bool
	default			 = false
}
