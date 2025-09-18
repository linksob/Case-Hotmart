provider "aws" {
  region = var.aws_region
  # credenciais: preferível usar AWS CLI / profiles / roles em vez de hardcode
  profile = "terraform_test"
}