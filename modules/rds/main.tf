
resource "random_password" "rds_password" {
  length  = 16
  special = true
}

resource "aws_ssm_parameter" "rds_username" {
  name  = "${var.env}_rds_username"
  type  = "SecureString"
  value = "admin"
}

resource "aws_ssm_parameter" "rds_password" {
  name  = "${var.env}_rds_password"
  type  = "SecureString"
  value = random_password.rds_password.result
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.env}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.env}-rds-subnet-group"
    Environment = var.env
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-rds-sg"
  description = "Security group for RDS instances in ${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    # from_port       = 5432 # TODO: Uncomment when switching to PostgreSQL
    # to_port         = 5432 # TODO: Uncomment when switching to PostgreSQL
    from_port       = 3306 # TODO: Delete when switching to PostgreSQL
    to_port         = 3306 # TODO: Delete when switching to PostgreSQL
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id, aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.env
  }
}

# resource "aws_db_instance" "postgres_db" {
#   allocated_storage       = 20
#   engine                  = "postgres"
#   engine_version          = "12"
#   instance_class          = "db.t3.large"
#   multi_az                = true
#   identifier              = "${var.env}-postgres"
#   username                = aws_ssm_parameter.rds_username.value
#   password                = aws_ssm_parameter.rds_password.value
#   db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
#   vpc_security_group_ids  = [aws_security_group.rds_sg.id]

#   storage_encrypted       = true
#   # deletion_protection     = true # TODO: uncomment when go live

#   backup_retention_period = 7
#   backup_window           = "03:00-06:00"  # UTC
#   copy_tags_to_snapshot   = true
#   skip_final_snapshot     = false
#   final_snapshot_identifier = "${var.env}-postgres-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"

#   enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

#   tags = {
#     Name        = "${var.env}-postgres"
#     Environment = var.env
#   }
# }

resource "aws_db_instance" "postgres_db" {
  allocated_storage      = 200
  engine                 = "mysql"
  engine_version         = "5.7.44"
  instance_class         = "db.t3.large"
  multi_az               = true
  identifier             = "${var.env}-mysql-eks"
  username               = aws_ssm_parameter.rds_username.value
  password               = aws_ssm_parameter.rds_password.value
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  storage_encrypted   = true
  skip_final_snapshot = true
}

# Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "${var.env}-bastion-sg"
  description = "Security group for bastion host in ${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.db_allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-bastion-sg"
    Environment = var.env
  }
}

# Bastion Host IAM Role
resource "aws_iam_role" "bastion_ssm_role" {
  name = "${var.env}-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })

  tags = {
    Name        = "${var.env}-bastion-ssm-role"
    Environment = var.env
  }
}

# Bastion Host IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Bastion Host IAM Instance Profile
resource "aws_iam_instance_profile" "bastion_ssm_instance_profile" {
  name = "${var.env}-bastion-ssm-instance-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion_host" {
  ami                    = "ami-0a93a903c0f607485" # TODO: Update to good AMI for region
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_one_id
  iam_instance_profile   = aws_iam_instance_profile.bastion_ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  ## TODO: Update script to be more secure and robust
  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y mysql socat awslogs fail2ban
                systemctl enable awslogsd
                systemctl start awslogsd
                systemctl enable fail2ban
                systemctl start fail2ban

                # Save the RDS endpoint as an environment variable
                RDS_ENDPOINT="${aws_db_instance.postgres_db.endpoint}"

                # Create a script for connecting to the MySQL database manually
                cat << "END" > /usr/local/bin/connect-db.sh
                #!/bin/bash
                username=$(aws ssm get-parameter --name "${var.env}_rds_username" --region=${var.region} --with-decryption --query "Parameter.Value" --output text)
                password=$(aws ssm get-parameter --name "${var.env}_rds_password" --region=${var.region} --with-decryption --query "Parameter.Value" --output text)
                mysql -h \$RDS_ENDPOINT -u "\$username" -p"\$password"
                END
                chmod +x /usr/local/bin/connect-db.sh

                # Setup socat for TCP forwarding
                nohup socat TCP-LISTEN:3306,fork TCP:$RDS_ENDPOINT:3306 &
                EOF

  tags = {
    Name        = "${var.env}-bastion-host"
    Environment = var.env
  }
}
