output "tfstate_bucket" { 
    value = google_storage_bucket.tfstate.name 
    description = "Name of the GCS bucket for Terraform state"
}
