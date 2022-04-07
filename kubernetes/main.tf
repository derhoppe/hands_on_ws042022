provider "azurerm" {
  features {}
}

provider random {
}

resource "random_integer" "net_id" {
  min = 1000
  max = 9999
}

resource "azurerm_resource_group" "rg_kubernetes" {
  name     = "RG-${var.location_short}-CONTAINER-${random_integer.net_id.result}-${var.environment}"
  location = "${var.location}"
}

resource "azurerm_kubernetes_cluster" "aks_test" {
  name                = "AKS-${var.location_short}-${random_integer.net_id.result}-${var.environment}"
  location            = "${var.location}"
  resource_group_name = azurerm_resource_group.rg_kubernetes.name
  dns_prefix          = "AKS-${var.location_short}-${random_integer.net_id.result}-${var.environment}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}