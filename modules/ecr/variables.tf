variable "env" {
  description = "Deployment environment (e.g., staging, production)."
  type        = string
}

variable "services" {
  type = map(object({
    name   = string
    domain = string
  }))
  description = "Map of service configurations"
}
