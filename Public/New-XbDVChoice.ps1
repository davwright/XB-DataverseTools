function New-XbDVChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com\/?$')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,
    
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Logical schema name for the choice, including prefix (e.g., 'new_VehicleType')")]
        [ValidatePattern('^[a-zA-Z0-9_]+_[a-zA-Z0-9_]+$')]
        [ValidateNotNullOrEmpty()]
        [string]$SchemaName,

        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Display name of the choice (e.g., 'Vehicle Type')")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(Mandatory = $true, Position = 3, HelpMessage = "Semicolon-separated list of choice options (e.g., 'Option1;Option2;Option3')")]
        [ValidateNotNullOrEmpty()]
        [string]$Choices,

        [Parameter(HelpMessage = "Optional description of the choice shown in UI and metadata.")]
        [string]$Description = "",
    
        [Parameter(HelpMessage = "Unique name of the solution to add this choice to (e.g., 'MyCustomSolution'). If not specified, choice is added to the default solution.")]
        [string]$SolutionUniqueName,

        [Parameter(HelpMessage = "OAuth 2.0 bearer token. Optional if session is pre-authenticated.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
    )
    
<#
.SYNOPSIS
    Creates a new global choice (option set) in Microsoft Dataverse.

.DESCRIPTION
    Provisions a new global choice (option set) in a Dataverse environment using the Web API.
    A global choice is a reusable picklist that can be used across multiple tables and columns.
    Options are automatically assigned incrementing values starting from 1.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment, e.g., "https://org.crm4.dynamics.com".

.PARAMETER SchemaName
    Logical name (SchemaName) of the choice to create, including prefix (e.g., "new_VehicleType").

.PARAMETER DisplayName
    Display name of the choice, shown in model-driven apps and solutions.

.PARAMETER Choices
    Semicolon-separated list of choice options (e.g., "car;bike;truck").
    Values will be automatically assigned starting from 1 and incrementing.

.PARAMETER SolutionUniqueName
    Optional. Unique name of the solution to add this choice to during creation.
    If not specified, the choice is added to the default solution (Common Data Services Default Solution).
    The solution must already exist in the environment.
    Example: "MyCustomSolution", "CoreComponents"

.PARAMETER AccessToken
    Optional. OAuth 2.0 bearer token for authorization. If not specified, assumes existing auth context.

.EXAMPLE
    New-XbDVChoice -EnvironmentUrl "https://org.crm4.dynamics.com" -SchemaName "new_VehicleType" `
        -DisplayName "Vehicle Type" -Choices "car;bike;truck" `
        -Description "Types of vehicles"

    Creates a global choice with three options: car (1), bike (2), truck (3).

.EXAMPLE
    New-XbDVChoice -EnvironmentUrl $envUrl -SchemaName "new_Priority" `
        -DisplayName "Priority Level" -Choices "Low;Medium;High;Critical"

    Creates a priority choice with four options with values 1-4.

.EXAMPLE
    New-XbDVChoice -EnvironmentUrl $envUrl -SchemaName "custom_Status" `
        -DisplayName "Project Status" -Choices "Not Started;In Progress;On Hold;Completed;Cancelled" `
        -SolutionUniqueName "ProjectManagement"

    Creates a status choice and adds it to the "ProjectManagement" solution during creation.

.OUTPUTS
    None. Writes confirmation to host or throws error on failure.

.NOTES
    Author      : Kristian Holm Buch
    Version     : 1.0
    Date        : 2025-05-04
    Editor      : PowerShell Studio 2025
    License     : CC BY-NC-ND 4.0
    Copyright   : (c) 2025 - Kristian Holm Buch. All Rights Reserved.

    GLOBAL CHOICE (OPTION SET):
    A global choice is a reusable picklist that can be shared across multiple tables and columns.
    Once created, you can reference it when creating choice columns on any table.

    OPTION VALUES:
    Option values are automatically assigned starting from 1 and incrementing for each option.
    For example, "car;bike;truck" becomes: car=1, bike=2, truck=3.

    SOLUTION ASSIGNMENT:
    Choices can be added to a specific solution during creation using the -SolutionUniqueName parameter.
    If not specified, the choice is added to the "Default Solution" (Common Data Services Default Solution).
    The solution must already exist before creating the choice.
    You can also add choices to solutions after creation using the Dataverse UI or APIs.

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-update-optionsets
#>

    # Parse semicolon-separated choices and build Options array
    $choiceLabels = $Choices -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    $optionsArray = @()
    $value = 1
    foreach ($label in $choiceLabels) {
        $optionsArray += @{
            "Value" = $value
            "Label" = @{
                "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                "LocalizedLabels" = @(@{
                    "Label"        = $label
                    "LanguageCode" = 1033
                })
            }
        }
        $value++
    }

    # Build JSON body for the new global choice (OptionSetMetadata)
    $entity = [ordered]@{
        "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
        "Options"     = $optionsArray
        "Name"        = $SchemaName
        "DisplayName" = @{
            "@odata.type"     = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                "Label"       = $DisplayName
                "LanguageCode" = 1033
            })
        }
        "Description"  = @{
            "@odata.type"     = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                "Label"       = $Description
                "LanguageCode" = 1033
            })
        }
        "OptionSetType" = "Picklist"
        "IsGlobal"      = $true
    }

    $jsonBody = $entity | ConvertTo-Json -Depth 15
    $headers = @{
        Accept = 'application/json; charset=utf-8'
        "Content-Type" = 'application/json; charset=utf-8'
    }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }
    # Add choice to specific solution if specified
    if ($SolutionUniqueName) {
        $headers["MSCRM.SolutionUniqueName"] = $SolutionUniqueName
    }

    $url = "$EnvironmentUrl/api/data/v9.2/GlobalOptionSetDefinitions"

    # Write request to .rest file for debugging with REST Client Extension
    $restFilePath = Join-Path $PWD "$SchemaName.rest"
    $restContent = @()
    $restContent += "POST $url"
    foreach ($headerKey in $headers.Keys) {
        $restContent += "${headerKey}: $($headers[$headerKey])"
    }
    $restContent += ""
    $restContent += $jsonBody
    $restContent -join "`n" | Out-File -FilePath $restFilePath -Encoding UTF8
    Write-Host "REST request saved to: $restFilePath" -ForegroundColor Gray

    try {
        Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ErrorAction Stop
        $successMessage = "Dataverse global choice '$DisplayName' created (SchemaName: $SchemaName)"
        if ($SolutionUniqueName) {
            $successMessage += " in solution '$SolutionUniqueName'"
        }
        Write-Host "$successMessage."
    }
    catch {
        $errorDetails = $_.ErrorDetails.Message
        if ($errorDetails) {
            Write-Host "Error Details: $errorDetails" -ForegroundColor Red
        }
        Throw "Could not create choice '$SchemaName'. Error: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function New-XbDVChoice

# Example: Create a new global choice for vehicle types
# New-XbDVChoice -EnvironmentUrl $envUrl -SchemaName "new_VehicleType" `
#    -DisplayName "Vehicle Type" -Choices "car;bike;truck" `
#    -Description "Types of vehicles in the fleet"
