data "google_secret_manager_secret_version" "keycloak-user" {
  secret = "keycloak-user"
}
data "google_secret_manager_secret_version" "keycloak-password" {
  secret = "keycloak-password"
}
data "google_secret_manager_secret_version" "keycloak-postgres-password" {
  secret = "keycloak-postgres-password"
}

resource "helm_release" "keycloak" {
  name       = "keycloak"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "22.1.3"
  chart      = "keycloak"
  namespace  = "keycloak"

  create_namespace = true


  set {
    name  = "auth.adminUser"
    value = data.google_secret_manager_secret_version.keycloak-user.secret_data

  }

  set {
    name  = "auth.adminPassword"
    value = data.google_secret_manager_secret_version.keycloak-password.secret_data
  }

  set {
    name  = "postgresql.enabled"
    value = "true"
  }

  set {
    name  = "postgresql.auth.postgresPassword"
    value = data.google_secret_manager_secret_version.keycloak-postgres-password.secret_data
  }

  set {
    name  = "resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "250m"
  }

  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }
}