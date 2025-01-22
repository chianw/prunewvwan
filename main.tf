resource "random_pet" "vvan_name" {
  length    = 2
  separator = "-"
}

locals {
  firewall1_key        = "aue-vhub1-fw"
  firewall1_name       = "fw1-avm-vwan-${random_pet.vvan_name.id}"
  firewall2_key        = "aue-vhub2-fw"
  firewall2_name       = "fw2-avm-vwan-${random_pet.vvan_name.id}"  
  location            = "australiaeast"
  resource_group_name = "rg-avm-vwan-${random_pet.vvan_name.id}"
  tags = {
    environment = "avm-vwan-testing"
    deployment  = "terraform"
  }
  virtual_hub1_key  = "aue-vhub1"
  virtual_hub1_name = "vhub1-avm-vwan-${random_pet.vvan_name.id}"
  virtual_hub2_key  = "aue-vhub2"
  virtual_hub2_name = "vhub2-avm-vwan-${random_pet.vvan_name.id}"  
  virtual_wan_name = "vwan-avm-vwan-${random_pet.vvan_name.id}"
}

module "vwan_with_vhub" {
  source                         = "git::https://github.com/Azure/terraform-azurerm-avm-ptn-virtualwan?ref=v0.8.0"
  create_resource_group          = true
  resource_group_name            = local.resource_group_name
  location                       = local.location
  virtual_wan_name               = local.virtual_wan_name
  disable_vpn_encryption         = false
  allow_branch_to_branch_traffic = true
  type                           = "Standard"
  virtual_wan_tags               = local.tags
  virtual_hubs = {
    (local.virtual_hub1_key) = {
      name           = local.virtual_hub1_name
      location       = local.location
      resource_group = local.resource_group_name
      address_prefix = "10.0.0.0/24"
      tags           = local.tags
    }
    (local.virtual_hub2_key) = {
      name           = local.virtual_hub2_name
      location       = local.location
      resource_group = local.resource_group_name
      address_prefix = "10.1.0.0/24"
      tags           = local.tags
    }    
  }
  firewalls = {
    (local.firewall1_key) = {
      sku_name        = "AZFW_Hub"
      sku_tier        = "Standard"
      name            = local.firewall1_name
      virtual_hub_key = local.virtual_hub1_key
    }
    (local.firewall2_key) = {
      sku_name        = "AZFW_Hub"
      sku_tier        = "Standard"
      name            = local.firewall2_name
      virtual_hub_key = local.virtual_hub2_key
    }    
  }
  routing_intents = {
    "aue-vhub1-routing-intent" = {
      name            = "private1-routing-intent"
      virtual_hub_key = local.virtual_hub1_key
      routing_policies = [{
        name                  = "aue-vhub1-routing-policy-private"
        destinations          = ["PrivateTraffic"]
        next_hop_firewall_key = local.firewall1_key
      }]
    }
    "aue-vhub2-routing-intent" = {
      name            = "private2-routing-intent"
      virtual_hub_key = local.virtual_hub2_key
      routing_policies = [{
        name                  = "aue-vhub2-routing-policy-private"
        destinations          = ["PrivateTraffic"]
        next_hop_firewall_key = local.firewall2_key
      }]
    }    
  }
}