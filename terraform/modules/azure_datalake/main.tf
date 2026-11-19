# =============================================================================
# Moduł azure_datalake - Resource Group + ADLS Gen2 (bronze/silver/gold) + Key Vault
# =============================================================================

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}"
  location = var.location
  tags     = var.tags
}

# --- ADLS Gen2 ----------------------------------------------------------------
# Nazwa storage account: 3-24 znaki, tylko [a-z0-9], globalnie unikalna,
# BEZ myślników - stąd sklejamy project + env bez separatora.
resource "azurerm_storage_account" "this" {
  name                = "st${var.project}${var.env}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  account_tier             = "Standard"
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"

  is_hns_enabled = true # Hierarchical Namespace = ADLS Gen2

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = "bronze"
  storage_account_id = azurerm_storage_account.this.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "silver" {
  name               = "silver"
  storage_account_id = azurerm_storage_account.this.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "gold" {
  name               = "gold"
  storage_account_id = azurerm_storage_account.this.id
}

# --- Key Vault ------------------------------------------------------------------

resource "azurerm_key_vault" "this" {
  name                = "kv-${var.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Włączone tylko na prod - na dev Key Vault musi dać się zniszczyć
  # i odtworzyć pod tą samą nazwą (terraform destroy + apply).
  purge_protection_enabled   = var.env == "prod" ? true : false
  soft_delete_retention_days = 90

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "terraform_sp" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = var.sp_object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

resource "azurerm_key_vault_secret" "adls_connection_string" {
  name         = "adls-connection-string"
  value        = azurerm_storage_account.this.primary_connection_string
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault_access_policy.terraform_sp]
}
