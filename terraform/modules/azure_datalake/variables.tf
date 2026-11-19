variable "project" {
  description = "Nazwa projektu (bez myślników) - używana w nazwie storage account."
  type        = string

  validation {
    # "st" + project + env musi zmieścić się w 24 znakach [a-z0-9]
    condition     = can(regex("^[a-z0-9]{3,18}$", var.project))
    error_message = "project: tylko [a-z0-9], 3-18 znaków (nazwa storage account max 24 znaki)."
  }
}

variable "env" {
  description = "Środowisko: dev/prod. Steruje purge_protection_enabled w Key Vault."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env musi mieć wartość 'dev' albo 'prod'."
  }
}

variable "name_prefix" {
  description = "Prefiks nazw zasobów z myślnikami, np. ecommerce-dev (Resource Group, Key Vault)."
  type        = string

  validation {
    # "kv-" + name_prefix musi zmieścić się w 24 znakach (limit Key Vault)
    condition     = can(regex("^[a-z0-9-]{3,21}$", var.name_prefix))
    error_message = "name_prefix: [a-z0-9-], max 21 znaków (nazwa Key Vault max 24 znaki)."
  }
}

variable "location" {
  description = "Region Azure."
  type        = string
}

variable "replication_type" {
  description = "Typ replikacji storage account."
  type        = string

  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type musi być jednym z: LRS, GRS, ZRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "tenant_id" {
  description = "Azure AD Tenant ID dla Key Vault."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "tenant_id musi być GUID."
  }
}

variable "sp_object_id" {
  description = "Object ID service principal / usera Terraform, dla którego nadawana jest access policy do Key Vault."
  type        = string
}

variable "tags" {
  description = "Tagi dołączane do zasobów."
  type        = map(string)
  default     = {}
}
