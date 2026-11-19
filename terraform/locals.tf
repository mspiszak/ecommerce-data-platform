locals {
  # Wspólny prefiks nazw zasobów, np. "ecommerce-dev"
  name_prefix = "${var.project}-${var.env}"

  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Owner       = "data-platform-team"
  }

  env_config = {
    dev = {
      deletion_protection     = false
      purge_protection        = false
      backup_retention_period = 1
      multi_az                = false
      glue_workers            = 2
    }
    prod = {
      deletion_protection     = true
      purge_protection        = true
      backup_retention_period = 7
      multi_az                = true
      glue_workers            = 5
    }
  }

  current_env = local.env_config[var.env]

  s3_bucket_names = {
    raw       = "${local.name_prefix}-raw"
    processed = "${local.name_prefix}-processed"
    curated   = "${local.name_prefix}-curated"
  }

  # --- Sieć: własne VPC (create_vpc = true) albo istniejące --------------------
  vpc_id             = var.create_vpc ? aws_vpc.this[0].id : var.vpc_id
  private_subnet_ids = var.create_vpc ? aws_subnet.private[*].id : var.private_subnet_ids

  vpc_cidr_prefix    = tonumber(split("/", var.vpc_cidr)[1])
  vpc_network_prefix = tonumber(split("/", var.vpc_network_cidr)[1])
}
