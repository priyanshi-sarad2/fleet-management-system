variable "create_secrets_manager" {
  description = "Whether to create the Secrets Manager secret"
  type        = bool
  default     = false
}

variable "region" {
  description = "Region where the secret is managed"
  type        = string
  default     = null
}

variable "secret_name" {
  description = "Friendly name of the secret (e.g. fleetman-prod/position-tracker)"
  type        = string
  default     = null
}

variable "description" {
  description = "A description of the secret"
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days Secrets Manager waits before deleting the secret. 0 forces immediate deletion (no recovery); 7-30 otherwise"
  type        = number
  default     = 0
}
