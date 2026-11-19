# =============================================================================
# IAM Role dla AWS Glue - least privilege
# =============================================================================

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_role" {
  name               = "${local.name_prefix}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "glue_s3_access" {
  statement {
    sid       = "ReadRawObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.raw.arn}/*"]
  }

  statement {
    sid       = "ReadWriteProcessedObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.processed.arn}/*"]
  }

  statement {
    sid       = "ListPipelineBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.raw.arn, aws_s3_bucket.processed.arn]
  }
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name   = "${local.name_prefix}-glue-s3-access"
  role   = aws_iam_role.glue_role.id
  policy = data.aws_iam_policy_document.glue_s3_access.json
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
