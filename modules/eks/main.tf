# EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name     = "${var.env}-cluster"
  role_arn = aws_iam_role.cluster.arn


  vpc_config {
    subnet_ids             = var.private_subnet_ids
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

# Allow ALB to communicate with the EKS cluster
resource "aws_security_group_rule" "alb_to_eks" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  description              = "Allow ALB to communicate with the EKS cluster"
}

# Fargate profile for kube-system
resource "aws_eks_fargate_profile" "kube_system_fargate_profile" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${var.env}-kube-system-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = "kube-system"
  }
}

# Services Fargate profiles
resource "aws_eks_fargate_profile" "fargate_profile" {
  for_each = var.services

  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${var.env}-${each.value.name}-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = each.value.name
  }
}

# Required IAM roles and policies for EKS and Fargate
resource "aws_iam_role" "cluster" {
  name = "${var.env}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# IAM Role for Fargate Pods
resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "${var.env}-fargate-pod-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for Fargate Pod Execution
resource "aws_iam_policy" "fargate_pod_common_policy" {
  name = "${var.env}-fargate-pod-common-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "s3:GetObject",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach IAM Policy to Fargate Pod Execution Role
resource "aws_iam_role_policy_attachment" "fargate_pod_policy_attachment" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = aws_iam_policy.fargate_pod_common_policy.arn
}
