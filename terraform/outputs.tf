# --- AWS ---------------------------------------------------------------------

output "s3_bucket_raw" {
  description = "Nazwa bucketu S3 raw."
  value       = aws_s3_bucket.raw.bucket
}

output "s3_bucket_processed" {
  description = "Nazwa bucketu S3 processed."
  value       = aws_s3_bucket.processed.bucket
}

output "s3_bucket_curated" {
  description = "Nazwa bucketu S3 curated."
  value       = aws_s3_bucket.curated.bucket
}

output "rds_endpoint" {
  description = "Endpoint RDS PostgreSQL (host:port)."
  value       = aws_db_instance.postgres.endpoint
}

output "rds_engine_version" {
  description = "Faktyczna wersja PostgreSQL wybrana przez AWS (np. 15.x)."
  value       = aws_db_instance.postgres.engine_version_actual
}

output "vpc_id" {
  description = "ID VPC, w którym stoi RDS (utworzonego przez Terraform lub przekazanego)."
  value       = local.vpc_id
}

output "glue_role_arn" {
  description = "ARN roli IAM używanej przez Glue Job."
  value       = module.glue_job.role_arn
}

output "glue_job_name" {
  description = "Nazwa Glue Job."
  value       = module.glue_job.job_name
}

# --- Azure ---------------------------------------------------------------------

output "adls_paths" {
  description = "Ścieżki ABFSS do warstw bronze/silver/gold w ADLS Gen2."
  value       = module.azure_datalake.adls_paths
}

output "key_vault_uri" {
  description = "URI Azure Key Vault, gdzie znajduje się sekret adls-connection-string."
  value       = module.azure_datalake.key_vault_uri
}
