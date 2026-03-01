#  Hybrid Identity Lab — Azure AD Connect + On-Prem AD

> A hands-on lab simulating a real-world enterprise hybrid identity environment using Azure Active Directory (Entra ID), Azure AD Connect, and a Windows Server Active Directory domain.

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Azure (Cloud)                         │
│                                                          │
│   ┌──────────────┐     ┌──────────────────────────┐     │
│   │  Entra ID    │◄────│   Azure AD Connect Sync  │     │
│   │  (AAD Tenant)│     │   (Password Hash Sync)   │     │
│   └──────┬───────┘     └──────────────────────────┘     │
│          │                          ▲                    │
│   ┌──────▼───────┐                  │                    │
│   │  Azure RBAC  │                  │                    │
│   │  Policies    │       Azure VNet (10.0.0.0/16)       │
│   └──────────────┘       ┌──────────────────────┐       │
│                           │  Domain Controller VM │       │
│                           │  Windows Server 2022  │       │
│                           │  AD DS + DNS + ADCS   │       │
│                           └──────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

##  What This Lab Demonstrates

- Provisioning an on-premises Active Directory domain in Azure (simulated hybrid)
- Installing and configuring **Azure AD Connect** (Entra Connect) with Password Hash Sync
- OU filtering and attribute-level sync scoping
- **Seamless SSO** configuration for domain-joined machines
- **Password writeback** from Entra ID back to on-prem AD
- Hybrid Azure AD Join configuration
- Break-glass account setup and monitoring

## Prerequisites

- Azure subscription (Free tier works for lab)
- Azure CLI installed (`az --version`)
- Terraform >= 1.5.0
- PowerShell 7+ (for DSC scripts)
- Basic understanding of Active Directory and Azure AD

##  Repository Structure

```
hybrid-identity-lab/
├── terraform/
│   ├── main.tf              # Core infrastructure
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── networking.tf        # VNet, subnets, NSG
│   └── dc-vm.tf             # Domain Controller VM
├── scripts/
│   ├── Deploy-ADForest.ps1  # Promotes server to DC, creates AD forest
│   ├── Create-TestUsers.ps1 # Seeds 50 test users across OUs
│   ├── Install-AADConnect.ps1 # Downloads + configures AAD Connect
│   └── Configure-SeamlessSSO.ps1
├── dsc/
│   └── ADConfiguration.ps1  # PowerShell DSC for AD setup
├── policies/
│   └── password-writeback-policy.json
└── docs/
    ├── SETUP.md
    └── TROUBLESHOOTING.md
```

##  Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/YOUR_USERNAME/hybrid-identity-lab
cd hybrid-identity-lab/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy infrastructure

```bash
az login
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Configure Active Directory

```powershell
# RDP into the DC VM, then run:
.\scripts\Deploy-ADForest.ps1 -DomainName "corp.contoso.local" -SafeModePassword "P@ssw0rd123!"
# Server will reboot — reconnect and run:
.\scripts\Create-TestUsers.ps1 -UserCount 50
```

### 4. Install and Configure Azure AD Connect

```powershell
.\scripts\Install-AADConnect.ps1 -TenantId "YOUR_TENANT_ID"
# Follow the GUI wizard or use express settings for lab
```

##  Key Configuration Decisions

| Setting | Value | Why |
|---|---|---|
| Sync Method | Password Hash Sync | Simplest, most resilient option |
| OU Filtering | Corp > Users, Groups only | Exclude service accounts from sync |
| Staging Mode | Enabled initially | Safe testing before going live |
| Seamless SSO | Enabled | No password prompts on domain PCs |
| Password Writeback | Enabled | SSPR works from cloud → on-prem |



##  Cleanup

```bash
terraform destroy
```

##  References

- [Microsoft Entra Connect documentation](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/)
- [Hybrid Identity Design Guide](https://learn.microsoft.com/en-us/azure/active-directory/hybrid/whatis-hybrid-identity)
- [Password Hash Sync deep dive](https://learn.microsoft.com/en-us/azure/active-directory/hybrid/connect/how-to-connect-password-hash-synchronization)
