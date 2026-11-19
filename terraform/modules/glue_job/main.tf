# =============================================================================
# Moduł glue_job - reużywalny. Może stworzyć własną rolę IAM (create_iam_role
# = true, count = 1) albo użyć roli przekazanej z zewnątrz (count = 0).
# =============================================================================

data "aws_iam_policy_document" "assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count              = var.create_iam_role ? 1 : 0
  name               = "${var.job_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "s3_access" {
  count = var.create_iam_role ? 1 : 0


  statement {
    sid       = "ObjectAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for arn in var.s3_bucket_arns : "${arn}/*"]
  }

  statement {
    sid       = "ListBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = var.s3_bucket_arns
  }
}

resource "aws_iam_role_policy" "s3_access" {
  count  = var.create_iam_role ? 1 : 0
  name   = "${var.job_name}-s3-access"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.s3_access[0].json
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

locals {
  # Rola efektywnie użyta przez Glue Job - albo stworzona przez moduł,
  # albo przekazana z root module.
  effective_role_arn = var.create_iam_role ? aws_iam_role.this[0].arn : var.role_arn
}

resource "aws_glue_job" "this" {
  name         = var.job_name
  role_arn     = local.effective_role_arn
  glue_version = var.glue_version

  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers

  command {
    name            = "glueetl"
    script_location = var.script_s3_path
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--SOURCE_BUCKET"                    = var.source_bucket
    "--TARGET_BUCKET"                    = var.target_bucket
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--TempDir"                          = "s3://${var.target_bucket}/tmp/"
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.create_iam_role || var.role_arn != null
      error_message = "Gdy create_iam_role = false, musisz przekazać role_arn."
    }
    precondition {
      condition     = !var.create_iam_role || length(var.s3_bucket_arns) > 0
      error_message = "Gdy create_iam_role = true, podaj s3_bucket_arns, do których rola ma mieć dostęp."
    }
  }
}
