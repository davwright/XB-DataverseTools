# DataverseCmdlets

A professional PowerShell module for managing Microsoft Dataverse environments using REST APIs and the Power Platform CLI. Designed for automation, provisioning, metadata querying, and record operations — with full support for custom tables, fields, and robust error handling.

## ✨ Features

- Create, update, delete, and query Dataverse **records**, **tables**, **columns**, and **global choices**
- Retrieve full **metadata** for tables and fields
- Auto-generate base64-safe **schema names**
- Robust **retry logic** and **throttling** handling for API calls
- Integrates with **Power Platform CLI** (`pac`) for environment listing
- Supports **OAuth 2.0 bearer tokens** or existing `pac auth` context
- Modular, PlatyPS-compatible, pipeline-friendly

## 🛠 Requirements

- PowerShell 5.1 or 7+
- Power Platform CLI (`pac`) for environment listing (optional)
- AAD App Registration (for token-based access) or PAC Auth Session
- Admin or maker privileges in Dataverse

## 📦 Installation

1. Clone or install from your internal feed/repository:

```powershell
git clone https://github.com/kristianbuch/DataverseCmdlets
```

2. Import the module (from the cloned folder):

```powershell
Import-Module .\DataverseCmdlets\DataverseCmdlets.psd1 -Force
```

## 🔧 Functions

```powershell
Connect-Dataverse          # Authenticate and get an access token for Dataverse
Get-PPEnvironments         # List environments using the Power Platform CLI
Get-DVData                 # Retrieve records from any Dataverse table (with pagination & retry)
New-DVRecord               # Create a record in a Dataverse table
Update-DVRecord            # Update a specific record by GUID
New-DVTable                # Provision a custom table (EntityMetadata)
Remove-DVTable             # Delete a custom table and all its data
New-DVColumn               # Add a custom column to an existing table
New-DVChoice               # Create a global choice (option set) with multiple options
New-DVPolymorphicLookup    # Create a polymorphic lookup that can reference multiple table types
Get-DVTableMetadata        # Retrieve metadata (field names, types, requirements, etc.)
```

## 🔐 Authentication

Most functions accept an optional `-AccessToken` parameter. If not provided they rely on an existing authenticated session (for example via `Connect-Dataverse` or `pac auth create`).

Quick examples:

```powershell
# 1) Install dependencies (if needed)
Install-Module -Name Az.Accounts -Scope CurrentUser

# 2) Use the helper to get a bearer token (recommended):
$env = "https://{yourorgname}.crm.dynamics.com"
$token = Connect-Dataverse -EnvironmentUrl $env

# 3) Or use Az.Accounts directly to obtain a token
$secureToken = (Get-AzAccessToken -ResourceUrl $env).Token
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

# 4) Use token with commands (example):
New-DVTable -EnvironmentUrl $env -TableLogicalName "new_oldtable" -AccessToken $token
New-DVRecord -EnvironmentUrl $env -TableName "contacts" -Data @{ firstname = 'Eva'; lastname = 'Holm' } -AccessToken $token

# 5) Use PAC CLI to list environments (if pac is installed and authenticated):
pac auth create --environment $env
Get-PPEnvironments -OutPath ".\envs.json" -OutputFormat JSON

Get-Help New-DVRecord -Full
Get-Help Get-DVTableMetadata
```

If you encounter `SerializationSettings` or `ResourceManagementClient` errors with `Az.Accounts`, update the module and restart PowerShell:

```powershell
Update-Module Az.Accounts -Force
```

## 🧪 Examples

### Basic operations

```powershell
# Get all accounts from a Dataverse environment
Get-DVData -EnvironmentUrl "https://org.crm4.dynamics.com" -TableName "accounts"

# Create a custom table
New-DVTable -EnvironmentUrl $env -TableLogicalName "new_oldtable" -AccessToken $token

# Create a new contact
$new = @{ firstname = "Eva"; lastname = "Holm" }
New-DVRecord -EnvironmentUrl $env -TableName "contacts" -Data $new -AccessToken $token

# Create a global choice (reusable across multiple tables)
New-DVChoice -EnvironmentUrl $env -SchemaName "new_VehicleType" `
    -DisplayName "Vehicle Type" -Choices "car;bike;truck" -Description "Types of vehicles" -AccessToken $token

# Add a Choice field to a custom table
New-DVColumn -EnvironmentUrl $env -TableLogicalName "new_project" -SchemaName "new_Status" `
    -DisplayName "Status" -Type Choice -Choices @("Planned","Active","Completed") -AccessToken $token

# Create a polymorphic lookup that can reference multiple entity types
$targets = @(
    @{LogicalName='account'},
    @{LogicalName='contact'},
    @{LogicalName='lead'}
)
New-DVPolymorphicLookup -EnvironmentUrl $env -ReferencingTable "new_activity" `
    -SchemaName "new_RegardingObjectId" -DisplayName "Regarding" -ReferencedTables $targets -AccessToken $token

# Delete a custom table
Remove-DVTable -EnvironmentUrl $env -TableLogicalName "new_oldtable" -AccessToken $token

# List all Power Platform environments
Get-PPEnvironments -OutPath ".\envs.json" -OutputFormat JSON
```

## 📚 Help

```powershell
Get-Help New-DVRecord -Full
Get-Help Get-DVTableMetadata
```

## 👤 Authors & Maintainers

- Original author / upstream source: **Kristian Holm Buch** — [GitHub](https://github.com/kristianbuch) — [LinkedIn](https://linkedin.com/in/kristianbuch)
© 2025 Kristian Holm Buch — Licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0)
- Current maintainer and active development: **EvolX** (this repository)

Maintained and developed by EvolX.
