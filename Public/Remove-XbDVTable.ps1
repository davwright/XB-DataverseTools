function Remove-XbDVTable {
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

<#
.SYNOPSIS
    Deletes a custom table (entity) from Microsoft Dataverse.

.DESCRIPTION
    Removes a custom table and all its columns from a Dataverse environment using the Web API.
    This operation cannot be undone. All data in the table will be permanently deleted.

    IMPORTANT: This operation will delete:
    - The table and all its metadata
    - All columns/fields in the table
    - All data stored in the table
    - All relationships involving this table

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment, e.g., "https://org.crm4.dynamics.com".

.PARAMETER TableLogicalName
    The logical name of the table to delete (e.g.,  "new_customtable").

.PARAMETER AccessToken
    Optional. OAuth 2.0 bearer token. If not provided, assumes session authentication.

.PARAMETER Force
    Skip the confirmation prompt and delete immediately.

.EXAMPLE
    Remove-XbDVTable -EnvironmentUrl "https://org.crm4.dynamics.com" -TableLogicalName "new_customtable" -AccessToken $token

    Deletes the "new_customtable" table after prompting for confirmation.

.EXAMPLE
    Remove-XbDVTable -EnvironmentUrl $envUrl -TableLogicalName "new_customtable" -AccessToken $token -Force

    Deletes the "new_customtable" table without prompting for confirmation.

.EXAMPLE
    Remove-XbDVTable -EnvironmentUrl $envUrl -TableLogicalName "new_customtable" -AccessToken $token -WhatIf

    Shows what would happen without actually deleting the table.

.OUTPUTS
    System.String
    Returns a confirmation string upon success.

.NOTES
    Author      : Claude Code
    Version     : 1.0
    Date        : 2025-12-04
    License     : CC BY-NC-ND 4.0

    - This operation is irreversible
    - You cannot delete system tables (only custom tables)
    - You must have appropriate permissions in Dataverse
    - The table must not have dependencies (managed relationships, etc.)

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-update-entity-definitions-metadata
#>

    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }

    # Build the URL to get the table's MetadataId
    $getUrl = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions(LogicalName='$TableLogicalName')?`$select=MetadataId,SchemaName,LogicalName"

    try {
        # First, get the table metadata to retrieve MetadataId
        $tableMetadata = Invoke-RestMethod -Method GET -Uri $getUrl -Headers $headers -ErrorAction Stop

        $metadataId = $tableMetadata.MetadataId
        $schemaName = $tableMetadata.SchemaName

        # Confirm deletion
        if ($Force -or $PSCmdlet.ShouldProcess("Table '$schemaName' ($TableLogicalName)", "Delete table and all its data")) {

            # Delete the table using MetadataId
            $deleteUrl = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions($metadataId)"

            Invoke-RestMethod -Method DELETE -Uri $deleteUrl -Headers $headers -ErrorAction Stop | Out-Null

            return "Table '$schemaName' ($TableLogicalName) deleted successfully."
        }
        else {
            return "Table deletion cancelled."
        }
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
        Throw "Could not delete table '$TableLogicalName'. Error: $errMsg"
    }
}
Export-ModuleMember -Function Remove-XbDVTable
