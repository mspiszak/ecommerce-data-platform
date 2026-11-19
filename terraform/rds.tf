# =============================================================================
# RDS PostgreSQL
# =============================================================================

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = local.private_subnet_ids
  tags       = local.common_tags

  lifecycle {
    precondition {
      condition     = var.create_vpc || (var.vpc_id != null && length(var.private_subnet_ids) >= 2)
      error_message = "Przy create_vpc = false musisz podać vpc_id oraz min. 2 private_subnet_ids."
    }
  }
}

resource "aws_security_group" "rds" {
  name   = "${local.name_prefix}-rds-sg"
  vpc_id = local.vpc_id


  description = "PostgreSQL access only from inside the VPC"

  ingress {
    description = "PostgreSQL from VPC CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_db_instance" "postgres" {
  identifier = "${local.name_prefix}-postgres"
  engine     = "postgres"


  engine_version             = var.db_engine_version
  auto_minor_version_upgrade = true

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  multi_az                  = local.current_env.multi_az
  backup_retention_period   = local.current_env.backup_retention_period
  deletion_protection       = var.env == "prod" ? true : false
  skip_final_snapshot       = var.env == "prod" ? false : true
  final_snapshot_identifier = var.env == "prod" ? "${local.name_prefix}-final-snapshot" : null

  tags = local.common_tags
}
