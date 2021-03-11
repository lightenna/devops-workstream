# [2.6.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v2.5.0...v2.6.0) (2019-07-24)


### Features

* support for user-assigned identities ([11a0cab](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/11a0cab))

# [2.5.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v2.4.0...v2.5.0) (2019-07-24)


### Features

* add `storage_mounts` argument ([536c769](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/536c769))

# [2.4.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v2.3.0...v2.4.0) (2019-07-24)


### Features

* support for Azure AD auth ([6b15d5b](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/6b15d5b))

# [2.3.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v2.2.1...v2.3.0) (2019-07-18)


### Bug Fixes

* omit empty app settings by changing variable defaults to `null` ([8b9e784](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/8b9e784))
* rename `sku` to `sku_size` in `plan` ([7f39467](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/7f39467))


### Features

* add support for free and shared plans ([8c23c3b](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/8c23c3b))

## [2.2.1](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v2.2.0...v2.2.1) (2019-07-18)


### Bug Fixes

* web app must be created only after the secret has been created ([9d43f24](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/9d43f24))

# [2.2.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v2.1.0...v2.2.0) (2019-07-18)


### Bug Fixes

* turn off affinity cookie ([112b87d](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/112b87d))


### Features

* add `plan` argument ([dcde5be](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/dcde5be))

# [2.1.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v2.0.0...v2.1.0) (2019-05-07)


### Bug Fixes

* secret name can only contain alphanumeric characters and dashes ([4755133](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/4755133))


### Features

* add `secure_app_settings` and `key_vault_id` arguments ([6616a4c](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/6616a4c))

# [2.0.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v1.5.0...v2.0.0) (2019-04-25)


### Bug Fixes

* dynamic blocks of `ip_restriction` not expected here ([015a188](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/015a188))


### Features

* flatten `ip_restrictions` argument ([70e0faf](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/70e0faf))
* flatten SKU into single argument ([44207a8](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/44207a8))
* rewrite module source code for v0.12 ([2d8457f](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/2d8457f))


### BREAKING CHANGES

* module has been upgraded to use Terraform v0.12-only features.

# [1.5.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v1.4.0...v1.5.0) (2019-04-11)


### Features

* add system-assigned identity ([7e33b43](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/7e33b43))

# [1.4.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v1.3.0...v1.4.0) (2019-04-11)


### Features

* add `always_on` argument ([aa5dfb0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/aa5dfb0))

# [1.3.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v1.2.0...v1.3.0) (2019-03-13)


### Features

* add `ip_restrictions` argument ([aa94d1c](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/aa94d1c))

# [1.2.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v1.1.0...v1.2.0) (2019-03-13)


### Features

* add `app_settings` argument ([8f9d092](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/8f9d092))

# [1.1.0](https://github.com/innovationnorway/terraform-azurerm-web-app-container/compare/v1.0.0...v1.1.0) (2019-03-03)


### Features

* add `tags` argument ([77c791a](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/77c791a))

# 1.0.0 (2019-03-01)


### Features

* initial release ([604daab](https://github.com/innovationnorway/terraform-azurerm-web-app-container/commit/604daab))
