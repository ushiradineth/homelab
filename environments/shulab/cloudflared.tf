resource "kubernetes_secret_v1" "cloudflared_tunnel_token" {
  metadata {
    name      = "cloudflared-tunnel-token"
    namespace = kubernetes_namespace_v1.networking.metadata[0].name
  }
  type = "Opaque"

  data = {
    token = cloudflare_zero_trust_tunnel_cloudflared.shulab.tunnel_token
  }

  depends_on = [kubernetes_namespace_v1.networking, cloudflare_zero_trust_tunnel_cloudflared.shulab]
}

resource "kubernetes_deployment_v1" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace_v1.networking.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        pod = "cloudflared"
      }
    }

    template {
      metadata {
        labels = {
          pod = "cloudflared"
        }
      }

      spec {
        container {
          name              = "cloudflared"
          image             = "cloudflare/cloudflared:2024.12.2"
          image_pull_policy = "IfNotPresent"
          command = [
            "cloudflared",
            "tunnel",
            "--no-autoupdate",
            "--metrics",
            "0.0.0.0:2000",
            "run",
          ]

          env {
            name = "TUNNEL_TOKEN"
            value_from {
              secret_key_ref {
                name = "cloudflared-tunnel-token"
                key  = "token"
              }
            }
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              # Cloudflared has a /ready endpoint which returns 200 if and only if
              # it has an active connection to the edge.
              path = "/ready"
              port = 2000
            }
            failure_threshold     = 1
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace_v1.networking,
    kubernetes_secret_v1.cloudflared_tunnel_token,
    cloudflare_zero_trust_tunnel_cloudflared.shulab
  ]
}
