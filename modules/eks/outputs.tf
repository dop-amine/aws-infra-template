output "cluster_name" {
  description = "The name of the EKS Cluster."
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API."
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_id" {
  description = "The EKS cluster ID."
  value       = aws_eks_cluster.cluster.id
}

output "eks_security_group_id" {
  description = "The security group ID attached to the EKS cluster."
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}
