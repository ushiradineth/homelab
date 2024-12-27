variable "cloudflared_token" {
  type        = string
  description = "The cloudflared token to use for the tunnel."
  sensitive   = true
}

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
