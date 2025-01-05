locals {
  kube_prometheus_stack = {
    name = "kube-prometheus-stack"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "67.7.0"

  values = [
    yamlencode({
      nameOverride     = local.kube_prometheus_stack.name
      fullnameOverride = local.kube_prometheus_stack.name
      grafana = {
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
            cert-manager-kubernetes = {
              gnetId     = 20842
              revision   = 3
              datasource = "Prometheus"
            }
            horizontal-pod-autoscaler-hpa = {
              gnetId     = 22128
              revision   = 11
              datasource = "Prometheus"
            }
            go-processes = {
              gnetId     = 6671
              revision   = 2
              datasource = "Prometheus"
            }
            postgresql-database = {
              gnetId     = 9628
              revision   = 8
              datasource = "Prometheus"
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace_v1.monitoring]
}

