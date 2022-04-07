terraform {

  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider random {
}

resource "random_integer" "net_id" {
  min = 1000
  max = 9999
}

resource "azurerm_resource_group" "network_group" {
    name     = "RG-${var.location_short}-NETWORK-${random_integer.net_id.result}-${var.environment}"
    location = "${var.location}"

    tags = {
        ENV = "${var.environment}"
    }
}

resource "azurerm_resource_group" "vmss_group" {
    name     = "RG-${var.location_short}-COMPUTE-AGENT-${random_integer.net_id.result}-${var.environment}"
    location = "${var.location}"

    tags = {
        ENV = "${var.environment}"
    }
}

resource "azurerm_virtual_network" "network_hub" {
    name                = "VNET-${var.location_short}-HUB-${random_integer.net_id.result}-${var.environment}"
    address_space       = ["10.100.0.0/24"]
    location            = "${var.location}"
    resource_group_name = azurerm_resource_group.network_group.name

    tags = {
        ENV = "${var.environment}"
    }
}
resource "azurerm_subnet" "subnet_hub" {
    name                 = "SN-${var.location_short}-INT-${random_integer.net_id.result}-${var.environment}"
    resource_group_name  = azurerm_resource_group.network_group.name
    virtual_network_name = azurerm_virtual_network.network_resource.name
    address_prefixes       = ["10.100.0.0/27"]
}

resource "azurerm_virtual_network" "network_resource" {
    name                = "VNET-${var.location_short}-SPOKE-${random_integer.net_id.result}-${var.environment}"
    address_space       = ["10.101.0.0/24"]
    location            = "${var.location}"
    resource_group_name = azurerm_resource_group.network_group.name

    tags = {
        ENV = "${var.environment}"
    }
}
resource "azurerm_subnet" "subnet_resource" {
    name                 = "SN-${var.location_short}-INT-${random_integer.net_id.result}-${var.environment}"
    resource_group_name  = azurerm_resource_group.network_group.name
    virtual_network_name = azurerm_virtual_network.network_resource.name
    address_prefixes       = ["10.101.0.0/27"]
}

resource "azurerm_virtual_network_peering" "net_peering_1" {
  name                      = "${azurerm_virtual_network.network_hub.name}-${azurerm_virtual_network.network_resource.name}" 
  resource_group_name       = azurerm_resource_group.network_group.name
  virtual_network_name      = azurerm_virtual_network.network_hub.name
  remote_virtual_network_id = azurerm_virtual_network.network_resource.id
}

resource "azurerm_virtual_network_peering" "net_peering_2" {
  name                      = "${azurerm_virtual_network.network_resource.name}-${azurerm_virtual_network.network_hub.name}" 
  resource_group_name       = azurerm_resource_group.network_group.name
  virtual_network_name      = azurerm_virtual_network.network_resource.name
  remote_virtual_network_id = azurerm_virtual_network.network_hub.id
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
 name                = "vmscaleset"
 location            = "${var.location}"
 resource_group_name = azurerm_resource_group.vmss_group.name
 upgrade_policy_mode = "Manual"

 sku {
   name     = "Standard_D4s_v3"
   tier     = "Standard"
   capacity = 0
 }

 storage_profile_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_profile_os_disk {
   name              = ""
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 storage_profile_data_disk {
   lun          = 0
   caching        = "ReadWrite"
   create_option  = "Empty"
   disk_size_gb   = 10
 }

 os_profile {
   computer_name_prefix = "vmlab"
   admin_username       = "vmssadmin"
   admin_password       = "Pa55w.rd12345"
   custom_data          = file("web.conf")
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 network_profile {
   name    = "terraformnetworkprofile"
   primary = true

   ip_configuration {
     name                                   = "IPConfiguration"
     subnet_id                              = azurerm_subnet.subnet_resource.id
     primary = true
   }
 }

 tags = {
    ENV = "${var.environment}"
 }
}

output "rnd_net_id" {
  value = random_integer.net_id.result
}