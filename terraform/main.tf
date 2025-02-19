variable "subscription_id" {}
variable "admin_password" {}
variable "resource_group_name" {
  default = "savard-rg"
}
variable "location" {
  default = "eastus"
}
variable "vnet_name" {
  default = "savard-vnet"
}
variable "subnet_name" {
  default = "savard-subnet"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "Production"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Environment = "Production"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "savard-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "winrm_nsg" {
  name                = "winrm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-WinRM"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "savard-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.winrm_nsg.id
}

resource "azurerm_windows_virtual_machine" "savard-server" {
  name                = "savard-server"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = "savardstorage"
  resource_group_name       = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "winrm_script" {
  name                   = "winrm-setup.ps1"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "./terraform/winrm-setup.ps1"
}

resource "azurerm_virtual_machine_extension" "winrm_setup" {
  name                 = "winrm-config"
  virtual_machine_id   = azurerm_windows_virtual_machine.savard-server.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
      "scriptUri": "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/winrm-setup.ps1"
    }
SETTINGS
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}
