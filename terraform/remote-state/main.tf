resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
}

resource "google_storage_bucket" "tfstate" {
  name                        = "terraform-state-${var.project_id}-${random_id.bucket_suffix.hex}"
  location                    = var.location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning { enabled = true }
  depends_on = [google_project_service.storage]
}
# Generate unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
