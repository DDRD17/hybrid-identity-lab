##############################################################################
# Virtual Network & Subnet
##############################################################################

resource "azurerm_virtual_network" "lab" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.1.4", "168.63.129.16"] # DC IP + Azure DNS fallback
  tags                = var.tags
}

resource "azurerm_subnet" "identity" {
  name                 = "identity-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

##############################################################################
# Network Security Group — Domain Controller
##############################################################################

resource "azurerm_network_security_group" "dc" {
  name                = "${var.prefix}-dc-nsg"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location

  # RDP — restrict to your IP in production; open for lab only
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_rdp_cidr
    destination_address_prefix = "*"
  }

  # LDAP
  security_rule {
    name                       = "Allow-LDAP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Kerberos
  security_rule {
    name                       = "Allow-Kerberos"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # DNS
  security_rule {
    name                       = "Allow-DNS"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "identity" {
  subnet_id                 = azurerm_subnet.identity.id
  network_security_group_id = azurerm_network_security_group.dc.id
}

##############################################################################
# Public IP + NIC for Domain Controller
##############################################################################

resource "azurerm_public_ip" "dc" {
  name                = "${var.prefix}-dc-pip"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "dc" {
  name                = "${var.prefix}-dc-nic"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.identity.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4" # Fixed DC IP — matches VNet DNS
    public_ip_address_id          = azurerm_public_ip.dc.id
  }

  tags = var.tags
}
