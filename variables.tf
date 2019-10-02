variable "project" {
  type        = "string"
  description = "project id"
  default     = "trung-terraform"
}

variable "region" {
  type        = "string"
  description = "region of cluster - Jurong West Singapore"
  default     = "asia-southeast1"
}

variable "cluster_ca_certificate" {
  type        = "string"
  description = "region of cluster - Jurong West Singapore"
}

variable "host" {
  type        = "string"
  description = "region of cluster - Jurong West Singapore"
}

variable "zone" {
  type    = "string"
  default = "asia-southeast1-a"
}

variable "username" {
  type        = "string"
  description = "User name for authentication to the Kubernetes linux agent virtual machines in the cluster."
}

variable "password" {
  type        = "string"
  description = "The password for the Linux admin account."
}

variable "init_node_count" {
  type        = "string"
  description = "Init node count"
  default     = 1
}

variable "gcp_node_count" {
  type        = "string"
  description = "The number of nodes to create in this cluster's default node pool."
}

variable "cluster_name" {
  type        = "string"
  description = "Cluster name for the GCP Cluster."
}