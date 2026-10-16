# Local platform: the same building blocks as the EKS setup in ../, running on a
# kind cluster on the developer machine. Terraform owns the cluster and every
# platform add-on; ArgoCD then deploys the application itself from Git.

resource "kind_cluster" "this" {
  name           = var.cluster_name
  node_image     = var.node_image
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # ingress-nginx is scheduled onto the node labelled ingress-ready=true
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n",
      ]

      # http://localhost on the Mac reaches the ingress controller in the cluster
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
  }
}

# ------------------------------------------------------------------
# Ingress: routes / to the frontend and /api to the backend
# ------------------------------------------------------------------
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.15.0"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    controller = {
      hostPort     = { enabled = true }
      service      = { type = "NodePort" }
      nodeSelector = { "ingress-ready" = "true" }
      tolerations = [{
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Equal"
        effect   = "NoSchedule"
      }]
      publishService = { enabled = false }
      extraArgs      = { "publish-status-address" = "localhost" }
      resources      = { requests = { cpu = "50m", memory = "90Mi" } }
    }
  })]
}

# ------------------------------------------------------------------
# metrics-server: CPU metrics for the HorizontalPodAutoscalers
# ------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.13.1"
  namespace  = "kube-system"

  values = [yamlencode({
    args = ["--kubelet-insecure-tls"] # kind kubelets use self-signed certs
  })]
}

# ------------------------------------------------------------------
# Observability: Prometheus Operator + Prometheus + Grafana
# ------------------------------------------------------------------
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack" # must match the ServiceMonitor's release label
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "92.8.0"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 900

  values = [
    file("${path.module}/../../monitoring/prometheus-values.yaml"),
    yamlencode({
      grafana = { adminPassword = var.grafana_admin_password }
      prometheus = {
        prometheusSpec = {
          resources = { requests = { cpu = "100m", memory = "256Mi" } }
        }
      }
      # laptop-sized: the SpendWise dashboard only needs the app's own metrics
      defaultRules     = { create = false }
      nodeExporter     = { enabled = false }
      kubeStateMetrics = { enabled = false }
    }),
  ]
}

# ------------------------------------------------------------------
# GitOps: ArgoCD (the Application itself lives in ../../argocd/)
# ------------------------------------------------------------------
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.10.3"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 900

  values = [yamlencode({
    # trimmed for a laptop: no SSO, notifications or ApplicationSets
    dex            = { enabled = false }
    notifications  = { enabled = false }
    applicationSet = { replicas = 0 }
    configs = {
      params = { "server.insecure" = true }
      cm     = { "timeout.reconciliation" = "60s" } # poll Git every minute
    }
  })]

  depends_on = [helm_release.kube_prometheus_stack] # app's ServiceMonitor needs the CRDs
}
