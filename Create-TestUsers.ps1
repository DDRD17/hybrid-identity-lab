output "dc_public_ip" {
  description = "Public IP of the Domain Controller VM — use for RDP"
  value       = azurerm_public_ip.dc.ip_address
}

output "dc_private_ip" {
  description = "Private IP of the DC (10.0.1.4 — set as VNet DNS)"
  value       = azurerm_network_interface.dc.private_ip_address
}

output "resource_group_name" {
  description = "Name of the lab resource group"
  value       = azurerm_resource_group.lab.name
}

output "key_vault_name" {
  description = "Key Vault storing lab credentials"
  value       = azurerm_key_vault.lab.name
}

output "rdp_command" {
  description = "Quick command to open RDP to the DC"
  value       = "mstsc /v:${azurerm_public_ip.dc.ip_address}"
}
