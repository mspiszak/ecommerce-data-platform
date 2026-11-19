output "resource_group_name" {
  description = "Nazwa Resource Group."
  value       = azurerm_resource_group.this.name
}

output "storage_account_name" {
  description = "Nazwa ADLS Gen2 storage account."
  value       = azurerm_storage_account.this.name
}

output "adls_paths" {
  description = "Ścieżki ABFSS do warstw bronze/silver/gold."
  value = {
    bronze = "abfss://${azurerm_storage_data_lake_gen2_filesystem.bronze.name}@${azurerm_storage_account.this.name}.dfs.core.windows.net/"
    silver = "abfss://${azurerm_storage_data_lake_gen2_filesystem.silver.name}@${azurerm_storage_account.this.name}.dfs.core.windows.net/"
    gold   = "abfss://${azurerm_storage_data_lake_gen2_filesystem.gold.name}@${azurerm_storage_account.this.name}.dfs.core.windows.net/"
  }
}

output "key_vault_uri" {
  description = "URI Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_name" {
  description = "Nazwa Key Vault."
  value       = azurerm_key_vault.this.name
}
