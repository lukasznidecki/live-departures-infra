data "google_secret_manager_secret_version" "google_oauth_client_id" {
  secret = "google-oauth-client-id"
}

data "google_secret_manager_secret_version" "google_oauth_client_secret" {
  secret = "google-oauth-client-secret"
}

data "google_secret_manager_secret_version" "github_key" {
  secret = "github_key"
}


resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  create_namespace = true

  set {
    name  = "notifications.enabled"
    value = "false"
  }

#   values = [
#     templatefile("argocd-values.yaml", {
#       google_client_id     = data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
#       google_client_secret = data.google_secret_manager_secret_version.google_oauth_client_secret.secret_data
#     })
#   ]


#   set {
#     name  = "dex.enabled"
#     value = "true"
#   }

  set {
    name  = "applicationSet.enabled"
    value = "false"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "server.resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "server.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "server.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "server.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "repoServer.resources.limits.cpu"
    value = "300m"
  }
  set {
    name  = "repoServer.resources.limits.memory"
    value = "512Mi"
  }
  set {
    name  = "repoServer.resources.requests.cpu"
    value = "150m"
  }
  set {
    name  = "repoServer.resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "redis.resources.limits.cpu"
    value = "100m"
  }
  set {
    name  = "redis.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "redis.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "redis.resources.requests.memory"
    value = "128Mi"
  }
}

resource "kubectl_manifest" "live_departures_repo" {
  yaml_body = templatefile("${path.module}/live-departures-backend-repo.yaml", {
    github_ssh_key = data.google_secret_manager_secret_version.github_key.secret_data
  })
}

resource "kubectl_manifest" "my_app" {
  yaml_body = file("${path.module}/live-departures-backend.yaml")
  depends_on = [kubectl_manifest.live_departures_repo]
}