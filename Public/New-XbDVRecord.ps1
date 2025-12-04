function New-XbDVRecord {
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
    
<#
.SYNOPSIS
    Creates a new record in a Dataverse table using the Web API.

.DESCRIPTION
    Sends a POST request to the specified table's endpoint with the provided field data.
    Returns the OData entity URI or a status message upon successful creation.
    Supports authentication via access token or pre-authenticated session.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment, e.g., "https://org.crm4.dynamics.com".

.PARAMETER TableName
    The plural entity set name (e.g., "contacts", "accounts") of the table to insert into.

.PARAMETER Data
    A hashtable containing field-value pairs representing the attributes of the record.

.PARAMETER AccessToken
    Optional. OAuth 2.0 bearer token. If not provided, assumes authentication context is already established.

.EXAMPLE
    $newContact = @{ firstname = "Hans"; lastname = "Hansen" }
    New-DVRecord -EnvironmentUrl $envUrl -TableName "contacts" -Data $newContact

.EXAMPLE
    New-DVRecord -EnvironmentUrl "https://org.crm4.dynamics.com" -TableName "accounts" `
                 -Data @{ name = "NexaBlue A/S"; telephone1 = "+45 12345678" } -AccessToken $token

.OUTPUTS
    System.String
    Returns the URI of the newly created record or a status message.

.NOTES
    Author      : Kristian Holm Buch
    Version     : 1.0
    Date        : 2025-05-04
    Editor      : PowerShell Studio 2025
    License     : CC BY-NC-ND 4.0
    Copyright   : (c) 2025 - Kristian Holm Buch. All Rights Reserved.

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-entity
#>
    # Check if the required parameters are provided
    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }
    # Convert input data to JSON body
    $jsonBody = ($Data | ConvertTo-Json -Depth 5)
    $url = "$EnvironmentUrl/api/data/v9.2/$TableName"
    try {
        # Use POST to create a new record
        $response = Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ContentType 'application/json' -ErrorAction Stop
        # If the creation is successful, Dataverse typically responds with HTTP 204 No Content and an 'OData-EntityId' header containing the URL of the new object.
        # We return the URL or entity ID as confirmation.
        $createdUri = $response | Out-Null
        if ($_.HttpResponseHeaders.'OData-EntityId') {
            return $_.HttpResponseHeaders.'OData-EntityId'
        } else {
            return "Record created (no content returned)."
        }
    }
    catch {
        # Extract error message(s) from the response if possible
        $errMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDesc = $_.Exception.Response.StatusDescription
            try {
                $responseStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($responseStream)
                $responseContent = $reader.ReadToEnd(); $reader.Close()
            } catch {}
            if ($responseContent) {
                $errMsg += " | Details: $responseContent"
            } else {
                $errMsg += " | HTTP $statusCode $statusDesc"
            }
        }
        Throw "Could not create new $TableName record. Error: $errMsg"
    }
}
Export-ModuleMember -Function New-XbDVRecord

# Example: Create a new contact and then update its last name
# $newContact = @{
#     firstname = "Hans"
#     lastname  = "Hansen"
#     emailaddress1 = "hans.hansen@company.com"
# }
# $entityIdUrl = New-DVRecord -EnvironmentUrl $envUrl -TableName "contacts" -Data $newContact
# Write-Host "New contact created:" $entityIdUrl
#
# # Extract GUID from URL (last part after '(' )
# if ($entityIdUrl -match '\(([^)]+)\)') {
#     $contactId = $Matches[1]
#     Update-DVRecord -EnvironmentUrl $envUrl -TableName "contacts" -RecordId $contactId -Data @{ lastname = "Hansen-Olsen" }
# }
