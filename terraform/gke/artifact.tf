resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "nh-docker"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# Grant GKE nodes read access to Artifact Registry
resource "google_project_iam_member" "nodes_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}
