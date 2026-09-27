# One ECR repository per app image (frontend + backend x 5 apps = 10 repos).
# force_delete lets `terraform destroy` remove repos that still hold images,
# so teardown never gets stuck.

resource "aws_ecr_repository" "ecommerce_frontend" {
  name                 = "dev-cluster/ecommerce-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "ecommerce_backend" {
  name                 = "dev-cluster/ecommerce-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "banking_frontend" {
  name                 = "dev-cluster/banking-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "banking_backend" {
  name                 = "dev-cluster/banking-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "food_delivery_frontend" {
  name                 = "dev-cluster/food-delivery-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "food_delivery_backend" {
  name                 = "dev-cluster/food-delivery-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "student_portal_frontend" {
  name                 = "dev-cluster/student-portal-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "student_portal_backend" {
  name                 = "dev-cluster/student-portal-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "support_tickets_frontend" {
  name                 = "dev-cluster/support-tickets-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "support_tickets_backend" {
  name                 = "dev-cluster/support-tickets-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
