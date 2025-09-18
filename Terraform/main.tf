###############################
# main.tf – Glue Job completo #
###############################

# ---------
# S3 Bucket para scripts e logs
# ---------
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "meu-bucket-glue-${var.env}"

  tags = {
    Name        = "glue-scripts-${var.env}"
    Environment = var.env
  }
}

resource "aws_s3_bucket" "glue_logs" {
  bucket = "meu-bucket-glue-logs-${var.env}"

  tags = {
    Name        = "glue-logs-${var.env}"
    Environment = var.env
  }
}

# ---------
# IAM Role para o Glue Job
# ---------
resource "aws_iam_role" "glue_role_purchases" {
  name = "glue_job_role_${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# Políticas gerenciadas básicas para Glue e S3
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role_purchases.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_full" {
  role       = aws_iam_role.glue_role_purchases.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.glue_role_purchases.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ---------
# Glue Job
# ---------
resource "aws_glue_job" "tb_spec_purchases" {
  name        = "meu-glue-job-${var.env}"
  role_arn    = aws_iam_role.glue_role_purchases.arn
  description = "Job ETL de exemplo criado via Terraform"

  command {
    name            = "glueetl"
    # Agora apontando para o novo script
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/ex_2_glue_job.py"
    python_version  = "3"
  }

  default_arguments = {
    "--TempDir"             = "s3://${aws_s3_bucket.glue_logs.bucket}/temp/"
    "--job-language"        = "python"
    "--enable-metrics"      = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-glue-datacatalog"          = "true"
  }

  max_retries        = 1
  glue_version       = "4.0"
  worker_type        = "G.1X"
  number_of_workers  = 2

  tags = {
    Environment = var.env
  }
}
