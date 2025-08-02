variable "project_id" {
  description = "The GCP project ID"
  default     = "stonoga"
}

variable "region" {
  description = "The GCP region for the cluster"
  type        = string
  default     = "europe-central2"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "gke-autopilot-cluster"
}