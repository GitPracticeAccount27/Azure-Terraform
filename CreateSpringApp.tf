terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.106.1"
    }
  }
}
# Authenticating Azure provider with tenant deatils
provider "azurerm" {
  subscription_id = ""
  tenant_id = ""
  client_id = ""
  client_secret = ""
  features {}
}


locals {
  RG= "practiceRG"
  location= "East US"
  virtual_network={
    name= "VmVnet"
    address_space= "10.171.0.0/16"
  }
  subnets=[
    {
      name= "VmSubnet"
      address_prefixes="10.171.0.0/24"
    },
    {
      name= "VmSubnetB"
      address_prefixes="10.171.1.0/24"
    }
   ]
}






resource "azurerm_resource_group" "practiceRG" {
  name     = local.RG
  location = local.location
}

resource "azurerm_virtual_network" "VmVnet" {
  name                = local.virtual_network.name
  address_space       = [local.virtual_network.address_space]
  location            = local.location
  resource_group_name = local.RG
  depends_on = [ 
    azurerm_resource_group.practiceRG
   ]
}

# Creating two subnet using count based on variables
resource "azurerm_subnet" "VmSubnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = local.RG
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[0].address_prefixes]
  depends_on = [ 
    azurerm_virtual_network.VmVnet ]
}

resource "azurerm_subnet" "VmSubnetB" {
  name                 = local.subnets[1].name
  resource_group_name  = local.RG
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[1].address_prefixes]
  depends_on = [ 
    azurerm_virtual_network.VmVnet ]
}


resource "azurerm_application_insights" "app-insights" {
  name                = "test-appinsights"
  location            = local.location
  resource_group_name = local.RG
  application_type    = "java"
  depends_on = [  
    azurerm_resource_group.practiceRG
   ]
}

resource "azurerm_spring_cloud_service" "test-spapp" {
  name                = "test-spapp"
  resource_group_name = local.RG
  location            = local.location
  sku_name            = "S0"

  network {
    
    app_subnet_id = azurerm_subnet.VmSubnetA.id
    service_runtime_subnet_id = azurerm_subnet.VmSubnetB.id
    cidr_ranges = ["10.0.0.0/16","10.1.0.0/16","10.2.0.1/16"]
  }

  trace {
    connection_string = azurerm_application_insights.app-insights.connection_string
    sample_rate       = 10.0
  }
  depends_on = [  
    azurerm_resource_group.practiceRG,
    azurerm_virtual_network.VmVnet,
    azurerm_subnet.VmSubnetA,
    azurerm_subnet.VmSubnetB,
    azurerm_application_insights.app-insights,

   ]

}


