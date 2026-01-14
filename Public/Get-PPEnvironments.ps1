# Heritage: formerly XB-DataverseTools (NexaBlue)
function Get-PPEnvironments {
    [CmdletBinding()]
    param(
        [string]$OutPath,
        [ValidateSet("JSON","CSV")]
        [string]$OutputFormat = "JSON"
    )
    <#
    Retrieves a list of Power Platform environments via the Power Platform CLI (pac).
    #>
    try { $envJson = pac env list --json 2>$null }
    catch { Throw "PAC CLI call failed. Ensure Power Platform CLI is installed and you are logged in (pac auth create)." }
    if (-not $envJson) { Write-Warning "No environment data received."; return @() }
    $environments = $envJson | ConvertFrom-Json
    if ($OutPath) {
        if ($OutputFormat -eq "CSV") { $environments | Export-Csv -Path $OutPath -NoTypeInformation; Write-Verbose "Environment list saved as CSV: $OutPath" }
        else { $environments | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutPath -Encoding UTF8; Write-Verbose "Environment list saved as JSON: $OutPath" }
    }
    return $environments
}
Export-ModuleMember -Function Get-PPEnvironments

# Example: Retrieve environments and save result to 'environments.json'
# $environments = Get-PPEnvironments -OutPath ".\environments.json" -OutputFormat JSON
# $environments | Format-Table displayName, environmentUrl, environmentId
