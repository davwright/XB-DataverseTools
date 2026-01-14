# Heritage: formerly XB-DataverseTools (NexaBlue)
function New-DVPolymorphicLookup {
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
    #>

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

    if (-not $ReferencedTables -or $ReferencedTables.Count -eq 0) { Throw "ReferencedTables must contain at least one target table definition." }
    foreach ($table in $ReferencedTables) { if (-not $table.LogicalName) { Throw "Each table in ReferencedTables must have a 'LogicalName' property." } }

    $reqLevel = @{
        Value = $RequiredLevel
        CanBeChanged = $true
        ManagedPropertyLogicalName = "canmodifyrequirementlevelsettings"
    }

    $relationships = @()
    foreach ($table in $ReferencedTables) {
        $targetLogicalName = $table.LogicalName
        $relationshipSchemaName = "${targetLogicalName}_${ReferencingTable}_$SchemaName"
        $relationship = @{
            SchemaName = $relationshipSchemaName
            ReferencedEntity = $targetLogicalName
            ReferencingEntity = $ReferencingTable
            CascadeConfiguration = @{
                Assign = "NoCascade"
                Delete = "RemoveLink"
                Merge = "NoCascade"
                Reparent = "NoCascade"
                Share = "NoCascade"
                Unshare = "NoCascade"
            }
        }
        $relationships += $relationship
    }

    $lookupMetadata = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.ComplexLookupAttributeMetadata"
        AttributeType = "Lookup"
        AttributeTypeName = @{ Value = "LookupType" }
        SchemaName = $SchemaName
        DisplayName = New-Label $DisplayName
        Description = New-Label $Description
        RequiredLevel = $reqLevel
    }

    $requestBody = @{
        OneToManyRelationships = $relationships
        Lookup = $lookupMetadata
    }
    if ($SolutionUniqueName) { $requestBody["SolutionUniqueName"] = $SolutionUniqueName }

    $jsonBody = ($requestBody | ConvertTo-Json -Depth 15)

    $headers = @{
        Accept = 'application/json; charset=utf-8'
        "Content-Type" = 'application/json; charset=utf-8'
        "OData-MaxVersion" = "4.0"
        "OData-Version" = "4.0"
    }
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }

    $actionUrl = "$EnvironmentUrl/api/data/v9.2/CreatePolymorphicLookupAttribute"

    $restFilePath = Join-Path $PWD "$SchemaName.rest"
    $restContent = @()
    $restContent += "POST $actionUrl"
    foreach ($headerKey in $headers.Keys) { $restContent += "${headerKey}: $($headers[$headerKey])" }
    $restContent += ""
    $restContent += $jsonBody
    $restContent -join "`n" | Out-File -FilePath $restFilePath -Encoding UTF8

    try {
        Write-Host "Creating polymorphic lookup '$DisplayName' on $ReferencingTable with $($ReferencedTables.Count) target table(s)..." -ForegroundColor Cyan
        $response = Invoke-RestMethod -Method POST -Uri $actionUrl -Headers $headers -Body $jsonBody -ErrorAction Stop
        Write-Host "  Polymorphic lookup created successfully!" -ForegroundColor Green
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
            try { $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json; $errorMessage = $errorDetails.error.message }
            catch { $errorMessage = $_.ErrorDetails.Message }
        }
        Throw "Failed to create polymorphic lookup '$SchemaName' on $ReferencingTable. Error: $errorMessage"
    }
}
Export-ModuleMember -Function New-DVPolymorphicLookup
