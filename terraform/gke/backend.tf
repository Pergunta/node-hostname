
terraform {
  backend "gcs" {
    bucket = ""
    prefix = "terraform/gke/state"
  }
}
