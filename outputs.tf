output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.autopilot.name
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.autopilot.location
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.autopilot.endpoint
  sensitive   = true
}