variable "cluster_name" {
  description = "Name of the local kind cluster"
  type        = string
  default     = "spendwise"
}

variable "node_image" {
  description = "kindest/node image; must match the kind version bundled in the provider (v0.31 -> v1.35.0)"
  type        = string
  default     = "kindest/node:v1.35.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "spendwise-admin"
  sensitive   = true
}
