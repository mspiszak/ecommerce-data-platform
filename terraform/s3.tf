# =============================================================================
# S3 - raw / processed / curated
# =============================================================================

resource "aws_s3_bucket" "raw" {
  bucket = local.s3_bucket_names.raw
  tags   = merge(local.common_tags, { Layer = "raw" })
}

resource "aws_s3_bucket" "processed" {
  bucket = local.s3_bucket_names.processed
  tags   = merge(local.common_tags, { Layer = "processed" })
}

resource "aws_s3_bucket" "curated" {
  bucket = local.s3_bucket_names.curated
  tags   = merge(local.common_tags, { Layer = "curated" })
}

# --- Versioning: raw i processed ---------------------------------------------

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "curated" {
  bucket = aws_s3_bucket.curated.id
  versioning_configuration {
    status = "Suspended"
  }
}

# --- SSE-S3 (AES256) na wszystkich trzech ------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "curated" {
  bucket = aws_s3_bucket.curated.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Block Public Access (4 flagi) na wszystkich trzech ----------------------

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket                  = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "curated" {
  bucket                  = aws_s3_bucket.curated.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Lifecycle: usuń stare wersje na raw po 90 dniach ------------------------

resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  # Musi być zaaplikowany po włączeniu versioningu
  depends_on = [aws_s3_bucket_versioning.raw]

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
