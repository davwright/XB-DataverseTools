function New-XbDVPolymorphicLookup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com$')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Logical name of the table that will contain the polymorphic lookup, e.g., 'new_activity'")]
        [Alias('Entity', 'LogicalName')]
        [ValidateNotNullOrEmpty()]
        [string]$ReferencingTable,

        [Parameter(Mandatory = $true, HelpMessage = "SchemaName for the new polymorphic lookup column (with prefix, e.g., 'new_RegardingObjectId')")]
        [ValidatePattern('^[a-zA-Z0-9_]+_[a-zA-Z0-9_]+$')]
        [ValidateNotNullOrEmpty()]
        [string]$SchemaName,

        [Parameter(Mandatory = $true, HelpMessage = "Display name for the new polymorphic lookup shown in the UI")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(HelpMessage = "Optional description for the polymorphic lookup shown in metadata and UI")]
        [string]$Description = "",

        [Parameter(Mandatory = $true, HelpMessage = "Array of hashtables containing 'LogicalName' for each target table, e.g., @(@{LogicalName='account'}, @{LogicalName='contact'})")]
        [ValidateNotNullOrEmpty()]
        [hashtable[]]$ReferencedTables,

        [Parameter(HelpMessage = "Requirement level for the column (None, Recommended, ApplicationRequired, SystemRequired). Default: None.")]
        [ValidateSet("None","Recommended","ApplicationRequired","SystemRequired")]
        [string]$RequiredLevel = "None",

        [Parameter(HelpMessage = "Unique name of the solution to add this polymorphic lookup to (e.g., 'MyCustomSolution'). If not specified, column is added to the default solution.")]
        [string]$SolutionUniqueName,

        [Parameter(HelpMessage = "OAuth 2.0 bearer token. If not provided, assumes the session is authenticated.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
    )
<#
.SYNOPSIS
    Creates a new polymorphic (multi-table) lookup column on a Dataverse table via the Web API.

.DESCRIPTION
    This function provisions a polymorphic lookup attribute (column) on a Dataverse table using the
    CreatePolymorphicLookupAttribute Web API action. A polymorphic lookup allows a single lookup field
    to reference multiple different types of entities.

    For example, a "Regarding" field that can point to accounts, contacts, or custom entities.

    The function uses the specialized CreatePolymorphicLookupAttribute action which creates both
    the lookup attribute and all necessary OneToManyRelationship metadata in a single atomic operation.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment (e.g., 'https://org.crm4.dynamics.com').

.PARAMETER ReferencingTable
    The logical name of the entity/table that will contain the polymorphic lookup field
    (e.g., 'new_activity', 'annotation').

.PARAMETER SchemaName
    The schema name of the new polymorphic lookup column. Must include a valid prefix
    (e.g., 'new_RegardingObjectId').

.PARAMETER DisplayName
    The display name of the polymorphic lookup as seen in the UI.

.PARAMETER Description
    Optional. A description of the polymorphic lookup to be shown in metadata and UI.

.PARAMETER ReferencedTables
    Array of hashtables specifying the target tables this polymorphic lookup can reference.
    Each hashtable must contain:
    - LogicalName: The logical name of the target entity (e.g., 'account', 'contact', 'new_project')

    Example: @(@{LogicalName='account'}, @{LogicalName='contact'}, @{LogicalName='lead'})

    Note: The PluralName is no longer required as the CreatePolymorphicLookupAttribute action
    handles this automatically.

.PARAMETER RequiredLevel
    The requirement level for the column. Options:
    - None: Field is completely optional (default)
    - Recommended: Field shows a blue + icon, suggesting users fill it in but not enforced
    - ApplicationRequired: Field must be filled in before the record can be saved
    - SystemRequired: Reserved for system fields (rarely used for custom fields)

.PARAMETER SolutionUniqueName
    Optional. Unique name of the solution to add this polymorphic lookup to during creation.
    If not specified, the column is added to the default solution (Common Data Services Default Solution).
    The solution must already exist in the environment.

.PARAMETER AccessToken
    Optional. OAuth 2.0 bearer token. If not provided, the function assumes the session is pre-authenticated.

.EXAMPLE
    $targets = @(
        @{LogicalName='account'},
        @{LogicalName='contact'},
        @{LogicalName='lead'}
    )
    New-XbDVPolymorphicLookup -EnvironmentUrl "https://org.crm4.dynamics.com" `
        -ReferencingTable "new_activity" -SchemaName "new_RegardingObjectId" `
        -DisplayName "Regarding" -ReferencedTables $targets

    Creates a polymorphic lookup that can reference accounts, contacts, or leads.

.EXAMPLE
    $targets = @(
        @{LogicalName='new_project'},
        @{LogicalName='new_campaign'}
    )
    New-XbDVPolymorphicLookup -EnvironmentUrl $envUrl -ReferencingTable "new_document" `
        -SchemaName "new_RelatedRecordId" -DisplayName "Related Record" `
        -ReferencedTables $targets -RequiredLevel ApplicationRequired

    Creates a required polymorphic lookup on a custom document table.

.EXAMPLE
    # Using the solution parameter
    $targets = @(
        @{LogicalName='account'},
        @{LogicalName='new_client'}
    )
    New-XbDVPolymorphicLookup -EnvironmentUrl $envUrl -ReferencingTable "new_invoice" `
        -SchemaName "new_BilledToId" -DisplayName "Billed To" `
        -ReferencedTables $targets -SolutionUniqueName "FinanceModule" -AccessToken $token

.INPUTS
    None

.OUTPUTS
    PSCustomObject with AttributeId and RelationshipIds from the API response.

.NOTES
    Author      : Kristian Holm Buch
    Version     : 2.0
    Date        : 2025-12-05
    Editor      : PowerShell Studio 2025
    License     : CC BY-NC-ND 4.0
    Copyright   : (c) 2025 - Kristian Holm Buch. All Rights Reserved.

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/createpolymorphiclookupattribute

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/multitable-lookup
#>
    # Helper function to create Label objects
    function New-Label($text) {
        return @{
            "@odata.type"     = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{
                "@odata.type"    = "Microsoft.Dynamics.CRM.LocalizedLabel"
                "Label"          = $text
                "LanguageCode"   = 1033
            })
        }
    }

    # Validate that ReferencedTables is not empty and contains valid data
    if (-not $ReferencedTables -or $ReferencedTables.Count -eq 0) {
        Throw "ReferencedTables must contain at least one target table definition."
    }

    # Validate each hashtable has required LogicalName property
    foreach ($table in $ReferencedTables) {
        if (-not $table.LogicalName) {
            Throw "Each table in ReferencedTables must have a 'LogicalName' property."
        }
    }

    # Build RequiredLevel metadata object
    $reqLevel = @{
        Value = $RequiredLevel
        CanBeChanged = $true
        ManagedPropertyLogicalName = "canmodifyrequirementlevelsettings"
    }

    # Build the OneToManyRelationships array - one relationship per target table
    $relationships = @()
    foreach ($table in $ReferencedTables) {
        $targetLogicalName = $table.LogicalName

        # Generate a relationship schema name (standard Dataverse pattern)
        # Format: referencedentity_referencingentity_lookupfield
        $relationshipSchemaName = "${targetLogicalName}_${ReferencingTable}_$SchemaName"

        $relationship = @{
            SchemaName = $relationshipSchemaName
            ReferencedEntity = $targetLogicalName
            ReferencingEntity = $ReferencingTable
            CascadeConfiguration = @{
                Assign = "NoCascade"
                Delete = "RemoveLink"  # When target is deleted, clear the lookup
                Merge = "NoCascade"
                Reparent = "NoCascade"
                Share = "NoCascade"
                Unshare = "NoCascade"
            }
        }

        $relationships += $relationship
    }

    # Build the Lookup attribute metadata
    $lookupMetadata = @{
        AttributeType = "Lookup"
        AttributeTypeName = @{
            Value = "LookupType"
        }
        SchemaName = $SchemaName
        DisplayName = New-Label $DisplayName
        Description = New-Label $Description
        RequiredLevel = $reqLevel
    }

    # Build the complete request body for CreatePolymorphicLookupAttribute action
    $requestBody = @{
        OneToManyRelationships = $relationships
        Lookup = $lookupMetadata
    }

    # Add SolutionUniqueName if specified
    if ($SolutionUniqueName) {
        $requestBody["SolutionUniqueName"] = $SolutionUniqueName
    }

    # Convert to JSON
    $jsonBody = ($requestBody | ConvertTo-Json -Depth 15)

    # Prepare headers
    $headers = @{
        Accept = 'application/json; charset=utf-8'
        "Content-Type" = 'application/json; charset=utf-8'
        "OData-MaxVersion" = "4.0"
        "OData-Version" = "4.0"
    }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }

    # Use the CreatePolymorphicLookupAttribute Web API action
    $actionUrl = "$EnvironmentUrl/api/data/v9.2/CreatePolymorphicLookupAttribute"

    try {
        Write-Host "Creating polymorphic lookup '$DisplayName' on $ReferencingTable with $($ReferencedTables.Count) target table(s)..." -ForegroundColor Cyan

        $response = Invoke-RestMethod -Method POST -Uri $actionUrl -Headers $headers -Body $jsonBody -ErrorAction Stop

        Write-Host "  Polymorphic lookup created successfully!" -ForegroundColor Green
        Write-Host "  Attribute ID: $($response.AttributeId)" -ForegroundColor Gray
        Write-Host "  Relationships created: $($response.RelationshipIds.Count)" -ForegroundColor Gray

        # Return the response for potential further processing
        return [PSCustomObject]@{
            AttributeId = $response.AttributeId
            RelationshipIds = $response.RelationshipIds
            SchemaName = $SchemaName
            DisplayName = $DisplayName
            ReferencingTable = $ReferencingTable
            TargetTables = ($ReferencedTables | ForEach-Object { $_.LogicalName })
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                $errorMessage = $errorDetails.error.message
            }
            catch {
                $errorMessage = $_.ErrorDetails.Message
            }
        }
        Throw "Failed to create polymorphic lookup '$SchemaName' on $ReferencingTable. Error: $errorMessage"
    }
}
Export-ModuleMember -Function New-XbDVPolymorphicLookup
