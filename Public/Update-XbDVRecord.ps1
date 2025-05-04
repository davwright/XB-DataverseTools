function Update-XbDVRecord {
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
    
<#
.SYNOPSIS
    Updates an existing Dataverse record by ID.

.DESCRIPTION
    Sends a PATCH request to a specific record in a Dataverse table with the provided key-value pairs.
    Supports authentication using an access token or assumes prior authentication context.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment, e.g., "https://org.crm4.dynamics.com".

.PARAMETER TableName
    The plural entity set name of the table (e.g., "contacts", "accounts").

.PARAMETER RecordId
    The GUID of the record to update (without braces).

.PARAMETER Data
    Hashtable containing the fields and values to be updated.

.PARAMETER AccessToken
    Optional. OAuth 2.0 bearer token. If not provided, assumes session authentication.

.EXAMPLE
    $updates = @{ lastname = "Hansen-Olsen" }
    Update-XbDVRecord -EnvironmentUrl $envUrl -TableName "contacts" -RecordId $id -Data $updates

.EXAMPLE
    Update-XbDVRecord -EnvironmentUrl "https://org.crm4.dynamics.com" -TableName "accounts" `
                    -RecordId "7c2a7d6f-7c3e-ed11-9db1-0022481a289c" `
                    -Data @{ telephone1 = "+45 33445566" } -AccessToken $token

.OUTPUTS
    System.String
    Returns a confirmation string upon success.

.NOTES
    Author      : Kristian Holm Buch
    Version     : 1.0
    Date        : 2025-05-04
    Editor      : PowerShell Studio 2025
    License     : CC BY-NC-ND 4.0
    Copyright   : (c) 2025 - Kristian Holm Buch. All Rights Reserved.

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/update-delete-entity
#>

    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }
    $jsonBody = ($Data | ConvertTo-Json -Depth 5)
    # The Dataverse API requires the primary key GUID in parentheses after the entity name to address a specific record.
    $url = "$EnvironmentUrl/api/data/v9.2/$TableName($RecordId)"
    try {
        # Use PATCH to update (MERGE can also be used, but PATCH is standard)
        Invoke-RestMethod -Method PATCH -Uri $url -Headers $headers -Body $jsonBody -ContentType 'application/json' -ErrorAction Stop | Out-Null
        return "Record $RecordId updated."
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDesc = $_.Exception.Response.StatusDescription
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseContent = $reader.ReadToEnd(); $reader.Close()
            } catch {}
            if ($responseContent) {
                $errMsg += " | Details: $responseContent"
            } else {
                $errMsg += " | HTTP $statusCode $statusDesc"
            }
        }
        Throw "Update of $TableName($RecordId) failed. Error: $errMsg"
    }
}
Export-ModuleMember -Function Update-XbDVRecord