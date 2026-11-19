# =============================================================================
# Upload skryptu PySpark + wywołanie modułu glue_job
# =============================================================================

resource "aws_s3_object" "etl_script" {
  bucket = aws_s3_bucket.processed.id
  key    = "scripts/orders_etl.py"
  source = "${path.module}/../glue_scripts/orders_etl.py"
  etag   = filemd5("${path.module}/../glue_scripts/orders_etl.py")

  # Szyfrowanie bucketu musi istnieć przed uploadem; etag == MD5 działa
  # tylko dla SSE-S3 (AES256), nie dla SSE-KMS.
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.processed]
}

module "glue_job" {
  source = "./modules/glue_job"

  job_name       = "orders-etl-job"
  script_s3_path = "s3://${aws_s3_bucket.processed.bucket}/${aws_s3_object.etl_script.key}"

  # Root module zarządza rolą centralnie (iam.tf), więc moduł jej nie tworzy
  # (count = 0). Ścieżka create_iam_role = true jest w pełni wspierana, gdy
  # moduł jest używany samodzielnie w innym projekcie.
  create_iam_role = false
  role_arn        = aws_iam_role.glue_role.arn

  source_bucket     = aws_s3_bucket.raw.bucket
  target_bucket     = aws_s3_bucket.processed.bucket
  number_of_workers = local.current_env.glue_workers

  tags = local.common_tags

  depends_on = [
    aws_s3_object.etl_script,
    aws_iam_role_policy.glue_s3_access,
    aws_iam_role_policy_attachment.glue_service_role,
  ]
}
