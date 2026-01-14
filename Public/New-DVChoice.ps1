# Heritage: formerly XB-DataverseTools (NexaBlue)
function New-DVChoice {
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
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }
    if ($SolutionUniqueName) { $headers["MSCRM.SolutionUniqueName"] = $SolutionUniqueName }

    $url = "$EnvironmentUrl/api/data/v9.2/GlobalOptionSetDefinitions"

    try {
        Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ErrorAction Stop
        $successMessage = "Dataverse global choice '$DisplayName' created (SchemaName: $SchemaName)"
        if ($SolutionUniqueName) { $successMessage += " in solution '$SolutionUniqueName'" }
        Write-Host "$successMessage." -ForegroundColor Green
    }
    catch {
        $errorDetails = $_.ErrorDetails.Message
        if ($errorDetails) { Write-Host "Error Details: $errorDetails" -ForegroundColor Red }
        Throw "Could not create choice '$SchemaName'. Error: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function New-DVChoice

# Example: Create a new global choice for vehicle types
# New-DVChoice -EnvironmentUrl $envUrl -SchemaName "new_VehicleType" `
#    -DisplayName "Vehicle Type" -Choices "car;bike;truck" `
#    -Description "Types of vehicles in the fleet"
