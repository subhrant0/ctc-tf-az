terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ctcrg02" {
  name     = "ctc-rg-02"
  location = "East US"

  tags = {
    environment = "CTC Demo"
  }
}

resource "azurerm_kubernetes_cluster" "ctc_k8s" {
  name                = "ctck8s"
  location            = "East US"
  resource_group_name = azurerm_resource_group.ctcrg02.name
  dns_prefix          = "ctc-k8s"

  linux_profile {
        admin_username = "ctcadmin"

        ssh_key {
            key_data = file("~/.ssh/id_rsa.pub")
        }
    }
  
  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_B2ms"
  }

identity {
    type = "SystemAssigned"
  }
  
  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "kubenet"
  }

  tags = {
    environment = "CTC Demo"
  }
}