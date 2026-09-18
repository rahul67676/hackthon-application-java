resource "aws_ecr_repository" "main_repo" {
  name                 = "app-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "app-repository"
  }
}