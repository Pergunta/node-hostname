
terraform {
  backend "gcs" {
    bucket = "terraform-state-fiery-azimuth-470410-b6-d3ac623e"
    prefix = "terraform/gke/state"
  }
}
