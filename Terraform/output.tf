output "glue_scripts_bucket" {
  description = "Nome do bucket S3 para scripts do Glue"
  value       = aws_s3_bucket.glue_scripts.bucket
}

output "glue_logs_bucket" {
  description = "Nome do bucket S3 para logs do Glue"
  value       = aws_s3_bucket.glue_logs.bucket
}

output "glue_job_name" {
  description = "Nome do Glue Job criado"
  value       = aws_glue_job.tb_spec_purchases.name
}

output "glue_role_arn" {
  description = "ARN da role IAM usada pelo Glue Job"
  value       = aws_iam_role.glue_role_purchases.arn
}