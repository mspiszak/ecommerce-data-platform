output "job_name" {
  description = "Nazwa stworzonego Glue Job."
  value       = aws_glue_job.this.name
}

output "job_arn" {
  description = "ARN Glue Job."
  value       = aws_glue_job.this.arn
}

output "role_arn" {
  description = "ARN roli IAM użytej przez Glue Job (własna lub przekazana)."
  value       = local.effective_role_arn
}
