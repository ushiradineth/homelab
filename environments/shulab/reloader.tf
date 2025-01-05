resource "helm_release" "reloader" {
  name       = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  namespace  = kubernetes_namespace_v1.operator.metadata[0].name
  version    = "1.2.0"

  values = [
    yamlencode({
      reloader = {
        syncAfterRestart = true
        watchGlobally    = true
      }
    })
  ]

  depends_on = [kubernetes_namespace_v1.operator]
}

