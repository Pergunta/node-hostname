variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for labeling"
  type        = string
  default     = "node-hostname"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "platform-gke"
}

variable "master_ipv4_cidr_block" {
  description = "IP range for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "node_pools" {
  description = "Configuration for GKE node pools"
  type = list(object({
    name               = string
    machine_type      = string
    min_nodes         = number
    max_nodes         = number
    initial_nodes     = number
    disk_size_gb      = number
    disk_type         = string
    preemptible       = bool
    auto_repair       = bool
    auto_upgrade      = bool
  }))
  default = [
    {
      name          = "default-pool"
      machine_type  = "e2-standard-2"
      min_nodes     = 2
      max_nodes     = 5
      initial_nodes = 2
      disk_size_gb  = 30
      disk_type     = "pd-standard"
      preemptible   = false
      auto_repair   = true
      auto_upgrade  = true
    }
  ]
}

variable "github_user" {
  description = "GitHub username for container registry"
  type        = string
}

variable "github_token" {
  description = "GitHub token for container registry"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring stack"
  type        = bool
  default     = true
}

variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = false
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 50
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = []
}
