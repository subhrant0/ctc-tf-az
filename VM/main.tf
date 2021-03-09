provider "azurerm" {
    version = "~>2.0"
    features {}
}

resource "azurerm_resource_group" "ctcrg01" {
    name     = "ctc-rg-01"
    location = "eastus"

    tags = {
        environment = "CTC Demo"
    }
}

resource "azurerm_virtual_network" "ctcvnet01" {
    name                = "ctc-vnet-01"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.ctcrg01.name

    tags = {
        environment = "CTC Demo"
    }
}

resource "azurerm_subnet" "ctcvnet01snet01" {
    name                 = "ctc-vnet-01-snet-01"
    resource_group_name  = azurerm_resource_group.ctcrg01.name
    virtual_network_name = azurerm_virtual_network.ctcvnet01.name
    address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ctcpip01" {
    name                         = "ctc-pip-01"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.ctcrg01.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "CTC Demo"
    }
}

resource "azurerm_network_security_group" "ctcnsg01" {
    name                = "ctc-nsg-01"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.ctcrg01.name

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "CTC Demo"
    }
}

resource "azurerm_network_interface" "ctcvnet01snet01nic01" {
    name                      = "ctc-vnet-01-snet-01-nic-01"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.ctcrg01.name

    ip_configuration {
        name                          = "ctc-vnet-01-snet-01-nic-01Configuration"
        subnet_id                     = azurerm_subnet.ctcvnet01snet01.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.ctcpip01.id
    }

    tags = {
        environment = "CTC Demo"
    }
}

resource "azurerm_network_interface_security_group_association" "nsg01xnic01" {
    network_interface_id      = azurerm_network_interface.ctcvnet01snet01nic01.id
    network_security_group_id = azurerm_network_security_group.ctcnsg01.id
}

resource "azurerm_storage_account" "ctcstgact01" {
    name                        = "ctcstorageact01"
    resource_group_name         = azurerm_resource_group.ctcrg01.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "CTC Demo"
    }
}

resource "tls_private_key" "vm01-ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { value = tls_private_key.vm01-ssh.private_key_pem }

resource "azurerm_linux_virtual_machine" "ctcvm01" {
    name                  = "ctc-vm-01"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.ctcrg01.name
    network_interface_ids = [azurerm_network_interface.ctcvnet01snet01nic01.id]
    size                  = "Standard_B2s"

    os_disk {
        name              = "ctc-vm-01-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "ctc-vm-01"
    admin_username = "ctcadmin"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "ctcadmin"
        public_key     = tls_private_key.vm01-ssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.ctcstgact01.primary_blob_endpoint
    }

    tags = {
        environment = "CTC Demo"
    }
}