provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "builder_rg" {
  name     = "builder-resources"
  location = var.location
}

resource "azurerm_virtual_network" "builder_vnet" {
  name                = "builder-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.builder_rg.location
  resource_group_name = azurerm_resource_group.builder_rg.name
}

resource "azurerm_subnet" "builder_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.builder_rg.name
  virtual_network_name = azurerm_virtual_network.builder_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "builder_nsg" {
  name                = "builder-nsg"
  location            = azurerm_resource_group.builder_rg.location
  resource_group_name = azurerm_resource_group.builder_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "builder_public_ip" {
  name                = "builder-public-ip"
  location            = azurerm_resource_group.builder_rg.location
  resource_group_name = azurerm_resource_group.builder_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "builder_nic" {
  name                = "builder-nic"
  location            = azurerm_resource_group.builder_rg.location
  resource_group_name = azurerm_resource_group.builder_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.builder_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.builder_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "builder_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.builder_nic.id
  network_security_group_id = azurerm_network_security_group.builder_nsg.id
}

# Generate SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "builder_vm" {
  name                = "builder"
  resource_group_name = azurerm_resource_group.builder_rg.name
  location            = azurerm_resource_group.builder_rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.builder_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # Install Docker and Docker Compose
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo usermod -aG docker ${var.admin_username}",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]

    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = azurerm_public_ip.builder_public_ip.ip_address
    }
  }
}

# Output the SSH private key
output "ssh_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

# Output the public IP address
output "public_ip_address" {
  value = azurerm_public_ip.builder_public_ip.ip_address
} 