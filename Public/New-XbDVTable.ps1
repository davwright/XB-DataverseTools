function New-XbDVTable {
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
    
<#
.SYNOPSIS
    Creates a new custom table (entity) in Microsoft Dataverse with configurable metadata.

.DESCRIPTION
    Provisions a new table (EntityMetadata) in a Dataverse environment using the Web API.
    Allows specification of schema name, display names, primary name field, ownership model,
    and behavioral properties such as auditing, duplicate detection, activities, and offline access.

    Every table requires a primary name field (text column) that serves as the main record identifier.
    If not specified, defaults are used: SchemaName + "Name", DisplayName "Name", MaxLength 100.
    This field cannot be changed after table creation, so customize it during creation if needed.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment, e.g., "https://org.crm4.dynamics.com".

.PARAMETER SchemaName
    Logical name (SchemaName) of the table to create, including prefix (e.g., "new_Project").

.PARAMETER DisplayName
    Singular display name of the table, shown in model-driven apps and solutions.

.PARAMETER DisplayPluralName
    Plural display name of the table (e.g., "Projects").

.PARAMETER Description
    Optional. A description of the table used in metadata and solution explorers.

.PARAMETER PrimaryFieldSchema
    Optional. SchemaName of the primary name field.
    Default: {TableSchemaName}Name (e.g., if table is "new_Project", this becomes "new_ProjectName")
    IMPORTANT: The primary name field is the main identifier for records and cannot be changed after table creation.

.PARAMETER PrimaryFieldDisplayName
    Optional. Display name for the primary name field shown in the UI.
    Default: "Name"
    Example: "Project Name", "Case Title", "Contact Name"

.PARAMETER PrimaryFieldDescription
    Optional. Description for the primary name field shown in metadata.
    Default: "Primary name for {DisplayName}"

.PARAMETER PrimaryFieldMaxLength
    Maximum length for the primary name field. Range 1-4000. Default is 100.

.PARAMETER PrimaryFieldRequiredLevel
    Requirement level for the primary name field. Options:
    - None: Field is optional (default)
    - Recommended: Field shows a blue + icon, suggesting users fill it in
    - ApplicationRequired: Field must be filled in before the record can be saved

.PARAMETER OwnershipType
    Ownership model for the table. Options:
    - UserOwned (default): records owned by users/teams
    - OrganizationOwned: records not owned by individuals

.PARAMETER IsActivityTable
    Create an Activity table instead of a standard entity. Activity tables appear in timelines.

.PARAMETER EnableAuditing
    Enables auditing on the table. Default is disabled.

.PARAMETER EnableDuplicateDetection
    Enables duplicate detection on the table. Default is disabled.

.PARAMETER EnableOffline
    Makes the table available offline (for mobile clients). Default is disabled.

.PARAMETER EnableNotes
    Enables the Notes (attachments) feature on the table.

.PARAMETER EnableActivities
    Enables activity tracking (e.g., emails, tasks) on the table.

.PARAMETER SolutionUniqueName
    Optional. Unique name of the solution to add this table to during creation.
    If not specified, the table is added to the default solution (Common Data Services Default Solution).
    The solution must already exist in the environment.
    Example: "MyCustomSolution", "CoreComponents"

.PARAMETER AccessToken
    Optional. OAuth 2.0 bearer token for authorization. If not specified, assumes existing auth context.

.EXAMPLE
    New-XbDVTable -EnvironmentUrl "https://org.crm4.dynamics.com" -SchemaName "new_Project" `
        -DisplayName "Project" -DisplayPluralName "Projects" -Description "Project tracking table" `
        -EnableNotes -EnableAuditing

.EXAMPLE
    New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "custom_caseplan" `
        -DisplayName "Case Plan" -DisplayPluralName "Case Plans" -EnableActivities -EnableOffline

.EXAMPLE
    New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_task" `
        -DisplayName "Custom Task" -DisplayPluralName "Custom Tasks" `
        -PrimaryFieldMaxLength 200 -PrimaryFieldRequiredLevel ApplicationRequired `
        -EnableAuditing

.EXAMPLE
    New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_customactivity" `
        -DisplayName "Custom Activity" -DisplayPluralName "Custom Activities" `
        -IsActivityTable -EnableActivities

.EXAMPLE
    New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_product" `
        -DisplayName "Product" -DisplayPluralName "Products" `
        -PrimaryFieldSchema "new_ProductCode" `
        -PrimaryFieldDisplayName "Product Code" `
        -PrimaryFieldDescription "Unique identifier for the product" `
        -PrimaryFieldMaxLength 50 `
        -PrimaryFieldRequiredLevel ApplicationRequired

    Creates a table with a customized primary name field called "Product Code" that is required
    and limited to 50 characters. Without these parameters, the primary field would default to
    "new_ProductName" with display name "Name" and 100 character length.

.EXAMPLE
    New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_inventory" `
        -DisplayName "Inventory Item" -DisplayPluralName "Inventory Items" `
        -SolutionUniqueName "WarehouseManagement" `
        -EnableAuditing -EnableNotes

    Creates a table and adds it to the "WarehouseManagement" solution during creation.
    The solution must already exist in the environment.

.OUTPUTS
    None. Writes confirmation to host or throws error on failure.

.NOTES
    Author      : Kristian Holm Buch
    Version     : 1.0
    Date        : 2025-05-04
    Editor      : PowerShell Studio 2025
    License     : CC BY-NC-ND 4.0
    Copyright   : (c) 2025 - Kristian Holm Buch. All Rights Reserved.

    PRIMARY NAME FIELD:
    Every Dataverse table must have exactly one primary name field (text column) that serves as the
    main identifier for records. This field is set when creating the table and CANNOT be changed later.

    Defaults (if parameters not specified):
    - SchemaName: {TableSchemaName}Name (e.g., "new_Project" → "new_ProjectName")
    - DisplayName: "Name"
    - Description: "Primary name for {DisplayName}"
    - MaxLength: 100 characters
    - RequiredLevel: None (optional)

    To customize the primary name field, specify these parameters when creating the table:
    -PrimaryFieldSchema, -PrimaryFieldDisplayName, -PrimaryFieldMaxLength,
    -PrimaryFieldRequiredLevel

    SOLUTION ASSIGNMENT:
    Tables can be added to a specific solution during creation using the -SolutionUniqueName parameter.
    If not specified, the table is added to the "Default Solution" (Common Data Services Default Solution).
    The solution must already exist before creating the table.
    You can also add tables to solutions after creation using the Dataverse UI or APIs.

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-entity
#>

    # Set default values for primary name field if not specified
    if (-not $PrimaryFieldSchema -or $PrimaryFieldSchema.Trim() -eq "") {
        $PrimaryFieldSchema = $SchemaName + "Name"
    }
    if (-not $PrimaryFieldDisplayName -or $PrimaryFieldDisplayName.Trim() -eq "") {
        $PrimaryFieldDisplayName = "Name"
    }
    if (-not $PrimaryFieldDescription) {
        $PrimaryFieldDescription = "Primary name for $DisplayName"
    }

    # Build localized labels for DisplayName
    $displayNameLabels = @(
        @{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = $DisplayName
            LanguageCode  = 1033
        }
    )
    if ($DisplayNameDE) {
        $displayNameLabels += @{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = $DisplayNameDE
            LanguageCode  = 1031
        }
    }

    # Build localized labels for DisplayCollectionName (plural)
    $displayPluralLabels = @(
        @{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = $DisplayPluralName
            LanguageCode  = 1033
        }
    )

    # Build JSON body for the new table (EntityMetadata)
    $entity = [ordered]@{
        "@odata.type"             = "Microsoft.Dynamics.CRM.EntityMetadata"
        SchemaName                = $SchemaName
        DisplayName               = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = $displayNameLabels
        }
        DisplayCollectionName     = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = $displayPluralLabels
        }
        Description               = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $Description
                LanguageCode  = 1033
            })
        }
        OwnershipType            = $OwnershipType           # "UserOwned" or "OrganizationOwned"
        IsActivity               = ([bool]$IsActivityTable) # Activity table or standard entity
        HasNotes                 = ([bool]$EnableNotes)     # enable notes (attachments)
        HasActivities            = ([bool]$EnableActivities)  # enable activities (activity panel)
        # Primary name attribute (required for a new table):
        Attributes = @(
            @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
                SchemaName       = $PrimaryFieldSchemaName
                DisplayName      = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    "LocalizedLabels" = $(
                        $primaryLabels = @(
                            @{
                                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                                Label         = $PrimaryFieldDisplayName
                                LanguageCode  = 1033
                            }
                        )
                        if ($PrimaryFieldDisplayNameDE) {
                            $primaryLabels += @{
                                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                                Label         = $PrimaryFieldDisplayNameDE
                                LanguageCode  = 1031
                            }
                        }
                        $primaryLabels
                    )
                }
                Description      = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    "LocalizedLabels" = @(@{
                        "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                        Label         = $PrimaryFieldDescription
                        LanguageCode  = 1033
                    })
                }
                MaxLength        = $PrimaryFieldMaxLength
                FormatName       = @{ Value = "Text" }
                RequiredLevel    = @{
                    Value                         = $PrimaryFieldRequiredLevel
                    CanBeChanged                  = $true
                    ManagedPropertyLogicalName    = "canmodifyrequirementlevelsettings"
                }
                IsPrimaryName    = $true
            }
        )
        # Managed properties for auditing, duplicate detection, offline:
        IsAuditEnabled = @{
            Value                         = ([bool]$EnableAuditing)
            CanBeChanged                  = $true
            ManagedPropertyLogicalName    = "canmodifyauditsettings"
        }
        IsDuplicateDetectionEnabled = @{
            Value                         = ([bool]$EnableDuplicateDetection)
            CanBeChanged                  = $true
            ManagedPropertyLogicalName    = "canmodifyduplicatedetectionsettings"
        }
        IsOfflineInMobileClient = @{
            Value                         = ([bool]$EnableOffline)
            CanBeChanged                  = $true
            ManagedPropertyLogicalName    = "canmodifymobileclientoffline"
        }
        IsAvailableOffline        = ([bool]$EnableOffline)  # make table available offline
    }

    $jsonBody = $entity | ConvertTo-Json -Depth 15
    $headers = @{
        Accept = 'application/json; charset=utf-8'
        "Content-Type" = 'application/json; charset=utf-8'
    }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }
    # Add table to specific solution if specified
    if ($SolutionUniqueName) {
        $headers["MSCRM.SolutionUniqueName"] = $SolutionUniqueName
    }

    $url = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions"
    try {
        Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ErrorAction Stop
        Write-Host "Dataverse table '$DisplayName' created (SchemaName: $SchemaName)." -ForegroundColor  Green
       }
    catch {
        Throw "Could not create table '$SchemaName'. Error: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function New-XbDVTable 

# Example: Create a new custom table "Project" (user-owned) with notes and auditing enabled
# New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_Project" -DisplayName "Project" `
#    -DisplayPluralName "Projects" -Description "Table for managing projects" `
#    -PrimaryFieldMaxLength 200 -PrimaryFieldRequiredLevel ApplicationRequired `
#    -EnableNotes -EnableAuditing -EnableDuplicateDetection
