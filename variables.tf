##############################################################################
# Domain Controller Virtual Machine
##############################################################################

resource "azurerm_windows_virtual_machine" "dc" {
  name                  = "${var.prefix}-dc01"
  resource_group_name   = azurerm_resource_group.lab.name
  location              = azurerm_resource_group.lab.location
  size                  = var.dc_vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.dc.id]

  os_disk {
    name                 = "${var.prefix}-dc01-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

##############################################################################
# VM Extension — Install AD DS + DNS + promote to DC via PowerShell DSC
##############################################################################

resource "azurerm_virtual_machine_extension" "ad_setup" {
  name                 = "ADForestSetup"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = jsonencode({
    commandToExecute = join(" ", [
      "powershell.exe -ExecutionPolicy Unrestricted -Command",
      "\"Install-WindowsFeature -Name AD-Domain-Services,DNS,RSAT-AD-Tools -IncludeManagementTools;",
      "Import-Module ADDSDeployment;",
      "Install-ADDSForest",
      "-DomainName '${var.ad_domain_name}'",
      "-DomainNetbiosName '${var.ad_netbios_name}'",
      "-SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force)",
      "-InstallDns",
      "-Force",
      "-NoRebootOnCompletion:$false\""
    ])
  })

  tags       = var.tags
  depends_on = [azurerm_windows_virtual_machine.dc]
}

##############################################################################
# Key Vault — store DC admin credentials securely
##############################################################################

resource "azurerm_key_vault" "lab" {
  name                      = "${var.prefix}-kv-${random_id.suffix.hex}"
  resource_group_name       = azurerm_resource_group.lab.name
  location                  = azurerm_resource_group.lab.location
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }

  tags = var.tags
}

resource "azurerm_key_vault_secret" "dc_password" {
  name         = "dc-admin-password"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.lab.id
  depends_on   = [azurerm_key_vault.lab]
}

data "azurerm_client_config" "current" {}
