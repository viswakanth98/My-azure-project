terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
provider "azurerm" {
  features {}
  # subscription_id  = "b02b827d-461c-4628-b7b1-729f9d193b21"
  # client_id        = "a3eee789-5e98-4cab-a66f-7607932fb9bd"
  # client_secret    = "QUU8Q~sp2MEZ4Nb7nKo9Sfjl4GGq34GgXexvDcSY"
  # tenant_id        = "7e500098-d1ad-4230-adf7-1d8b4522d293"

}

resource "azurerm_resource_group" "ntc-rg" {
  name     = "ntc-resources"
  location = "East Us"
  tags = {
    environment = "dev"
  }
}
resource "azurerm_virtual_network" "ntc-vn" {
  name                = "ntc-network"
  resource_group_name = azurerm_resource_group.ntc-rg.name
  location            = azurerm_resource_group.ntc-rg.location
  address_space       = ["10.123.0.0/16"]
}
resource "azurerm_subnet" "ntc-subnet" {
  name                 = "ntc-subnet"
  resource_group_name  = azurerm_resource_group.ntc-rg.name
  virtual_network_name = azurerm_virtual_network.ntc-vn.name
  address_prefixes     = ["10.123.1.0/24"]

}
resource "azurerm_network_security_group" "ntc-sg" {
  name                = "ntc-sg"
  resource_group_name = azurerm_resource_group.ntc-rg.name
  location            = azurerm_resource_group.ntc-rg.location

  tags = {
    environment = "dev"
  }

}
resource "azurerm_network_security_rule" "ntc-dev-rule" {
  name                        = "ntc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ntc-rg.name
  network_security_group_name = azurerm_network_security_group.ntc-sg.name
}

resource "azurerm_subnet_network_security_group_association" "ntc-sga" {
  subnet_id                 = azurerm_subnet.ntc-subnet.id
  network_security_group_id = azurerm_network_security_group.ntc-sg.id
}
resource "azurerm_public_ip" "ntc-ip" {
  name                = "ntc-ip"
  resource_group_name = azurerm_resource_group.ntc-rg.name
  location            = azurerm_resource_group.ntc-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}


resource "azurerm_network_interface" "ntc-nic" {
  name                = "ntc-nic"
  resource_group_name = azurerm_resource_group.ntc-rg.name
  location            = azurerm_resource_group.ntc-rg.location

  ip_configuration {

    name                          = "internal"
    subnet_id                     = azurerm_subnet.ntc-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ntc-ip.id
  }

  tags = {
    environment = "dev"
  }

}

#Create Storage account
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "viswa123987"
  location                 = azurerm_resource_group.ntc-rg.location
  resource_group_name      = azurerm_resource_group.ntc-rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
# Create virtual machine
resource "azurerm_windows_virtual_machine" "main" {
  name                  = "test1"
  admin_username        = "Azureuser123"
  admin_password        = "Azureuser123"
  location              = azurerm_resource_group.ntc-rg.location
  resource_group_name   = azurerm_resource_group.ntc-rg.name
  network_interface_ids = [azurerm_network_interface.ntc-nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

}
