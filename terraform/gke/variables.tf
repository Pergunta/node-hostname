variable "project_id" {
  type = string
}
variable "region" {
  type    = string
  default = "europe-west1"
}
variable "cluster_name" {
  type    = string
  default = "assignment-cluster"
}

variable "node_count" {
  type    = number
  default = 2
}
variable "node_type" {
  type    = string
  default = "e2-standard-2"
}
