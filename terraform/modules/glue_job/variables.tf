variable "job_name" {
  description = "Nazwa Glue Job."
  type        = string
}

variable "script_s3_path" {
  description = "Pełna ścieżka s3:// do skryptu PySpark."
  type        = string

  validation {
    condition     = startswith(var.script_s3_path, "s3://") && endswith(var.script_s3_path, ".py")
    error_message = "script_s3_path musi mieć format s3://bucket/ścieżka/skrypt.py."
  }
}

variable "source_bucket" {
  description = "Nazwa bucketu źródłowego (raw), przekazywana do skryptu jako SOURCE_BUCKET."
  type        = string
}

variable "target_bucket" {
  description = "Nazwa bucketu docelowego (processed), przekazywana do skryptu jako TARGET_BUCKET."
  type        = string
}

variable "create_iam_role" {
  description = "Czy moduł ma sam stworzyć IAM Role (true) czy użyć roli przekazanej w role_arn (false). Umożliwia reużycie modułu niezależnie od root module."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "ARN istniejącej roli IAM - wymagane gdy create_iam_role = false."
  type        = string
  default     = null

  validation {
    condition     = var.role_arn == null || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", var.role_arn))
    error_message = "role_arn musi być ARN roli IAM (arn:aws:iam::<account>:role/...)."
  }
}

variable "s3_bucket_arns" {
  description = "Lista ARN-ów bucketów S3, do których rola (jeśli tworzona przez moduł) ma dostęp (GetObject/PutObject/DeleteObject + ListBucket)."
  type        = list(string)
  default     = []
}

variable "glue_version" {
  description = "Wersja Glue."
  type        = string
  default     = "4.0"

  validation {
    condition     = contains(["3.0", "4.0", "5.0"], var.glue_version)
    error_message = "glue_version musi być jedną z: 3.0, 4.0, 5.0."
  }
}

variable "worker_type" {
  description = "Typ workera Glue."
  type        = string
  default     = "G.1X"

  validation {
    condition     = contains(["G.025X", "G.1X", "G.2X", "G.4X", "G.8X"], var.worker_type)
    error_message = "worker_type musi być jednym z: G.025X, G.1X, G.2X, G.4X, G.8X."
  }
}

variable "number_of_workers" {
  description = "Liczba workerów Glue."
  type        = number
  default     = 2

  validation {
    condition     = var.number_of_workers >= 2
    error_message = "Glue wymaga co najmniej 2 workerów."
  }
}

variable "tags" {
  description = "Tagi dołączane do zasobów."
  type        = map(string)
  default     = {}
}
