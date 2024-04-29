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

variable "alb_security_group_id" {
  description = "The security group ID of the ALB"
  type        = string
}

variable "rds_security_group_id" {
  description = "The security group ID of the RDS database"
  type        = string
}

variable "services" {
  type = map(object({
    name   = string
    domain = string
  }))
  description = "Map of service configurations"
}
