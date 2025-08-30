
#Setup apis 
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "artifactregistry.googleapis.com",
    "connectgateway.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}
#--------------------------------
# VPC Subnet and Nat
#--------------------------------

resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/20"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  region                             = var.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

#--------------------------------
# gke cluster
#--------------------------------   
resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel { channel = "REGULAR" }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_global_access_config { enabled = false }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
  }
  depends_on = [
    google_project_service.apis,
    google_compute_subnetwork.subnet
  ]
}
#--------------------------------       
# Node Pool 
#--------------------------------
# Note: using default service account for simplicity, but best practice is to create a dedicated one
data "google_compute_default_service_account" "default" {} # use of data like we talked about in the interview :)

resource "google_container_node_pool" "default_pool" {
  name       = "default-pool"
  cluster    = google_container_cluster.gke.name
  location   = var.region
  node_count = var.node_count

  node_config {
    machine_type    = var.node_type
    service_account = data.google_compute_default_service_account.default.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    # Avoid SSD quota completely 
    disk_type    = "pd-standard"
    disk_size_gb = 100

    tags   = ["gke-private"]
    labels = { workload = "general" }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config { mode = "GKE_METADATA" }
    metadata = { disable-legacy-endpoints = "true" }
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 5
  }
}

#---------------------------------
# Global IP for Ingress
#---------------------------------
resource "google_compute_global_address" "app_ingress_ip" {
  name         = "app-ingress-ip"
  address_type = "EXTERNAL"
}

output "app_global_ip" {
  value       = google_compute_global_address.app_ingress_ip.address
  description = "Create DNS A record for your app domain pointing here"
}

#--------------------------------
# GKE Hub Membership for connect gateway
#--------------------------------
resource "google_gke_hub_membership" "membership" {
  membership_id = var.cluster_name
  endpoint {
    gke_cluster { resource_link = google_container_cluster.gke.id }
  }
  depends_on = [
    google_project_service.apis,
    google_container_cluster.gke
  ]
}
