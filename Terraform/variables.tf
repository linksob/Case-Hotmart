variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "sa-east-1"
}

variable "env" {
  description = "Ambiente (dev|staging|prod)"
  type        = string
  default     = "dev"
}