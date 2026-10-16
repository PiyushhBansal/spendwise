output "cluster_name" {
  value = kind_cluster.this.name
}

output "kubeconfig_context" {
  value = "kind-${kind_cluster.this.name}"
}

output "app_url" {
  value = "http://localhost/"
}

output "next_steps" {
  value = <<-EOT
    kubectl apply -f ../../k8s/namespace.yaml
    kubectl apply -f ../../argocd/application.yaml
    kubectl port-forward -n argocd svc/argocd-server 8081:80
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3001:80
  EOT
}
