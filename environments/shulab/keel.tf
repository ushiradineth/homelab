resource "helm_release" "keel" {
  name       = "keel"
  repository = "https://charts.keel.sh"
  chart      = "keel"
  namespace  = kubernetes_namespace_v1.operator.metadata[0].name
  version    = "1.0.5"

  values = [
    yamlencode({
      policy       = "force"
      trigger      = "poll"
      pollSchedule = "@every 3m"
      mail = {
        enabled = true
        from    = "keel@${var.smtp_domain}"
        to      = var.smtp_to
        smtp = {
          server = var.smtp_host
          port   = var.smtp_port
          user   = var.smtp_username
          pass   = var.smtp_password
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace_v1.operator]
}

