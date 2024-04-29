resource "aws_elasticache_cluster" "redis_cluster" {
  for_each = var.services

  cluster_id           = "${var.env}-${each.value.name}-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids = [aws_security_group.redis_sg.id]

  tags = {
    Name        = "${var.env}-${each.value.name}-redis-cluster"
    Environment = var.env
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.env}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.env}-redis-subnet-group"
    Environment = var.env
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.env}-redis-sg"
  description = "Security group for Redis ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-redis-sg"
    Environment = var.env
  }
}
