locals {
  github_token = var.cloud_provider == "gcp" ? (
    data.google_secret_manager_secret_version.github_token[0].secret_data
    ) : (
    try(
      jsondecode(data.aws_secretsmanager_secret_version.github_token[0].secret_string).token,
      data.aws_secretsmanager_secret_version.github_token[0].secret_string
    )
  )
}

resource "kubernetes_namespace" "live_departures" {
  metadata {
    name = "live-departures"
  }
}

resource "kubernetes_secret" "ghcr_creds" {
  metadata {
    name      = "ghcr-creds"
    namespace = kubernetes_namespace.live_departures.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = "lukasznidecki"
          password = local.github_token
          email    = "unused@example.com"
          auth     = base64encode("lukasznidecki:${local.github_token}")
        }
      }
    })
  }
}

resource "kubectl_manifest" "patch_default_sa" {
  yaml_body = jsonencode({
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.live_departures.metadata[0].name
    }
    imagePullSecrets = [
      {
        name = kubernetes_secret.ghcr_creds.metadata[0].name
      }
    ]
  })

  depends_on = [kubernetes_secret.ghcr_creds]
}
