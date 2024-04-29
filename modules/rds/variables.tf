variable "region" {
  description = "AWS region to deploy resources."
  type        = string
}

variable "env" {
  description = "Environment (e.g., staging or production)"
  type        = string
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the RDS database will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "public_subnet_one_id" {
  description = "The ID of the public subnet one"
  type        = string
}

variable "db_allowed_ips" {
  description = "List of CIDR blocks allowed to access the bastion host"
  type        = list(string)
}
