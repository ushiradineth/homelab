resource "kubernetes_secret_v1" "psql_credentials" {
  metadata {
    name      = "psql-credentials"
    namespace = kubernetes_namespace_v1.cron.metadata[0].name
  }
  type = "Opaque"

  data = {
    password          = var.cron_postgres_password
    postgres-password = var.cron_postgres_password
  }

  depends_on = [kubernetes_namespace_v1.cron]
}

resource "helm_release" "cron_psql" {
  name      = "psql"
  namespace = kubernetes_namespace_v1.cron.metadata[0].name
  chart     = "oci://registry-1.docker.io/bitnamicharts/postgresql"
  version   = "16.3.4"

  values = [
    yamlencode({
      auth = {
        username       = "cron"
        database       = "cron"
        existingSecret = kubernetes_secret_v1.psql_credentials.metadata[0].name
      }
    })
  ]

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [kubernetes_namespace_v1.cron, kubernetes_secret_v1.psql_credentials]
}

