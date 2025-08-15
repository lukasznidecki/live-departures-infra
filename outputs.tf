output "cloud_provider" {
  description = "The cloud provider being used"
  value       = var.cloud_provider
}

output "cluster_name" {
  description = "The name of the Kubernetes cluster"
  value = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? google_container_cluster.autopilot[0].name : ""
    ) : (
    length(aws_eks_cluster.eks) > 0 ? aws_eks_cluster.eks[0].name : ""
  )
}

output "cluster_location" {
  description = "The location/region of the Kubernetes cluster"
  value = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? google_container_cluster.autopilot[0].location : ""
    ) : (
    var.aws_region
  )
}

output "cluster_endpoint" {
  description = "The endpoint of the Kubernetes cluster"
  value = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? google_container_cluster.autopilot[0].endpoint : ""
    ) : (
    length(aws_eks_cluster.eks) > 0 ? aws_eks_cluster.eks[0].endpoint : ""
  )
  sensitive = true
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value = var.cloud_provider == "gcp" ? (
    length(google_container_cluster.autopilot) > 0 ? google_container_cluster.autopilot[0].master_version : ""
    ) : (
    length(aws_eks_cluster.eks) > 0 ? aws_eks_cluster.eks[0].version : ""
  )
}

# GCP-specific outputs
output "vpc_name" {
  description = "The name of the VPC (GCP only)"
  value       = var.cloud_provider == "gcp" && length(google_compute_network.vpc) > 0 ? google_compute_network.vpc[0].name : null
}

# AWS-specific outputs
output "vpc_id" {
  description = "The ID of the VPC (AWS only)"
  value       = var.cloud_provider == "aws" && length(aws_vpc.eks_vpc) > 0 ? aws_vpc.eks_vpc[0].id : null
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets (AWS only)"
  value       = var.cloud_provider == "aws" ? aws_subnet.eks_private_subnet[*].id : null
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets (AWS only)"
  value       = var.cloud_provider == "aws" ? aws_subnet.eks_public_subnet[*].id : null
}