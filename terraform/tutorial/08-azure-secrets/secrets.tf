
resource "random_id" "seckey" {
  # new random_id generated each time this 'keepers' map changes
  keepers = {
    fish = 1
  }
  byte_length = 8
}

resource "random_string" "secvalue" {
  length = 24
  special = true
  # explicitly use the full list of special characters
  # override_special = "!@#$%&*()-_=+[]{}<>:?"
  # explicitly use a narrow set of special characters
  override_special = "!@#$%*_"
}

#
# create secrets
#

resource "azurerm_key_vault_secret" "secretex" {
  name = format("%s%s", "kv-secret-", random_id.seckey.hex)
  value = random_string.secvalue.result
  key_vault_id = azurerm_key_vault.mkv.id
  depends_on = [
    azurerm_key_vault_access_policy.perm_tfsp]
  tags = {
    name = format("%s%s", "kv-secret-", random_id.seckey.hex)
    project = var.project
    environment = terraform.workspace
  }
}

resource "azurerm_key_vault_key" "keyex" {
  name = format("%s%s", "kv-key-", random_id.seckey.hex)
  key_vault_id = azurerm_key_vault.mkv.id
  key_type = "RSA"
  key_size = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  # ensure we have permission to operate on key_vault before creating keys
  depends_on = [
    azurerm_key_vault_access_policy.perm_tfsp]
  tags = {
    name = format("%s%s", "kv-key-", random_id.seckey.hex)
    project = var.project
    environment = terraform.workspace
  }
}

resource "azurerm_key_vault_certificate" "certex" {
  name = format("%s%s", "kv-cert-intaz-", random_id.seckey.hex)
  key_vault_id = azurerm_key_vault.mkv.id
  # set certificate policies: encryption, lifetime, key length etc.
  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_size = 2048
      key_type = "RSA"
      reuse_key = true
    }
    lifetime_action {
      action {
        # don't AutoRenew because it's £2.24/request
        action_type = "EmailContacts"
      }
      trigger {
        days_before_expiry = 30
      }
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      # Server Authentication (selected) = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = [
        "1.3.6.1.5.5.7.3.1"]
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]
      subject_alternative_names {
        dns_names = [
          "internal.azure-dns.lightenna.com"]
      }
      subject = "CN=intaz-devopsworkstream"
      validity_in_months = 12
    }
  }
  # ensure we have permission to operate on key_vault before creating keys
  depends_on = [
    azurerm_key_vault_access_policy.perm_tfsp]
  tags = {
    name = "${format("%s%s", "kv-cert-intaz-", random_id.seckey.hex)}"
    project = var.project
    environment = terraform.workspace
  }
}

resource "azurerm_key_vault_secret" "eyaml_private_key" {
  # name cannot contain dots (.) or underscores (_)
  name = replace(var.private_key_name,"/[^0-9A-Za-z]/","-")
  value = file(local.private_key_fullpath)
  key_vault_id = azurerm_key_vault.mkv.id
  # ensure we have permission to operate on key_vault before creating keys
  depends_on = [
    azurerm_key_vault_access_policy.perm_tfsp]
  tags = {
    name = var.private_key_name
    project = var.project
    environment = terraform.workspace
  }
}

resource "azurerm_key_vault_secret" "eyaml_public_key" {
  name = replace(var.public_key_name,"/[^0-9A-Za-z]/","-")
  value = file(local.public_key_fullpath)
  key_vault_id = azurerm_key_vault.mkv.id
  depends_on = [
    azurerm_key_vault_access_policy.perm_tfsp]
  tags = {
    name = var.public_key_name
    project = var.project
    environment = terraform.workspace
  }
}

