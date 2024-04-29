variable "env" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
}

variable "domain" {
  description = "The domain name for the services"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "db_allowed_ips" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access the bastion host"
}

variable "services" {
  description = "Map of service configurations"
  type = map(object({
    name   = string
    domain = string
  }))
}
