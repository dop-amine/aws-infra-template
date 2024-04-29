variable "env" {
  description = "Deployment environment (e.g., production, staging)"
  type        = string
}

variable "region" {
  description = "AWS region for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster."
  type        = string
}

variable "services" {
  type = map(object({
    name   = string
    domain = string
  }))
  description = "Map of service configurations"
}
