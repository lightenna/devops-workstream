data "azurerm_client_config" "main" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_app_service_plan" "main" {
  count               = local.plan.id == "" ? 1 : 0
  name                = coalesce(local.plan.name, local.default_plan_name)
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "linux"
  reserved            = true

  sku {
    tier = local.sku_tiers[local.plan.sku_size]
    size = local.plan.sku_size
  }

  tags = var.tags
}

resource "azurerm_app_service" "main" {
  name                = var.name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  app_service_plan_id = local.plan_id

  client_affinity_enabled = false

  https_only = var.https_only

  site_config {
    always_on        = local.always_on
    app_command_line = var.command
    ftps_state       = var.ftps_state
    ip_restriction   = local.ip_restrictions
    linux_fx_version = local.linux_fx_version

    use_32_bit_worker_process = local.use_32_bit_worker_process
  }

  app_settings = merge(var.app_settings, local.secure_app_settings, local.app_settings)

  identity {
    type = (local.identity.enabled ?
      (local.identity.ids != null ? "SystemAssigned, UserAssigned" : "SystemAssigned") :
      "None"
    )
    identity_ids = local.identity.ids
  }

  dynamic "storage_account" {
    for_each = local.storage_mounts
    iterator = s

    content {
      name         = s.value.name
      type         = s.value.share_name != "" ? "AzureFiles" : "AzureBlob"
      account_name = s.value.account_name
      share_name   = s.value.share_name != "" ? s.value.share_name : s.value.container_name
      access_key   = s.value.access_key
      mount_path   = s.value.mount_path
    }
  }

  dynamic "auth_settings" {
    for_each = local.auth.enabled ? [local.auth] : []

    content {
      enabled             = auth_settings.value.enabled
      issuer              = format("https://sts.windows.net/%s/", data.azurerm_client_config.main.tenant_id)
      token_store_enabled = local.auth.token_store_enabled
      additional_login_params = {
        response_type = "code id_token"
        resource      = local.auth.active_directory.client_id
      }
      default_provider = "AzureActiveDirectory"

      dynamic "active_directory" {
        for_each = [auth_settings.value.active_directory]

        content {
          client_id     = active_directory.value.client_id
          client_secret = active_directory.value.client_secret
          allowed_audiences = formatlist("https://%s", concat(
          [format("%s.azurewebsites.net", var.name)], var.custom_hostnames))
        }
      }
    }
  }

  tags = var.tags

  depends_on = [azurerm_key_vault_secret.main]
}

resource "azurerm_app_service_custom_hostname_binding" "main" {
  count               = length(var.custom_hostnames)
  hostname            = var.custom_hostnames[count.index]
  app_service_name    = azurerm_app_service.main.name
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_key_vault_access_policy" "main" {
  count              = length(var.secure_app_settings) > 0 ? 1 : 0
  key_vault_id       = var.key_vault_id
  tenant_id          = azurerm_app_service.main.identity[0].tenant_id
  object_id          = azurerm_app_service.main.identity[0].principal_id
  secret_permissions = ["Get"]
}

resource "azurerm_key_vault_secret" "main" {
  count        = length(local.key_vault_secrets)
  key_vault_id = var.key_vault_id
  name         = local.key_vault_secrets[count.index].name
  value        = local.key_vault_secrets[count.index].value
}
