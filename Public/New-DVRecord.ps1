# Heritage: formerly XB-DataverseTools (NexaBlue)
function New-DVRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com$')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,
    
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The plural entity set name (e.g., 'contacts', 'accounts')")]
        [Alias('EntitySet')]
        [ValidateNotNullOrEmpty()]
        [string]$TableName,
    
        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Hashtable of field names and values for the new record")]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data,
    
        [Parameter(HelpMessage = "OAuth 2.0 bearer token. If not specified, assumes session is already authenticated.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
    )

    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }
    $jsonBody = ($Data | ConvertTo-Json -Depth 5)
    $url = "$EnvironmentUrl/api/data/v9.2/$TableName"
    try {
        $response = Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ContentType 'application/json' -ErrorAction Stop
        if ($_.HttpResponseHeaders.'OData-EntityId') { return $_.HttpResponseHeaders.'OData-EntityId' } else { return "Record created (no content returned)." }
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDesc = $_.Exception.Response.StatusDescription
            try { $responseStream = $_.Exception.Response.GetResponseStream(); $reader = New-Object System.IO.StreamReader($responseStream); $responseContent = $reader.ReadToEnd(); $reader.Close() } catch {}
            if ($responseContent) { $errMsg += " | Details: $responseContent" } else { $errMsg += " | HTTP $statusCode $statusDesc" }
        }
        Throw "Could not create new $TableName record. Error: $errMsg"
    }
}
Export-ModuleMember -Function New-DVRecord

# Example: Create a new contact and then update its last name
# $newContact = @{
#     firstname = "Hans"
#     lastname  = "Hansen"
#     emailaddress1 = "hans.hansen@company.com"
# }
# $entityIdUrl = New-DVRecord -EnvironmentUrl $envUrl -TableName "contacts" -Data $newContact
