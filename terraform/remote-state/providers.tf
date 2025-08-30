terraform {
  required_version = ">= 1.13, < 2.0"
  required_providers {
    google = { source = "hashicorp/google" }
  }
}

provider "google" {
  project = var.project_id
  region  = "europe-west1"
}
