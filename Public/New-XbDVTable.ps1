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
    
        [Parameter(Mandatory = $true, Position = 3, HelpMessage = "Plural display name of the table (e.g., 'Projects')")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayPluralName,
    
        [Parameter(HelpMessage = "Optional description of the table shown in UI and metadata.")]
        [string]$Description = "",
    
        [Parameter(HelpMessage = "SchemaName of the primary name field. If not set, defaults to <SchemaName>Name.")]
        [ValidatePattern('^$|^[a-zA-Z0-9_]+_[a-zA-Z0-9_]+$')]
        [string]$PrimaryNameFieldSchema = "",
    
        [Parameter(HelpMessage = "Display name of the primary name field. If not set, defaults to 'Name'.")]
        [string]$PrimaryNameFieldDisplayName = "",
    
        [Parameter(HelpMessage = "Optional description of the primary name field.")]
        [string]$PrimaryNameFieldDescription = "",

        [Parameter(HelpMessage = "Maximum length for the primary name field (1-4000). Default: 100.")]
        [ValidateRange(1,4000)]
        [int]$PrimaryNameFieldMaxLength = 100,

        [Parameter(HelpMessage = "Requirement level for the primary name field (None, Recommended, ApplicationRequired). Default: None.")]
        [ValidateSet("None","Recommended","ApplicationRequired")]
        [string]$PrimaryNameFieldRequiredLevel = "None",

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

.PARAMETER PrimaryNameFieldSchema
    Optional. SchemaName of the primary name field.
    Default: {TableSchemaName}Name (e.g., if table is "new_Project", this becomes "new_ProjectName")
    IMPORTANT: The primary name field is the main identifier for records and cannot be changed after table creation.

.PARAMETER PrimaryNameFieldDisplayName
    Optional. Display name for the primary name field shown in the UI.
    Default: "Name"
    Example: "Project Name", "Case Title", "Contact Name"

.PARAMETER PrimaryNameFieldDescription
    Optional. Description for the primary name field shown in metadata.
    Default: "Primary name for {DisplayName}"

.PARAMETER PrimaryNameFieldMaxLength
    Maximum length for the primary name field. Range 1-4000. Default is 100.

.PARAMETER PrimaryNameFieldRequiredLevel
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
        -PrimaryNameFieldMaxLength 200 -PrimaryNameFieldRequiredLevel ApplicationRequired `
        -EnableAuditing

.EXAMPLE
    New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_customactivity" `
        -DisplayName "Custom Activity" -DisplayPluralName "Custom Activities" `
        -IsActivityTable -EnableActivities

.EXAMPLE
    New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_product" `
        -DisplayName "Product" -DisplayPluralName "Products" `
        -PrimaryNameFieldSchema "new_ProductCode" `
        -PrimaryNameFieldDisplayName "Product Code" `
        -PrimaryNameFieldDescription "Unique identifier for the product" `
        -PrimaryNameFieldMaxLength 50 `
        -PrimaryNameFieldRequiredLevel ApplicationRequired

    Creates a table with a customized primary name field called "Product Code" that is required
    and limited to 50 characters. Without these parameters, the primary field would default to
    "new_ProductName" with display name "Name" and 100 character length.

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
    -PrimaryNameFieldSchema, -PrimaryNameFieldDisplayName, -PrimaryNameFieldMaxLength,
    -PrimaryNameFieldRequiredLevel

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-entity
#>

    # Set default values for primary name field if not specified
    if (-not $PrimaryNameFieldSchema -or $PrimaryNameFieldSchema.Trim() -eq "") {
        $PrimaryNameFieldSchema = $SchemaName + "Name"
    }
    if (-not $PrimaryNameFieldDisplayName -or $PrimaryNameFieldDisplayName.Trim() -eq "") {
        $PrimaryNameFieldDisplayName = "Name"
    }
    if (-not $PrimaryNameFieldDescription) {
        $PrimaryNameFieldDescription = "Primary name for $DisplayName"
    }

    # Build JSON body for the new table (EntityMetadata)
    $entity = [ordered]@{
        "@odata.type"             = "Microsoft.Dynamics.CRM.EntityMetadata"
        SchemaName                = $SchemaName
        DisplayName               = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $DisplayName
                LanguageCode  = 1033
            })
        }
        DisplayCollectionName     = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $DisplayPluralName
                LanguageCode  = 1033
            })
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
                SchemaName       = $PrimaryNameFieldSchema
                DisplayName      = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    "LocalizedLabels" = @(@{
                        "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                        Label         = $PrimaryNameFieldDisplayName
                        LanguageCode  = 1033
                    })
                }
                Description      = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    "LocalizedLabels" = @(@{
                        "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                        Label         = $PrimaryNameFieldDescription
                        LanguageCode  = 1033
                    })
                }
                MaxLength        = $PrimaryNameFieldMaxLength
                FormatName       = @{ Value = "Text" }
                RequiredLevel    = @{
                    Value                         = $PrimaryNameFieldRequiredLevel
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
    # Use MSCRM.SolutionUniqueName header if the table should be created inside a specific solution (optional)
    # $headers["MSCRM.SolutionUniqueName"] = "<solution_unique_name>"

    $url = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions"
    try {
        Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ErrorAction Stop
        Write-Host "Dataverse table '$DisplayName' created (SchemaName: $SchemaName)."
    }
    catch {
        Throw "Could not create table '$SchemaName'. Error: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function New-XbDVTable 

# Example: Create a new custom table "Project" (user-owned) with notes and auditing enabled
# New-XbDVTable -EnvironmentUrl $envUrl -SchemaName "new_Project" -DisplayName "Project" `
#    -DisplayPluralName "Projects" -Description "Table for managing projects" `
#    -PrimaryNameFieldMaxLength 200 -PrimaryNameFieldRequiredLevel ApplicationRequired `
#    -EnableNotes -EnableAuditing -EnableDuplicateDetection
