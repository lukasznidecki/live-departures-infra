resource "helm_release" "kube_prometheus_stack" {
  timeout          = 900
  name             = "monitoring"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "61.4.0"
  create_namespace = true

  values = [
    yamlencode({
      defaultRules     = { create = false }
      alertmanager     = { enabled = false }
      kubeStateMetrics = { enabled = false }
      nodeExporter     = { enabled = false }

      kubeApiServer         = { enabled = false }
      kubeControllerManager = { enabled = false }
      kubeScheduler         = { enabled = false }
      kubeProxy             = { enabled = false }
      coreDns               = { enabled = false }
      kubeEtcd              = { enabled = false }

      kubelet = {
        enabled        = false
        service        = { enabled = false }
        serviceMonitor = { enabled = false }
      }

      prometheusOperator = {
        admissionWebhooks = {
          enabled = false
        patch = { enabled = false } }
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      grafana = {
        enabled = true
        service = { type = "ClusterIP" }
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      prometheus = {
        prometheusSpec = {
          replicas               = 1
          retention              = "12h"
          enableAdminAPI         = false
          serviceMonitorSelector = {}
          podMonitorSelector     = {}
          resources = {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }
      }
    })
  ]
}
