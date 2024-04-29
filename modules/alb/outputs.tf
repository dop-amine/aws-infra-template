output "alb_arn" {
  value       = aws_lb.alb.arn
  description = "The ARN of the Application Load Balancer."
}

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "The DNS name of the Application Load Balancer."
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}
