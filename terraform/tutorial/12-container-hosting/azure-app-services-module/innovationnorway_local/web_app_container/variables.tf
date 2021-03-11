variable "name" {
  type        = string
  description = "The name of the web app."
}

variable "resource_group_name" {
  type        = string
  description = "The name of an existing resource group to use for the web app."
}

variable "container_type" {
  type        = string
  default     = "docker"
  description = "Type of container. The options are: `docker`, `compose` or `kube`."
}

variable "container_config" {
  type        = string
  default     = ""
  description = "Configuration for the container. This should be YAML."
}

variable "container_image" {
  type        = string
  default     = ""
  description = "Container image name. Example: `innovationnorway/python-hello-world:latest`."
}

variable "port" {
  type        = string
  default     = null
  description = "The value of the expected container port number."
}

variable "enable_storage" {
  type        = string
  default     = "false"
  description = "Mount an SMB share to the `/home/` directory."
}

variable "start_time_limit" {
  type        = number
  default     = 230
  description = "Configure the amount of time (in seconds) the app service will wait before it restarts the container."
}

variable "command" {
  type        = string
  default     = ""
  description = "A command to be run on the container."
}

variable "app_settings" {
  type        = map(string)
  default     = {}
  description = "Set app settings. These are avilable as environment variables at runtime."
}

variable "secure_app_settings" {
  type        = map(string)
  default     = {}
  description = "Set sensitive app settings. Uses Key Vault references as values for app settings."
}

variable "key_vault_id" {
  type        = string
  default     = ""
  description = "The ID of an existing Key Vault. Required if `secure_app_settings` is set."
}

variable "always_on" {
  type        = bool
  default     = true
  description = "Either `true` to ensure the web app gets loaded all the time, or `false` to to unload after being idle."
}

variable "https_only" {
  type        = bool
  default     = true
  description = "Redirect all traffic made to the web app using HTTP to HTTPS."
}

variable "ftps_state" {
  type        = string
  default     = "Disabled"
  description = "Set the FTPS state value the web app. The options are: `AllAllowed`, `Disabled` and `FtpsOnly`."
}

variable "ip_restrictions" {
  type        = list(string)
  default     = []
  description = "A list of IP addresses in CIDR format specifying Access Restrictions."
}

variable "custom_hostnames" {
  type        = list(string)
  default     = []
  description = "List of custom hostnames to use for the web app."
}

variable "docker_registry_username" {
  type        = string
  default     = null
  description = "The container registry username."
}

variable "docker_registry_url" {
  type        = string
  default     = "https://index.docker.io"
  description = "The container registry url."
}

variable "docker_registry_password" {
  type        = string
  default     = null
  description = "The container registry password."
}

variable "plan" {
  type        = map(string)
  default     = {}
  description = "A map of app service plan properties."
}

variable "identity" {
  type        = any
  default     = {}
  description = "Managed service identity properties."
}

variable "storage_mounts" {
  type        = any
  default     = []
  description = "List of storage mounts."
}

variable "auth" {
  type        = any
  default     = {}
  description = "Auth settings for the web app. This should be `auth` object."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the web app."
}

locals {
  app_settings = {
    "WEBSITES_CONTAINER_START_TIME_LIMIT" = var.start_time_limit
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = var.enable_storage
    "WEBSITES_PORT"                       = var.port
    "DOCKER_REGISTRY_SERVER_USERNAME"     = var.docker_registry_username
    "DOCKER_REGISTRY_SERVER_URL"          = var.docker_registry_url
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.docker_registry_password
  }

  container_type   = upper(var.container_type)
  container_config = base64encode(var.container_config)

  supported_container_types = {
    COMPOSE = true
    DOCKER  = true
    KUBE    = true
  }
  check_supported_container_types = local.supported_container_types[local.container_type]

  linux_fx_version = "${local.container_type}|${local.container_type == "DOCKER" ? var.container_image : local.container_config}"

  ip_restrictions = [
    for prefix in var.ip_restrictions : {
      ip_address  = split("/", prefix)[0]
      subnet_mask = cidrnetmask(prefix)
    }
  ]

  key_vault_secrets = [
    for name, value in var.secure_app_settings : {
      name  = replace(name, "/[^a-zA-Z0-9-]/", "-")
      value = value
    }
  ]

  secure_app_settings = {
    for secret in azurerm_key_vault_secret.main :
    replace(secret.name, "-", "_") => format("@Microsoft.KeyVault(SecretUri=%s)", secret.id)
  }

  default_plan_name = format("%s-plan", var.name)

  plan = merge({
    id       = ""
    name     = ""
    sku_size = "F1"
  }, var.plan)

  plan_id = coalesce(local.plan.id, azurerm_app_service_plan.main[0].id)

  # FIXME: create a data source that exports list of all SKUs.
  sku_map = {
    "Free"      = ["F1", "Free"]
    "Shared"    = ["D1", "Shared"]
    "Basic"     = ["B1", "B2", "B3"]
    "Standard"  = ["S1", "S2", "S3"]
    "Premium"   = ["P1", "P2", "P3"]
    "PremiumV2" = ["P1v2", "P2v2", "P3v2"]
  }
  skus = flatten([
    for tier, sizes in local.sku_map : [
      for size in sizes : {
        tier = tier
        size = size
      }
    ]
  ])
  sku_tiers = { for sku in local.skus : sku.size => sku.tier }

  is_shared = contains(["F1", "FREE", "D1", "SHARED"], upper(local.plan.sku_size))

  always_on = local.is_shared ? false : true

  use_32_bit_worker_process = local.is_shared ? true : false

  identity = merge({
    enabled = true
    ids     = null
  }, var.identity)

  storage_mounts = [
    for s in var.storage_mounts : merge({
      name           = ""
      account_name   = ""
      access_key     = ""
      share_name     = ""
      container_name = ""
      mount_path     = ""
    }, s)
  ]

  auth = merge({
    enabled = false
    active_directory = {
      client_id     = ""
      client_secret = ""
    }
    token_store_enabled = true
  }, var.auth)
}
