# Heritage: formerly XB-DataverseTools (NexaBlue)
function Update-DVRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com$')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,
    
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The plural entity set name of the table (e.g., 'contacts')")]
        [Alias('EntitySet')]
        [ValidateNotNullOrEmpty()]
        [string]$TableName,
    
        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "The GUID of the record to update (without curly braces)")]
        [Alias('Id')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [ValidateNotNullOrEmpty()]
        [string]$RecordId,
    
        [Parameter(Mandatory = $true, HelpMessage = "Hashtable containing field names and their updated values")]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data,
    
        [Parameter(HelpMessage = "OAuth 2.0 bearer token. If not specified, assumes session is already authenticated.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
    )

    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }
    $jsonBody = ($Data | ConvertTo-Json -Depth 5)
    $url = "$EnvironmentUrl/api/data/v9.2/$TableName($RecordId)"
    try {
        Invoke-RestMethod -Method PATCH -Uri $url -Headers $headers -Body $jsonBody -ContentType 'application/json' -ErrorAction Stop | Out-Null
        return "Record $RecordId updated."
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDesc = $_.Exception.Response.StatusDescription
            try { $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream()); $responseContent = $reader.ReadToEnd(); $reader.Close() } catch {}
            if ($responseContent) { $errMsg += " | Details: $responseContent" } else { $errMsg += " | HTTP $statusCode $statusDesc" }
        }
        Throw "Update of $TableName($RecordId) failed. Error: $errMsg"
    }
}
Export-ModuleMember -Function Update-DVRecord
