resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "main" {
  name                = local.virtual_network
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "bastionsubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.224/27"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = local.public_ip
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku     = "Standard"
}

resource "azurerm_bastion_host" "main" {
  name                   = local.bastion_name
  location               = azurerm_resource_group.resource_group.location
  resource_group_name    = azurerm_resource_group.resource_group.name
  copy_paste_enabled     = true
  file_copy_enabled      = false
  sku                    = "Standard"
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionsubnet.id
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface" "main" {
  name                = local.virtual_network_nic
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "bastion-nsg" {
  name = local.network_security_group
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  security_rule {
    name                       = "Allow_TCP_443_Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_TCP_443_GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_TCP_4443_GatewayManager"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 4443
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_TCP_443_AzureLoadBalancer"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Deny_any_other_traffic"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_TCP_3389_VirtualNetwork"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "Allow_TCP_22_VirtualNetwork"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "Allow_TCP_443_AzureCloud"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = local.virtual_machine_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_F2"
  admin_username      = local.vm_user
  admin_password      = local.vm_user_password
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_key_vault" "key_vault" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.resource_group.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

}

resource "azurerm_key_vault_access_policy" "key_vault_access_policy_sp" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
}

resource "azurerm_key_vault_secret" "key_vault_secret_vmpassword" {
  name         = "vmpassword"
  value        = local.vm_user_password
  key_vault_id = azurerm_key_vault.key_vault.id

  # prevents race condition when the secret is getting created before the access policy, causing 401
  depends_on = [
    azurerm_key_vault_access_policy.key_vault_access_policy_sp
  ]
}