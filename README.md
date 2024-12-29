# 🧪 Homelab Configuration

## About

- This repository consists of IAC that helps me boot up my 'home server' infrastructure using terraform.

## 🔧 Stack

- NixOS
- Terraform
- Cloudflare

## ⚓ Services

- [x] Prometheus, Grafana, Alert Manager, Node Exporter
- [x] cloudflared
- [x] [Cron Backend](https://github.com/ushiradineth/cron-be)
- [x] PostgreSQL
- [ ] Traefik
- [ ] Uptime Kuma
- [ ] Homepage

## Pre-requisites

### Install terraform

- Docs: [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Install tflint

- Docs: [GitHub - terraform-linters/tflint](https://github.com/terraform-linters/tflint?tab=readme-ov-file#installation)

### Terraform login

- `terraform login`

### Setup ENVs

- Generate passwords and secrets externally using `openssl rand -base64 32`

#### Create Cloudflare API Token with the following permissions

![Cloudflare Permission](./images/cloudflare-permissions.png)

## Pre-validation

Please run the following commands before committing or applying any changes:

```bash
cd /environment/<env>
terraform validate
terraform fmt --recursive
tflint
cd ../..
terraform validate
terraform fmt --recursive
tflint
```

## Setting up the Server

- Follow the documentation from the [nix-config](https://github.com/ushiradineth/nix-config/blob/main/NIXOS_INSTALLER.md) repository.
