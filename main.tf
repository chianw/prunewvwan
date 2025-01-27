locals {
  firewall1_key       = "sea-vhub1-fw"
  firewall1_name      = "fw1-pru-vwan"
  firewall2_key       = "ea-vhub2-fw"
  firewall2_name      = "fw2-pru-vwan"
  location1           = "southeastasia"
  location2           = "eastasia"
  resource_group_name = "rg-pru-vwan"
  tags = {
    environment = "avm-vwan-testing"
    deployment  = "terraform"
  }
  virtual_hub1_key  = "sea-vhub1"
  virtual_hub1_name = "vhub1-pru-sea"
  virtual_hub2_key  = "ea-vhub2"
  virtual_hub2_name = "vhub2-pru-ea"
  virtual_wan_name  = "vwan-pru-sea"
}



/*
resource "azurerm_resource_group" "example" {
  name     = local.resource_group_name
  location = local.location1
}

module "firewall_policy" {
  source              = "Azure/avm-res-network-firewallpolicy/azurerm"
  version             = "0.3.2"
  name                = "prufwpolicy"
  location            = local.location1
  resource_group_name = azurerm_resource_group.example.name
  depends_on          = [module.vwan_with_vhub]
}

module "rule_collection_group" {
  source                                                   = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version                                                  = "0.3.2"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource.id
  firewall_policy_rule_collection_group_name               = "NetworkRuleCollectionGroup"
  firewall_policy_rule_collection_group_priority           = 400
  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      action   = "Allow"
      name     = "NetworkRuleCollection"
      priority = 200
      rule = [
        {
          name                  = "allowall"
          description           = "AllowAll"
          destination_addresses = ["0.0.0.0/0"]
          destination_ports     = ["*"]
          source_addresses      = ["0.0.0.0/0"]
          protocols             = ["Any"]
        }
      ]
    }
  ]
}
*/

resource "azurerm_firewall_policy" "this" {
  location            = local.location1
  name                = "prufwpolicy"
  resource_group_name = module.vwan_with_vhub.resource_group_name
}


resource "azurerm_firewall_policy_rule_collection_group" "example" {
  name               = "pru-fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 500

  network_rule_collection {
    name     = "network_rule_collection1"
    priority = 400
    action   = "Allow"
    rule {
      name                  = "network_rule_collection1_rule1"
      protocols             = ["Any"]
      source_addresses      = ["0.0.0.0/0"]
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["*"]
    }
  }


}


module "vwan_with_vhub" {
  source                         = "git::https://github.com/Azure/terraform-azurerm-avm-ptn-virtualwan?ref=v0.8.0"
  create_resource_group          = true
  resource_group_name            = local.resource_group_name
  location                       = local.location1
  virtual_wan_name               = local.virtual_wan_name
  disable_vpn_encryption         = false
  allow_branch_to_branch_traffic = true
  type                           = "Standard"
  virtual_wan_tags               = local.tags
  virtual_hubs = {
    (local.virtual_hub1_key) = {
      name           = local.virtual_hub1_name
      location       = local.location1
      resource_group = local.resource_group_name
      address_prefix = "10.0.0.0/24"
      tags           = local.tags
    }
    (local.virtual_hub2_key) = {
      name           = local.virtual_hub2_name
      location       = local.location2
      resource_group = local.resource_group_name
      address_prefix = "10.1.0.0/24"
      tags           = local.tags
    }
  }
  firewalls = {
    (local.firewall1_key) = {
      sku_name           = "AZFW_Hub"
      sku_tier           = "Standard"
      name               = local.firewall1_name
      virtual_hub_key    = local.virtual_hub1_key
      firewall_policy_id = azurerm_firewall_policy.this.id
    }
    (local.firewall2_key) = {
      sku_name           = "AZFW_Hub"
      sku_tier           = "Standard"
      name               = local.firewall2_name
      virtual_hub_key    = local.virtual_hub2_key
      firewall_policy_id = azurerm_firewall_policy.this.id
    }
  }
  routing_intents = {
    "aue-vhub1-routing-intent" = {
      name            = "private1-routing-intent"
      virtual_hub_key = local.virtual_hub1_key
      routing_policies = [{
        name                  = "aue-vhub1-routing-policy-private"
        destinations          = ["PrivateTraffic", "Internet"]
        next_hop_firewall_key = local.firewall1_key
      }]
    }
    "aue-vhub2-routing-intent" = {
      name            = "private2-routing-intent"
      virtual_hub_key = local.virtual_hub2_key
      routing_policies = [{
        name                  = "aue-vhub2-routing-policy-private"
        destinations          = ["PrivateTraffic", "Internet"]
        next_hop_firewall_key = local.firewall2_key
      }]
    }
  }
}