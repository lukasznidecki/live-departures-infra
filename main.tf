terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "aws" {
  region = var.aws_region
}

resource "google_compute_network" "vpc" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc[0].id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

resource "google_container_cluster" "autopilot" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  network    = google_compute_network.vpc[0].name
  subnetwork = google_compute_subnetwork.subnet[0].name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  deletion_protection = false
}

# GCP data sources
data "google_client_config" "default" {
  count = var.cloud_provider == "gcp" ? 1 : 0
}

# AWS data sources
data "aws_eks_cluster" "cluster" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = aws_eks_cluster.eks[0].name
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = aws_eks_cluster.eks[0].name
}

# Conditional Kubernetes provider configuration
provider "kubernetes" {
  host = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? google_container_cluster.autopilot[0].endpoint : null
    ) : (
    length(data.aws_eks_cluster.cluster) > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
  )

  token = var.cloud_provider == "gcp" ? (
    length(data.google_client_config.default) > 0 ? data.google_client_config.default[0].access_token : null
    ) : (
    length(data.aws_eks_cluster_auth.cluster) > 0 ? data.aws_eks_cluster_auth.cluster[0].token : null
  )

  cluster_ca_certificate = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? base64decode(google_container_cluster.autopilot[0].master_auth[0].cluster_ca_certificate) : null
    ) : (
    length(data.aws_eks_cluster.cluster) > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
  )
}

provider "helm" {
  kubernetes {
    host = var.cloud_provider == "gcp" ? (
      length(google_container_cluster.autopilot) > 0 ? google_container_cluster.autopilot[0].endpoint : null
      ) : (
      length(data.aws_eks_cluster.cluster) > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
    )

    token = var.cloud_provider == "gcp" ? (
      length(data.google_client_config.default) > 0 ? data.google_client_config.default[0].access_token : null
      ) : (
      length(data.aws_eks_cluster_auth.cluster) > 0 ? data.aws_eks_cluster_auth.cluster[0].token : null
    )

    cluster_ca_certificate = var.cloud_provider == "gcp" ? (
      length(google_container_cluster.autopilot) > 0 ? base64decode(google_container_cluster.autopilot[0].master_auth[0].cluster_ca_certificate) : null
      ) : (
      length(data.aws_eks_cluster.cluster) > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
    )
  }
}

provider "kubectl" {
  host = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? google_container_cluster.autopilot[0].endpoint : null
    ) : (
    length(data.aws_eks_cluster.cluster) > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
  )

  token = var.cloud_provider == "gcp" ? (
    length(data.google_client_config.default) > 0 ? data.google_client_config.default[0].access_token : null
    ) : (
    length(data.aws_eks_cluster_auth.cluster) > 0 ? data.aws_eks_cluster_auth.cluster[0].token : null
  )

  cluster_ca_certificate = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? base64decode(google_container_cluster.autopilot[0].master_auth[0].cluster_ca_certificate) : null
    ) : (
    length(data.aws_eks_cluster.cluster) > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
  )

  load_config_file = false
}


# Backend configuration - uncomment and configure based on your choice
terraform {
  backend "gcs" {
    bucket = "terraform-state-live-departures"
  }
}

# For AWS, use S3 backend instead:
# terraform {
#   backend "s3" {
#     bucket = "terraform-state-live-departures-aws"
#     key    = "terraform.tfstate"
#     region = "us-west-2"
#   }
# }