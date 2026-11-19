module "azure_datalake" {
  source = "./modules/azure_datalake"

  project          = var.project
  env              = var.env
  name_prefix      = local.name_prefix
  location         = var.azure_location
  replication_type = var.azure_replication_type

  tenant_id    = data.azurerm_client_config.current.tenant_id
  sp_object_id = data.azurerm_client_config.current.object_id

  tags = local.common_tags
}
