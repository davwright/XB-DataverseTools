# Heritage: formerly XB-DataverseTools (NexaBlue)
function Remove-DVTable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com$')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Logical name of the table to delete (e.g., 'new_customtable')")]
        [ValidateNotNullOrEmpty()]
        [string]$TableLogicalName,

        [Parameter(HelpMessage = "OAuth 2.0 bearer token. If not specified, assumes session is already authenticated.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken,

        [Parameter(HelpMessage = "Skip confirmation prompt.")]
        [switch]$Force
    )

    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }

    $getUrl = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions(LogicalName='$TableLogicalName')?`$select=MetadataId,SchemaName,LogicalName"
    try {
        $tableMetadata = Invoke-RestMethod -Method GET -Uri $getUrl -Headers $headers -ErrorAction Stop
        $metadataId = $tableMetadata.MetadataId
        $schemaName = $tableMetadata.SchemaName
        if ($Force -or $PSCmdlet.ShouldProcess("Table '$schemaName' ($TableLogicalName)", "Delete table and all its data")) {
            $deleteUrl = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions($metadataId)"
            Write-Host "Deleting table '$schemaName'..." -NoNewline
            Invoke-RestMethod -Method DELETE -Uri $deleteUrl -Headers $headers -ErrorAction Stop | Out-Null
            Write-Host " Done." -ForegroundColor Green
            return "Table '$schemaName' ($TableLogicalName) deleted successfully."
        }
        else { return "Table deletion cancelled." }
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDesc = $_.Exception.Response.StatusDescription
            try { $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream()); $responseContent = $reader.ReadToEnd(); $reader.Close() } catch {}
            if ($responseContent) { $errMsg += " | Details: $responseContent" } else { $errMsg += " | HTTP $statusCode $statusDesc" }
            if ($statusCode -eq 401) {
                $errMsg += "`n`nAuthentication failed. To get a valid access token, run:`n  `$secureToken = (Get-AzAccessToken -ResourceUrl '$EnvironmentUrl').Token`n  `$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(`$secureToken)`n  `$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(`$BSTR)`n  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR(`$BSTR)`nThen retry with: -AccessToken `$token"
            }
        }
        Throw "Could not delete table '$TableLogicalName'. Error: $errMsg"
    }
}
Export-ModuleMember -Function Remove-DVTable
