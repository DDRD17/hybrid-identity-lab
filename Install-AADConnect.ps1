variable "prefix" {
  type        = string
  default     = "hyblab"
  description = "Short prefix for all resource names (keep under 8 chars)"
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region for lab resources"
}

variable "dc_vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size for the Domain Controller (2 vCPU, 8 GB RAM minimum for AD DS)"
}

variable "admin_username" {
  type        = string
  default     = "labadmin"
  description = "Local administrator username for the DC VM"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Local administrator password — store in Key Vault, never commit to git"
}

variable "ad_domain_name" {
  type        = string
  default     = "corp.contoso.local"
  description = "FQDN for the on-prem AD forest root domain"
}

variable "ad_netbios_name" {
  type        = string
  default     = "CORP"
  description = "NetBIOS name for the domain (15 chars max, all caps)"
}

variable "allowed_rdp_cidr" {
  type        = string
  default     = "*"
  description = "CIDR that can RDP to the DC. Lock this down in a real environment!"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Lab"
    Project     = "HybridIdentity"
    ManagedBy   = "Terraform"
  }
}
