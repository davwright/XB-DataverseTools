# Heritage: formerly XB-DataverseTools (NexaBlue)
function New-DVTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com\/?$')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,
    
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Logical schema name for the table, including prefix (e.g., 'new_CustomEntity')")]
        [ValidatePattern('^[a-zA-Z0-9_]+_[a-zA-Z0-9_]+$')]
        [ValidateNotNullOrEmpty()]
        [string]$SchemaName,
    
        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Singular display name of the table (e.g., 'Project')")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Singular display name of the table (e.g., 'Project')")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayNameDE,

        [Parameter(Mandatory = $true, Position = 3, HelpMessage = "Plural display name of the table (e.g., 'Projects')")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayPluralName,
    
        [Parameter(HelpMessage = "Optional description of the table shown in UI and metadata.")]
        [string]$Description = "",
    
        [Parameter(HelpMessage = "SchemaName of the primary name field. If not set, defaults to <SchemaName>Name.")]
        [ValidatePattern('^$|^[a-zA-Z0-9_]+_[a-zA-Z0-9_]+$')]
        [string]$PrimaryFieldSchemaName = "",
    
        [Parameter(HelpMessage = "Display name of the primary name field. If not set, defaults to 'Name'.")]
        [string]$PrimaryFieldDisplayName = "",
    
        [Parameter(HelpMessage = "Display name of the primary name fieldin German.")]
        [string]$PrimaryFieldDisplayNameDE = "",
    
        [Parameter(HelpMessage = "Optional description of the primary name field.")]
        [string]$PrimaryFieldDescription = "",

        [Parameter(HelpMessage = "Maximum length for the primary name field (1-4000). Default: 100.")]
        [ValidateRange(1,4000)]
        [int]$PrimaryFieldMaxLength = 100,

        [Parameter(HelpMessage = "Requirement level for the primary name field (None, Recommended, ApplicationRequired). Default: None.")]
        [ValidateSet("None","Recommended","ApplicationRequired")]
        [string]$PrimaryFieldRequiredLevel = "None",

        [Parameter(HelpMessage = "Ownership model for the table: UserOwned or OrganizationOwned.")]
        [ValidateSet("UserOwned", "OrganizationOwned")]
        [string]$OwnershipType = "UserOwned",

        [Parameter(HelpMessage = "Create an Activity table instead of a standard table.")]
        [switch]$IsActivityTable,

        [Parameter(HelpMessage = "Enable auditing for the table.")]
        [switch]$EnableAuditing,

        [Parameter(HelpMessage = "Enable duplicate detection.")]
        [switch]$EnableDuplicateDetection,

        [Parameter(HelpMessage = "Enable offline availability in mobile apps.")]
        [switch]$EnableOffline,

        [Parameter(HelpMessage = "Enable notes and file attachments.")]
        [switch]$EnableNotes,

        [Parameter(HelpMessage = "Enable activities (e.g., tasks, emails) for this table.")]
        [switch]$EnableActivities,

        [Parameter(HelpMessage = "Unique name of the solution to add this table to (e.g., 'MyCustomSolution'). If not specified, table is added to the default solution.")]
        [string]$SolutionUniqueName,

        [Parameter(HelpMessage = "OAuth 2.0 bearer token. Optional if session is pre-authenticated.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
    )

    # Implementation preserved from original New-XbDVTable but exported as New-DVTable
    # Set default values for primary name field if not specified
    if (-not $PrimaryFieldSchema -or $PrimaryFieldSchema.Trim() -eq "") { $PrimaryFieldSchema = $SchemaName + "Name" }
    if (-not $PrimaryFieldDisplayName -or $PrimaryFieldDisplayName.Trim() -eq "") { $PrimaryFieldDisplayName = "Name" }
    if (-not $PrimaryFieldDescription) { $PrimaryFieldDescription = "Primary name for $DisplayName" }

    # Build localized labels for DisplayName
    $displayNameLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = $DisplayName; LanguageCode = 1033 })
    if ($DisplayNameDE) { $displayNameLabels += @{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = $DisplayNameDE; LanguageCode = 1031 } }

    $displayPluralLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = $DisplayPluralName; LanguageCode = 1033 })

    $entity = [ordered]@{
        "@odata.type"             = "Microsoft.Dynamics.CRM.EntityMetadata"
        SchemaName                = $SchemaName
        DisplayName               = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; "LocalizedLabels" = $displayNameLabels }
        DisplayCollectionName     = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; "LocalizedLabels" = $displayPluralLabels }
        Description               = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; "LocalizedLabels" = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = $Description; LanguageCode = 1033 }) }
        OwnershipType            = $OwnershipType
        IsActivity               = ([bool]$IsActivityTable)
        HasNotes                 = ([bool]$EnableNotes)
        HasActivities            = ([bool]$EnableActivities)
        Attributes = @( @{ "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"; SchemaName = $PrimaryFieldSchemaName; DisplayName = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; "LocalizedLabels" = @( @{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = $PrimaryFieldDisplayName; LanguageCode = 1033 } ) } } )
        IsAuditEnabled = @{ Value = ([bool]$EnableAuditing); CanBeChanged = $true; ManagedPropertyLogicalName = "canmodifyauditsettings" }
        IsDuplicateDetectionEnabled = @{ Value = ([bool]$EnableDuplicateDetection); CanBeChanged = $true; ManagedPropertyLogicalName = "canmodifyduplicatedetectionsettings" }
        IsOfflineInMobileClient = @{ Value = ([bool]$EnableOffline); CanBeChanged = $true; ManagedPropertyLogicalName = "canmodifymobileclientoffline" }
        IsAvailableOffline        = ([bool]$EnableOffline)
    }

    $jsonBody = $entity | ConvertTo-Json -Depth 15
    $headers = @{ Accept = 'application/json; charset=utf-8'; "Content-Type" = 'application/json; charset=utf-8' }
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }
    if ($SolutionUniqueName) { $headers["MSCRM.SolutionUniqueName"] = $SolutionUniqueName }

    $url = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions"
    try { Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ErrorAction Stop; Write-Host "Dataverse table '$DisplayName' created (SchemaName: $SchemaName)." -ForegroundColor  Green }
    catch { Throw "Could not create table '$SchemaName'. Error: $($_.Exception.Message)" }
}
Export-ModuleMember -Function New-DVTable
