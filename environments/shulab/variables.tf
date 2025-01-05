# Cron Backend variables

variable "cron_postgres_password" {
  type        = string
  description = "The password for the cron postgres database."
  sensitive   = true
}

variable "cron_jwt_secret" {
  type        = string
  description = "The JWT secret for the cron application."
  sensitive   = true
}

# ---

# Cloudflare variables

variable "cloudflare_zone" {
  description = "Cloudflare attached domain"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Account ID for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Email address for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_token" {
  description = "Cloudflare API token created at https://dash.cloudflare.com/profile/api-tokens"
  type        = string
  sensitive   = true
}

variable "cloudflare_zero_trust_domain" {
  description = "<your-team-name>.cloudflareaccess.com"
  type        = string
}

# ---

# Server variables

variable "server_ip" {
  description = "IP address of the server"
  type        = string
}

# ---

# SMTP variables

variable "smtp_host" {
  description = "SMTP host"
  type        = string
}

variable "smtp_port" {
  description = "SMTP port"
  type        = number
}

variable "smtp_username" {
  description = "SMTP username"
  type        = string
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  sensitive   = true
}

variable "smtp_domain" {
  description = "SMTP domain"
  type        = string
}

variable "smtp_to" {
  description = "SMTP to address"
  type        = string
}

# ---
