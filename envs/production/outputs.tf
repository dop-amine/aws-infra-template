output "vpc_id" {
  description = "The ID of the VPC created in the VPC module."
  value       = module.vpc.vpc_id
}

output "public_subnet_one_id" {
  description = "The ID of the first public subnet created in the VPC module."
  value       = module.vpc.public_subnet_one_id
}

output "public_subnet_two_id" {
  description = "The ID of the second public subnet created in the VPC module."
  value       = module.vpc.public_subnet_two_id
}

output "public_subnet_one_cidr_block" {
  description = "The CIDR block of the first public subnet created in the VPC module."
  value       = module.vpc.public_subnet_one_cidr_block
}

output "public_subnet_two_cidr_block" {
  description = "The CIDR block of the second public subnet created in the VPC module."
  value       = module.vpc.public_subnet_two_cidr_block
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer created in the ALB module."
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer created in the ALB module."
  value       = module.alb.alb_dns_name
}
