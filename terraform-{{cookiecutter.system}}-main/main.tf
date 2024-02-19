#_____________________________________________________
# Configure the Microsoft Azure provider
#_____________________________________________________
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.62, < 4.0"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "{{cookiecutter.organization}}"
    workspaces {
      prefix = "{{cookiecutter.workspace_prefix}}-"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = true
  use_oidc                   = true
  //use_cli = false
}

locals {
  eac = yamldecode(file("./config/sef_eac_{{cookiecutter.environment}}.yaml"))
}

variable "env" {
  description = "The environment in which the resources will be deployed"
  type        = string
}
module "sef_eac" {
  //Core Properties for Application Landscape

  //source = "github.com/Medline-Developer-Community/terraform-m1-eac-applzm"
  # insert required variables here
  source                   = "app.terraform.io/okuppurajah/eac-applzm/m1"
  version                  = "2.1.3"
  env                      = var.env
  app_short_name           = local.eac.eac_core.app_short_name
  immutability             = local.eac.eac_core.immutability
  location                 = local.eac.eac_core.location
  tags                     = local.tags
  vnet_address_space       = local.eac.malz_vnet.address_space
  enable_distrohub_peering = local.eac.eac_core.connect_hub
  zone_redundent           = local.eac.eac_core.zone_redundant

  //********CORE PROPERTIES FOR COMPUTE*********
  ase_buildagent_size = local.eac.compute_ase.build_agent_pool_size
  //ase_enabled                      = local.eac.compute_ase.enabled ? 1 : 0
  ase_sku_name                     = local.eac.compute_ase.sku_name
  ase_subnet_apps_address_apace    = local.eac.compute_ase.apps_subnet_address_space
  ase_subnet_runtime_address_apace = local.eac.compute_ase.runtime_subnet_address_space
  internal_cidr_ranges             = local.eac.compute_ase.cidr_ranges
  devtool_portal_enabled           = local.eac.compute_ase.devtool_portal
  ase_count                        = local.eac.compute_ase.enabled ? 1 : 0

  //**********CORE PAAS SERVICE- COSMOSDB*****************
  cosmosdb_container_name = join("_", [local.eac.paas_cosmosdb.cosmos_container, local.eac.eac_core.app_short_name, var.env])
  cosmosdb_count          = local.eac.paas_cosmosdb.enabled ? 1 : 0

  //**********CORE PAAS SERVICE- STORAGE*****************
  count_storage = local.eac.paas_storage.enabled ? 1 : 0

  //**********CORE PAAS SERVICE- EVENT-HUB*****************
  eh_consumergroup = format("%s_cg_%s_%s_%s_%s", "m1", "malz", local.eac.eac_core.app_short_name, var.env, local.eac.paas_eventhub.consumer_group)
  eventhub_count   = local.eac.paas_eventhub.enabled ? 1 : 0
  eventhub_name    = local.eac.paas_eventhub.eventhub_name

  //**********CORE PAAS SERVICE- REDIS-CACHE*****************
  redis_capacity = local.eac.paas_redis.capacity
  redis_count    = local.eac.paas_redis.enabled ? 1 : 0
  redis_family   = local.eac.paas_redis.family
  redis_sku_name = local.eac.paas_redis.sku_name

}




