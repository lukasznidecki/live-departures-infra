variable "cloud_provider" {
  description = "Cloud provider to use (gcp or aws)"
  type        = string
  default     = "gcp"
  validation {
    condition     = contains(["gcp", "aws"], var.cloud_provider)
    error_message = "Cloud provider must be either 'gcp' or 'aws'."
  }
}

variable "project_id" {
  description = "The GCP project ID (only used when cloud_provider is 'gcp')"
  default     = "live-departures"
}

variable "aws_region" {
  description = "The AWS region for the EKS cluster (only used when cloud_provider is 'aws')"
  type        = string
  default     = "us-west-2"
}

variable "region" {
  description = "The GCP region for the cluster (only used when cloud_provider is 'gcp')"
  type        = string
  default     = "europe-west4"
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string
  default     = "live-departures-cluster"
}