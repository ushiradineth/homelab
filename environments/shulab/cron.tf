locals {
  cron_api = {
    labels = {
      "app.kubernetes.io/name"      = "cron"
      "app.kubernetes.io/component" = "api"
    }
  }
}

resource "kubernetes_secret_v1" "api" {
  metadata {
    name      = "api"
    namespace = kubernetes_namespace_v1.cron.metadata[0].name
    labels    = local.cron_api.labels
  }
  type = "Opaque"

  data = {
    PG_PASSWORD = var.cron_postgres_password
    JWT_SECRET  = var.cron_jwt_secret
  }

  depends_on = [kubernetes_namespace_v1.cron]
}

resource "kubernetes_config_map_v1" "api" {
  metadata {
    name      = "api"
    namespace = kubernetes_namespace_v1.cron.metadata[0].name
    labels    = local.cron_api.labels
  }

  data = {
    ENV                 = "PRODUCTION"
    PORT                = "8080"
    PG_USER             = "cron"
    PG_DATABASE         = "cron"
    PG_URL              = "${helm_release.cron_psql.name}-postgresql.${kubernetes_namespace_v1.cron.metadata[0].name}.svc.cluster.local:5432"
    PG_SSLMODE          = "disable"
    CORS_ENABLED        = "true"
    CORS_ALLOWED_ORIGIN = "https://cron.ushira.com"
  }

  depends_on = [kubernetes_namespace_v1.cron, helm_release.cron_psql]
}

resource "kubernetes_deployment_v1" "api" {
  metadata {
    name      = "api"
    namespace = kubernetes_namespace_v1.cron.metadata[0].name
    annotations = {
      "keel.sh/policy"             = "force"
      "keel.sh/trigger"            = "poll"
      "keel.sh/pollSchedule"       = "@every 3m"
      "reloader.stakater.com/auto" = "true"
    }
    labels = local.cron_api.labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.cron_api.labels
    }

    template {
      metadata {
        labels = local.cron_api.labels
      }

      spec {
        init_container {
          name    = "migrations"
          image   = "migrate/migrate:latest"
          command = ["/migrate"]
          args = [
            "-source",
            "github://ushiradineth/cron-be/database/migration#main",
            "-database",
            "postgres://$(PG_USER):$(PG_PASSWORD)@$(PG_URL)/$(PG_DATABASE)?sslmode=$(PG_SSLMODE)",
            "-verbose",
            "up",
          ]
          env_from {
            config_map_ref {
              name = "api"
            }
          }

          env_from {
            secret_ref {
              name = "api"
            }
          }
        }

        container {
          name              = "api"
          image             = "ghcr.io/ushiradineth/cron-be:main"
          image_pull_policy = "Always"

          resources {
            requests = {
              cpu    = "100m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }

          port {
            name           = "http-api"
            container_port = 8080
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          env_from {
            config_map_ref {
              name = "api"
            }
          }

          env_from {
            secret_ref {
              name = "api"
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace_v1.cron,
    kubernetes_secret_v1.api,
    helm_release.cron_psql,
    kubernetes_config_map_v1.api
  ]
}

resource "kubernetes_service_v1" "api" {
  metadata {
    name      = "api"
    namespace = kubernetes_namespace_v1.cron.metadata[0].name
    labels    = local.cron_api.labels
  }

  spec {
    selector = local.cron_api.labels

    port {
      name        = "http-api"
      port        = 8080
      target_port = 8080
    }
  }

  depends_on = [kubernetes_namespace_v1.cron]
}

resource "kubernetes_manifest" "cron_api_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "cron-api"
      namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
      labels = {
        release = local.kube_prometheus_stack.name
      }
    }
    spec = {
      selector = {
        matchLabels = local.cron_api.labels
      }
      namespaceSelector = {
        matchNames = [kubernetes_namespace_v1.cron.metadata[0].name]
      }
      endpoints = [
        {
          port = "http-api"
          path = "/metrics"
        }
      ]
    }
  }

  depends_on = [kubernetes_namespace_v1.cron, kubernetes_namespace_v1.monitoring]
}
