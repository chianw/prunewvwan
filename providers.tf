terraform {
  required_version = "~> 1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }


  ## below block defines the backend that contains tfstate for this deployment
  backend "azurerm" {
    subscription_id      = "02bf2d88-20f2-4415-82c6-211960fd55f9" //management subscription containing storage account
    resource_group_name  = "prutfrg"
    storage_account_name = "prutfsa123"
    container_name       = "tfstate"
    key                  = "vwan.tfstate"
  }

}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  use_oidc = true
  # subscription_id = "68be2809-9674-447c-a43d-261ef2862c29"

}