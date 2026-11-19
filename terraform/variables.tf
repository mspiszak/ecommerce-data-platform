variable "project" {
  description = "Nazwa projektu, używana jako prefiks nazw zasobów."
  type        = string
  default     = "ecommercemspi"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,15}$", var.project))
    error_message = "project musi być lowercase, zaczynać się literą, 3-16 znaków [a-z0-9]."
  }
}

variable "env" {
  description = "Środowisko: dev lub prod. Steruje m.in. deletion_protection i purge_protection."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env musi mieć wartość 'dev' albo 'prod'."
  }
}

variable "aws_region" {
  description = "Region AWS, w którym provisionowane są zasoby."
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region musi być poprawnym kodem regionu AWS, np. eu-west-1."
  }
}

# --- Sieć ----------------------------------------------------------------------

variable "create_vpc" {
  description = "true = Terraform tworzy własne VPC z 2 prywatnymi podsieciami (zero ręcznych kroków). false = użyj istniejącego VPC (vpc_id + private_subnet_ids)."
  type        = bool
  default     = true
}

variable "vpc_network_cidr" {
  description = "Zakres CIDR VPC tworzonego przez Terraform (używany tylko gdy create_vpc = true). Musi mieścić się w vpc_cidr."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_network_cidr, 0)) && tonumber(split("/", var.vpc_network_cidr)[1]) <= 20
    error_message = "vpc_network_cidr musi być poprawnym CIDR o masce /20 lub większym zakresie (np. 10.10.0.0/16)."
  }
}

variable "vpc_id" {
  description = "ID istniejącego VPC (wymagane tylko gdy create_vpc = false)."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id musi mieć format vpc-xxxxxxxx."
  }
}

variable "private_subnet_ids" {
  description = "ID prywatnych podsieci (min. 2, różne AZ) dla RDS subnet group (wymagane tylko gdy create_vpc = false)."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.private_subnet_ids) == 0 || (length(var.private_subnet_ids) >= 2 && alltrue([for s in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]{8,17}$", s))]))
    error_message = "Podaj co najmniej 2 podsieci w formacie subnet-xxxxxxxx (albo pustą listę przy create_vpc = true)."
  }
}

variable "vpc_cidr" {
  description = "CIDR sieci wewnętrznej - jedyny zakres z dostępem do RDS na porcie 5432."
  type        = string
  default     = "10.0.0.0/8"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && var.vpc_cidr != "0.0.0.0/0"
    error_message = "vpc_cidr musi być poprawnym CIDR i nie może być 0.0.0.0/0."
  }
}

# --- RDS -----------------------------------------------------------------------

variable "db_name" {
  description = "Nazwa bazy danych PostgreSQL (schemat z M1: customers, orders, products)."
  type        = string
  default     = "ecommerce"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.db_name))
    error_message = "db_name: zaczyna się literą, tylko [a-zA-Z0-9_], max 63 znaki."
  }
}

variable "db_engine_version" {
  description = "Wersja PostgreSQL. \"15\" = najnowsza dostępna 15.x (15.4 jest wycofana przez AWS od 31.03.2025 i nie da się na niej utworzyć nowej instancji)."
  type        = string
  default     = "15"

  validation {
    condition     = can(regex("^15(\\.[0-9]+)?$", var.db_engine_version))
    error_message = "db_engine_version musi być z gałęzi PostgreSQL 15, np. \"15\" albo \"15.10\"."
  }
}

variable "db_username" {
  description = "Login administratora RDS. NIGDY nie wpisuj wartości w .tfvars - użyj TF_VAR_db_username."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,15}$", var.db_username)) && !contains(["admin", "postgres", "rdsadmin"], lower(var.db_username))
    error_message = "db_username: zaczyna się literą, [a-zA-Z0-9_], max 16 znaków, nie może być słowem zarezerwowanym (admin, postgres, rdsadmin)."
  }
}

variable "db_password" {
  description = "Hasło administratora RDS. NIGDY nie wpisuj wartości w .tfvars - użyj TF_VAR_db_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12 && length(var.db_password) <= 128 && !can(regex("[/@\" ]", var.db_password))
    error_message = "db_password: 12-128 znaków, bez znaków / @ \" i spacji (ograniczenie RDS)."
  }
}

variable "db_instance_class" {
  description = "Klasa instancji RDS."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_instance_class))
    error_message = "db_instance_class musi mieć format db.<rodzina>.<rozmiar>, np. db.t3.micro."
  }
}

variable "db_allocated_storage" {
  description = "Rozmiar dysku RDS w GB."
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "db_allocated_storage musi być w zakresie 20-1000 GB (minimum dla gp3 to 20 GB)."
  }
}
