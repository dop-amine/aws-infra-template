variable "env" {
  description = "The deployment environment (e.g., staging or production)."
}

variable "domain" {
  description = "The domain name for the services"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets"
  type        = list(string)
}

variable "services" {
  type = map(object({
    name   = string
    domain = string
  }))
  description = "Map of service configurations"
}
