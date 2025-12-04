# XB-DataverseTools

A professional PowerShell module for managing Microsoft Dataverse environments using REST APIs and the Power Platform CLI. Designed for automation, provisioning, metadata querying, and record operations — with full support for custom tables, fields, and robust error handling.

## ✨ Features

- Create, update, delete, and query Dataverse **records**, **tables**, and **columns**
- Retrieve full **metadata** for tables and fields
- Auto-generate base64-safe **schema names**
- Robust **retry logic** and **throttling** handling for API calls
- Integrates with **Power Platform CLI** (`pac`) for environment listing
- Supports **OAuth 2.0 bearer tokens** or existing `pac auth` context
- Modular, PlatyPS-compatible, pipeline-friendly

## 🛠 Requirements

- PowerShell 5.1 or 7+
- Power Platform CLI (`pac`) for environment listing
- AAD App Registration (for token-based access) or PAC Auth Session
- Admin or maker privileges in Dataverse

## 📦 Installation

```powershell
# 1. Clone or install from your internal feed/repository
git clone https://github.com/kristianbuch/XB-DataverseTools

# 2. Import the module
Import-Module .\XB-DataverseTools\XB-DataverseTools.psd1 -Force
```

## 🔧 Functions

```powershell
Get-XbPPEnvironments         # List environments using the Power Platform CLI
Get-XbDVData                 # Retrieve records from any Dataverse table (with pagination & retry)
New-XbDVRecord               # Create a record in a Dataverse table
Update-XbDVRecord            # Update a specific record by GUID
New-XbDVTable                # Provision a custom table (EntityMetadata)
Remove-XbDVTable             # Delete a custom table and all its data
New-XbDVColumn               # Add a custom column to an existing table
Get-XbDVTableMetadata        # Retrieve metadata (field names, types, requirements, etc.)
```

## 🧪 Examples

```powershell
# Get all accounts from a Dataverse environment
Get-XbDVData -EnvironmentUrl "https://org.crm4.dynamics.com" -TableName "accounts"

# Create a new contact
$new = @{ firstname = "Eva"; lastname = "Holm" }
New-XbDVRecord -EnvironmentUrl $envUrl -TableName "contacts" -Data $new

# Add a Choice field to a custom table
New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "new_project" -SchemaName "new_Status" `
    -DisplayName "Status" -Type Choice -Choices @("Planned","Active","Completed")

# List all Power Platform environments
Get-XbPPEnvironments -OutPath ".\envs.json" -OutputFormat JSON
```

## 📚 Help

```powershell
Get-Help New-XbDVRecord -Full
Get-Help Get-XbDVTableMetadata
```

## 👤 Author

**Kristian Holm Buch**  
[GitHub](https://github.com/kristianbuch)  
[LinkedIn](https://linkedin.com/in/kristianbuch)

© 2025 NexaBlue — Licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0)
