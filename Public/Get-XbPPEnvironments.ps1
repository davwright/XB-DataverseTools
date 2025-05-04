function Get-PPEnvironments {
    [CmdletBinding()]
    param(
        [string]$OutPath,               # Path to output file (optional)
        [ValidateSet("JSON","CSV")] 
        [string]$OutputFormat = "JSON"  # Format: JSON (default) or CSV
    )
<#
.SYNOPSIS
    Retrieves a list of Power Platform environments via the Power Platform CLI.

.DESCRIPTION
    Uses the Power Platform CLI (PAC) to fetch a list of environments accessible by the current user.
    Supports optional export to file in either JSON or CSV format. Requires PAC CLI to be installed and
    an active authenticated session (`pac auth create`).

.PARAMETER OutPath
    Optional. If specified, the retrieved environments will be saved to the given file path.

.PARAMETER OutputFormat
    Optional. Specifies the export format if OutPath is set. Options: JSON (default), CSV.

.EXAMPLE
    Get-PPEnvironments

    Retrieves the list of environments and returns them as PowerShell objects.

.EXAMPLE
    Get-PPEnvironments -OutPath ".\envs.json"

    Retrieves environments and saves the output to a JSON file.

.EXAMPLE
    Get-PPEnvironments -OutPath ".\envs.csv" -OutputFormat CSV

    Retrieves environments and saves the output to a CSV file.

.INPUTS
    None

.OUTPUTS
    System.Object[]
    A list of environment objects with details such as environment name, URL, ID, etc.

.NOTES
    Author      : Kristian Holm Buch
    Version     : 1.0
    Date        : 2025-05-04
    Editor      : PowerShell Studio 2025
    License     : CC BY-NC-ND 4.0
    Copyright   : (c) 2025 - Kristian Holm Buch. All Rights Reserved.

.LINK
    https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction
#>

    # Requires PAC CLI to be installed and the user to be logged in (pac auth).
    try {
        # Retrieve environment list as JSON via PAC CLI
        $envJson = pac env list --json 2>$null
    }
    catch {
        Throw "PAC CLI call failed. Ensure Power Platform CLI is installed and you are logged in (pac auth create)."
    }
    if (-not $envJson) {
        Write-Warning "No environment data received. Do you have access to any Power Platform environments?"
        return @()
    }
    # Convert JSON text to PowerShell objects
    $environments = $envJson | ConvertFrom-Json

    # Save to file if requested
    if ($OutPath) {
        if ($OutputFormat -eq "CSV") {
            $environments | Export-Csv -Path $OutPath -NoTypeInformation
            Write-Verbose "Environment list saved as CSV: $OutPath"
        }
        else {
            $environments | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutPath -Encoding UTF8
            Write-Verbose "Environment list saved as JSON: $OutPath"
        }
    }
    return $environments
}

# Example: Retrieve environments and save result to 'environments.json'
# $environments = Get-PPEnvironments -OutPath ".\environments.json" -OutputFormat JSON
# $environments | Format-Table displayName, environmentUrl, environmentId
