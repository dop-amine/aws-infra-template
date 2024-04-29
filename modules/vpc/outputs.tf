output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_one_id" {
  description = "The ID of the first public subnet"
  value       = aws_subnet.public_subnet_one.id
}

output "public_subnet_two_id" {
  description = "The ID of the second public subnet"
  value       = aws_subnet.public_subnet_two.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.public_subnet_one.id, aws_subnet.public_subnet_two.id]
}

output "public_subnet_one_cidr_block" {
  description = "The CIDR block of the first public subnet"
  value       = aws_subnet.public_subnet_one.cidr_block
}

output "public_subnet_two_cidr_block" {
  description = "The CIDR block of the second public subnet"
  value       = aws_subnet.public_subnet_two.cidr_block
}

output "private_subnet_one_id" {
  description = "The ID of the first private subnet"
  value       = aws_subnet.private_subnet_one.id
}

output "private_subnet_two_id" {
  description = "The ID of the second private subnet"
  value       = aws_subnet.private_subnet_two.id
}

output "private_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.private_subnet_one.id, aws_subnet.private_subnet_two.id]
}