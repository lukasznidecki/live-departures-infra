resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

data "google_secret_manager_secret_version" "grafana_user" {
  secret = "grafana_user"
}

data "google_secret_manager_secret_version" "grafana_password" {
  secret = "grafana_password"
}


resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.8.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        persistentVolume = {
          enabled = true
          size    = "8Gi"
        }
        resources = {
          limits = {
            cpu    = "200m"
            memory = "1000Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "512Mi"
          }
        }
        retention = "15d"
      }

      alertmanager = {
        enabled = false
      }

      kube-state-metrics = {
        enabled = true
      }

      prometheus-node-exporter = {
        enabled = false
      }

      prometheus-pushgateway = {
        enabled = false
      }
    })
  ]

  depends_on = [google_container_cluster.autopilot]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.3.7"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      adminUser     = data.google_secret_manager_secret_version.grafana_user.secret_data
      adminPassword = data.google_secret_manager_secret_version.grafana_password.secret_data

      service = {
        type = "ClusterIP"
        port = 80
      }

      persistence = {
        enabled = true
        size    = "10Gi"
      }

      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-server:80"
              access    = "proxy"
              isDefault = true
            }
          ]
        }
      }

      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [
            {
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
            }
          ]
        }
      }

      dashboards = {
        default = {
          "kubernetes-cluster-monitoring" = {
            gnetId     = 315
            revision   = 3
            datasource = "Prometheus"
          }
          "kubernetes-pod-monitoring" = {
            gnetId     = 6417
            revision   = 1
            datasource = "Prometheus"
          }
        }
      }

      resources = {
        limits = {
          cpu    = "200m"
          memory = "200Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    })
  ]

  depends_on = [google_container_cluster.autopilot]
}