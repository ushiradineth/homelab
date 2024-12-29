terraform {
  required_version = ">= 1.9.8"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.49.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "default"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
