variable "azure_location" {
  description = "Region Azure dla Resource Group, Storage Account i Key Vault."
  type        = string
  default     = "polandcentral"

  validation {
    condition     = can(regex("^[a-z]+[a-z0-9]*$", var.azure_location))
    error_message = "azure_location musi być nazwą regionu Azure w formacie lowercase bez spacji, np. westeurope, polandcentral."
  }
}

variable "azure_replication_type" {
  description = "Typ replikacji storage account (LRS/GRS/ZRS/RAGRS/GZRS)."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "RAGRS", "GZRS"], var.azure_replication_type)
    error_message = "azure_replication_type musi być jednym z: LRS, GRS, ZRS, RAGRS, GZRS."
  }
}
