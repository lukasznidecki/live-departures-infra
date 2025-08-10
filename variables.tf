variable "project_id" {
  description = "The GCP project ID"
  default     = "live-departures"
}

variable "region" {
  description = "The GCP region for the cluster"
  type        = string
  default     = "europe-west4"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "live-departures-cluster"
}