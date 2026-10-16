variable "cluster_name" {
  description = "Name of the local kind cluster"
  type        = string
  default     = "spendwise"
}

variable "node_image" {
  description = "kindest/node image (Kubernetes version)"
  type        = string
  default     = "kindest/node:v1.36.4"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "spendwise-admin"
  sensitive   = true
}
