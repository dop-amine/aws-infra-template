variable "env" {
  description = "The deployment environment (e.g., staging or production)"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}