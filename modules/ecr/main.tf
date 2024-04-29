resource "aws_ecr_repository" "images" {
  for_each = var.services

  name                 = "${var.env}-${each.value.name}-images"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.env
  }

}
