# Deklaracja wersji providera azurerm jest w main.tf (required_providers)
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = var.env == "prod" ? false : true
    }
  }
}

data "azurerm_client_config" "current" {}
