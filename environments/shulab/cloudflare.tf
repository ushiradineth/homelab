# Data Sources

data "kubernetes_service" "kube_dns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
}

data "kubernetes_service" "cron_api" {
  metadata {
    name      = "api"
    namespace = "cron"
  }
}

data "kubernetes_service" "grafana" {
  metadata {
    name      = "kube-prometheus-stack-grafana"
    namespace = "monitoring"
  }
}

data "kubernetes_service" "prometheus" {
  metadata {
    name      = "kube-prometheus-stack-prometheus"
    namespace = "monitoring"
  }
}

data "cloudflare_zone" "zone" {
  name = var.cloudflare_zone
}

# ---

# Network

resource "cloudflare_zero_trust_tunnel_virtual_network" "shulab" {
  account_id         = var.cloudflare_account_id
  name               = "shulab"
  is_default_network = true
}

# Enable UDP and TCP proxying on the gateway
resource "cloudflare_zero_trust_gateway_settings" "gateway_settings" {
  account_id = var.cloudflare_account_id

  proxy {
    tcp              = true
    udp              = true # UDP is required for Private DNS
    root_ca          = true
    virtual_ip       = false
    disable_for_time = 3600
  }

  lifecycle {
    ignore_changes = [logging, ssh_session_log]
  }
}

resource "cloudflare_record" "cronapi" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "cronapi"
  content = cloudflare_zero_trust_tunnel_cloudflared.shulab.cname
  type    = "CNAME"
  proxied = true
}

# ---

# Warp Application

resource "cloudflare_zero_trust_access_identity_provider" "pin_login" {
  account_id = var.cloudflare_account_id
  name       = "PIN login"
  type       = "onetimepin"
}

resource "cloudflare_zero_trust_access_application" "warp_application" {
  account_id                = var.cloudflare_account_id
  session_duration          = "18h"
  name                      = "Warp Login App" # This gets overwritten by Cloudflare
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.pin_login.id]
  auto_redirect_to_identity = true
  type                      = "warp"
  app_launcher_visible      = false

  depends_on = [cloudflare_zero_trust_access_identity_provider.pin_login]
}

resource "cloudflare_zero_trust_access_policy" "warp_application_users" {
  application_id = cloudflare_zero_trust_access_application.warp_application.id
  account_id     = var.cloudflare_account_id
  name           = "Allow users to enroll"
  decision       = "allow"
  precedence     = 1

  include {
    email = [var.cloudflare_email]
  }

  depends_on = [cloudflare_zero_trust_access_application.warp_application]
}

# ----

# Tunnel

resource "random_password" "tunnel_secret" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "shulab" {
  account_id = var.cloudflare_account_id
  name       = "shulab"
  secret     = base64encode(random_password.tunnel_secret.result)
  config_src = "cloudflare"

  depends_on = [random_password.tunnel_secret]
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "shulab" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.shulab.id

  # Note: All ingress_rule resources with a hostname must have a DNS record pointing to the tunnel CNAME
  config {
    warp_routing {
      enabled = true
    }
    ingress_rule {
      hostname = cloudflare_record.cronapi.hostname
      service  = "http://${data.kubernetes_service.cron_api.metadata[0].name}.${data.kubernetes_service.cron_api.metadata[0].namespace}.svc.cluster.local:${data.kubernetes_service.cron_api.spec[0].port[0].port}"
    }
    ingress_rule {
      service = "http_status:503"
    }
  }

  depends_on = [
    cloudflare_zero_trust_tunnel_cloudflared.shulab,
    data.kubernetes_service.cron_api,
    cloudflare_record.cronapi
  ]
}

# ---

# Private Network Routes

resource "cloudflare_zero_trust_tunnel_route" "server" {
  account_id         = var.cloudflare_account_id
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.shulab.id
  network            = "${var.server_ip}/32"
  comment            = "Private route into the server"
  virtual_network_id = cloudflare_zero_trust_tunnel_virtual_network.shulab.id

  depends_on = [
    cloudflare_zero_trust_tunnel_virtual_network.shulab,
    cloudflare_zero_trust_tunnel_cloudflared.shulab
  ]
}

resource "cloudflare_zero_trust_tunnel_route" "kube_dns" {
  account_id         = var.cloudflare_account_id
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.shulab.id
  network            = "${data.kubernetes_service.kube_dns.spec[0].cluster_ip}/32"
  comment            = "Private route for kube-dns"
  virtual_network_id = cloudflare_zero_trust_tunnel_virtual_network.shulab.id

  depends_on = [
    cloudflare_zero_trust_tunnel_virtual_network.shulab,
    cloudflare_zero_trust_tunnel_cloudflared.shulab,
    data.kubernetes_service.kube_dns
  ]
}

resource "cloudflare_zero_trust_tunnel_route" "cron_api" {
  account_id         = var.cloudflare_account_id
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.shulab.id
  network            = "${data.kubernetes_service.cron_api.spec[0].cluster_ip}/32"
  comment            = "Private route for Cron Backend API"
  virtual_network_id = cloudflare_zero_trust_tunnel_virtual_network.shulab.id

  depends_on = [
    cloudflare_zero_trust_tunnel_virtual_network.shulab,
    cloudflare_zero_trust_tunnel_cloudflared.shulab,
    data.kubernetes_service.cron_api
  ]
}

resource "cloudflare_zero_trust_tunnel_route" "grafana" {
  account_id         = var.cloudflare_account_id
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.shulab.id
  network            = "${data.kubernetes_service.grafana.spec[0].cluster_ip}/32"
  comment            = "Private route for Grafana"
  virtual_network_id = cloudflare_zero_trust_tunnel_virtual_network.shulab.id

  depends_on = [
    cloudflare_zero_trust_tunnel_virtual_network.shulab,
    cloudflare_zero_trust_tunnel_cloudflared.shulab,
    data.kubernetes_service.grafana
  ]
}

resource "cloudflare_zero_trust_tunnel_route" "prometheus" {
  account_id         = var.cloudflare_account_id
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.shulab.id
  network            = "${data.kubernetes_service.prometheus.spec[0].cluster_ip}/32"
  comment            = "Private route for Prometheus"
  virtual_network_id = cloudflare_zero_trust_tunnel_virtual_network.shulab.id

  depends_on = [
    cloudflare_zero_trust_tunnel_virtual_network.shulab,
    cloudflare_zero_trust_tunnel_cloudflared.shulab,
    data.kubernetes_service.prometheus
  ]
}

# ---

# This resources allows for hostnames ending with .cluster.local to resolve
# with the internal Kubernetes DNS serve, rather than the public DNS server.
# This does not by default expose the whole cluster to the WARP network,
# only the private routes created above will be exposed
# https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/local-domains/

resource "cloudflare_zero_trust_local_fallback_domain" "cluster_local" {
  account_id = var.cloudflare_account_id

  domains {
    dns_server  = [data.kubernetes_service.kube_dns.spec[0].cluster_ip]
    suffix      = "cluster.local"
    description = "Fallback to internal DNS"
  }

  depends_on = [data.kubernetes_service.kube_dns]
}

# ---

# Split Tunnels allow for more granular control over which traffic is exposed to the Warp network
# https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/split-tunnels/

resource "cloudflare_zero_trust_split_tunnel" "include" {
  account_id = var.cloudflare_account_id
  mode       = "include"

  # Required for Authentication
  tunnels {
    host        = var.cloudflare_zero_trust_domain
    description = "Zero Trust Domain (<your-team-name>.cloudflareaccess.com)"
  }

  # For direct SSH access to the server
  tunnels {
    address     = "${var.server_ip}/32"
    description = "Server CIDR"
  }

  # For Internal DNS resolution on client machines
  tunnels {
    address     = "${data.kubernetes_service.kube_dns.spec[0].cluster_ip}/32"
    description = "Kube DNS"
  }

  tunnels {
    address     = "${data.kubernetes_service.cron_api.spec[0].cluster_ip}/32"
    description = "Cron API"
  }

  tunnels {
    address     = "${data.kubernetes_service.grafana.spec[0].cluster_ip}/32"
    description = "Grafana"
  }

  tunnels {
    address     = "${data.kubernetes_service.prometheus.spec[0].cluster_ip}/32"
    description = "Prometheus"
  }

  depends_on = [
    data.kubernetes_service.cron_api,
    data.kubernetes_service.grafana,
    data.kubernetes_service.kube_dns
  ]
}

# ---
