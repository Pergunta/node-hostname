output "project_id" { value = var.project_id }
output "region" { value = var.region }
output "cluster_name" { value = google_container_cluster.gke.name }

output "artifact_registry_repo" {
  value = "${google_artifact_registry_repository.repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

# Connect Gateway command to get kubeconfig for the private control plane
output "connect_gateway_cmd" {
  value = "gcloud container fleet memberships get-credentials ${google_gke_hub_membership.membership.membership_id} --project ${var.project_id}"
}
