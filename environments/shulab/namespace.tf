resource "kubernetes_namespace_v1" "networking" {
  metadata {
    name = "networking"
  }
}

resource "kubernetes_namespace_v1" "operator" {
  metadata {
    name = "operator"
  }
}

resource "kubernetes_namespace_v1" "cron" {
  metadata {
    name = "cron"
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
