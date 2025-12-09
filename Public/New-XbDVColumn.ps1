function New-XbDVColumn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com\/?$')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,
    
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Logical name of the target table, e.g., 'account'")]
        [Alias('Entity', 'LogicalName')]
        [ValidateNotNullOrEmpty()]
        [string]$TableLogicalName,
    
        [Parameter(Mandatory = $true, HelpMessage = "SchemaName for the new column (with prefix, e.g., 'new_FieldName')")]
        [ValidatePattern('^[a-zA-Z0-9_]+_[a-zA-Z0-9_]+$')]
        [ValidateNotNullOrEmpty()]
        [string]$SchemaName,
    
        [Parameter(Mandatory = $true, HelpMessage = "Display name for the new field shown in the UI")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,
    
        [Parameter(HelpMessage = "Optional description for the field shown in metadata and UI")]
        [string]$Description = "",
    
        [Parameter(Mandatory = $true, HelpMessage = "Type of the new field (Text, Memo, Integer, Decimal, Boolean, Date, DateTime, etc.)")]
        [ValidateSet("Text","Memo","Integer","Decimal","Boolean","Date","DateTime","Choice","MultiChoice","Lookup", "Polymorph","Customer")]
        [string]$Type,
    
        [Parameter(HelpMessage = "Requirement level for the column (None, Recommended, ApplicationRequired, SystemRequired). Default: None.")]
        [ValidateSet("None","Recommended","ApplicationRequired","SystemRequired")]
        [string]$RequiredLevel = "None",
    
        [Parameter(HelpMessage = "Maximum length for text-based fields (Text/Memo). Default: 100.")]
        [ValidateRange(1,1048576)]
        [int]$MaxLength = 100,
    
        [Parameter(HelpMessage = "Decimal precision for number fields. Default: 2.")]
        [ValidateRange(0,10)]
        [int]$Precision = 2,
    
        [Parameter(HelpMessage = "Label for 'true' value on Boolean fields. Default: Yes.")]
        [string]$TrueLabel = "Yes",
    
        [Parameter(HelpMessage = "Label for 'false' value on Boolean fields. Default: No.")]
        [string]$FalseLabel = "No",
    
        [Parameter(HelpMessage = "List of labels to create a local option set (used with Choice or MultiChoice).")]
        [string[]]$Choices,
    
        [Parameter(HelpMessage = "Name of an existing global option set to reference (used with Choice or MultiChoice).")]
        [string]$GlobalOptionSetName,
    
        [Parameter(HelpMessage = "Target entity for Lookup (e.g., 'account','contact').")]
        [string]$Lookup,

        [Parameter(HelpMessage = "Plural Display name of Reference entity for Lookup.")]
        [string]$CollectionName,

        [Parameter(HelpMessage = "Unique name of the solution to add this column to (e.g., 'MyCustomSolution'). If not specified, column is added to the default solution.")]
        [string]$SolutionUniqueName,

        [Parameter(HelpMessage = "OAuth 2.0 bearer token. If not provided, assumes the session is authenticated.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
    )    
<#
.SYNOPSIS
    Creates a new custom column (field) on a Dataverse table via the Web API.

.DESCRIPTION
    This function provisions a new custom attribute (column) on a Dataverse table using the v9.2 REST API.
    It supports multiple field types (Text, Memo, Integer, Decimal, Boolean, Date, DateTime, Choice, MultiChoice, Lookup, Customer)
    and automatically builds valid metadata payloads, including display name, description, and required level.
    Supports both local and global option sets for choice fields, and target entity configuration for lookups.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment (e.g., 'https://org.crm4.dynamics.com').

.PARAMETER TableLogicalName
    The logical name of the entity/table where the column should be created (e.g., 'account', 'contact').

.PARAMETER SchemaName
    The schema name of the new column. Must include a valid prefix (e.g., 'new_FieldName').

.PARAMETER DisplayName
    The display name of the field as seen in the UI.

.PARAMETER Description
    Optional. A description of the column to be shown in metadata and UI.

.PARAMETER Type
    The data type of the column. Supported types:
    - Text, Memo, Integer, Decimal, Boolean, Date, DateTime, Choice, MultiChoice, Lookup, Customer

.PARAMETER RequiredLevel
    The requirement level for the column. Options:
    - None: Field is completely optional (default)
    - Recommended: Field shows a blue + icon, suggesting users fill it in but not enforced
    - ApplicationRequired: Field must be filled in before the record can be saved
    - SystemRequired: Reserved for system fields (rarely used for custom fields)

.PARAMETER MaxLength
    Applicable for Text and Memo fields. Maximum allowed: 4000 for Text, 1M for Memo. Default is 100.

.PARAMETER Precision
    Applicable for Decimal fields. Sets number of decimal places. Range 0-10. Default is 2.

.PARAMETER TrueLabel
    For Boolean fields. The label used when the value is true. Default is "Yes".

.PARAMETER FalseLabel
    For Boolean fields. The label used when the value is false. Default is "No".

.PARAMETER Choices
    For Choice or MultiChoice fields. A list of label strings for creating a local option set.

.PARAMETER GlobalOptionSetName
    Optional. If provided, the column will reference an existing global option set by name.

.PARAMETER Lookup
    For Lookup or Customer fields. The logical name of the entity that this field references (e.g., "account", "contact").

.PARAMETER SolutionUniqueName
    Optional. Unique name of the solution to add this column to during creation.
    If not specified, the column is added to the default solution (Common Data Services Default Solution).
    The solution must already exist in the environment.
    Example: "MyCustomSolution", "CoreComponents"

.PARAMETER AccessToken
    Optional. OAuth 2.0 bearer token. If not provided, the function assumes the session is pre-authenticated.

.EXAMPLE
    New-XbDVColumn -EnvironmentUrl "https://org.crm4.dynamics.com" -TableLogicalName "contact" `
        -SchemaName "new_IndustryCode" -DisplayName "Industry Code" -Description "Code for vertical" `
        -Type Text -MaxLength 50 -RequiredLevel ApplicationRequired

.EXAMPLE
    New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "incident" `
        -SchemaName "new_Priority" -DisplayName "Priority" -Type Choice `
        -Choices @("Low","Medium","High")

.EXAMPLE
    New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "account" `
        -SchemaName "new_Notes" -DisplayName "Internal Notes" -Type Memo `
        -MaxLength 2000 -RequiredLevel Recommended

.EXAMPLE
    New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "new_caseplan" `
        -SchemaName "new_PrimaryContact" -DisplayName "Primary Contact" `
        -Type Lookup -Lookup  contact - CollectionName "Contacts"

.EXAMPLE
    New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "new_inventory" `
        -SchemaName "new_Location" -DisplayName "Warehouse Location" `
        -Type Text -MaxLength 100 `
        -SolutionUniqueName "WarehouseManagement"

    Creates a column and adds it to the "WarehouseManagement" solution.

.INPUTS
    None

.OUTPUTS
    None. Writes success or error messages to the host.

.NOTES
    Author      : Kristian Holm Buch
    Version     : 1.0
    Date        : 2025-05-04
    Editor      : PowerShell Studio 2025
    License     : CC BY-NC-ND 4.0
    Copyright   : (c) 2025 - Kristian Holm Buch. All Rights Reserved.

.LINK
    https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-entity-attribute
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

    # Build RequiredLevel metadata object
    $reqLevel = @{
        Value = $RequiredLevel
        CanBeChanged = $true
        ManagedPropertyLogicalName = "canmodifyrequirementlevelsettings"
    }

    $url = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions(LogicalName='$TableLogicalName')/Attributes"
    # Build attribute JSON based on selected type
    $attributeMetadata = @{}
    switch ($Type) {
        "Text" {
            # Single-line field (text, max 4000 characters)
            if ($MaxLength -gt 4000) { $MaxLength = 4000 }
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                MaxLength        = $MaxLength
                FormatName       = @{ Value = "Text" }
                AttributeType    = "String"
            }
        }
        "Memo" {
            # Multi-line field (memo, up to 1,048,576 characters)
            if ($MaxLength -lt 256) { $MaxLength = 1000 }
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.MemoAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                Format           = "TextArea"
                MaxLength        = $MaxLength
                AttributeType    = "Memo"
            }
        }
        "Integer" {
            # Whole number field (32-bit integer)
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                Format           = "None"
                MinValue         = -2147483648
                MaxValue         = 2147483647
                AttributeType    = "Integer"
            }
        }
        "Decimal" {
            # Decimal number (floating-point with specified precision)
            if ($Precision -lt 0) { $Precision = 0 }
            if ($Precision -gt 10) { $Precision = 10 }
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.DecimalAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                MinValue         = -100000000000
                MaxValue         = 100000000000
                Precision        = $Precision
                AttributeType    = "Decimal"
            }
        }
        "Boolean" {
            # Two-state field (yes/no)
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.BooleanAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                AttributeType    = "Boolean"
                OptionSet        = @{
                    TrueOption   = @{ Value = 1; Label = New-Label $TrueLabel }
                    FalseOption  = @{ Value = 0; Label = New-Label $FalseLabel }
                    OptionSetType = "Boolean"
                }
            }
        }
        "Date" {
            # Date-only field (DateOnly behavior)
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                Format           = "DateOnly"  #Date Only
                AttributeType    = "DateTime"
            }
        }
        "DateTime" {
            # Date and time field (UserLocal behavior)
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                Format           = "DateAndTime"  #DateAndTime
                AttributeType    = "DateTime"
            }
        }
        "Choice" {
            # Single-select Option Set (Picklist)
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                AttributeType    = "Picklist"
            }
            if ($GlobalOptionSetName) {
                $attributeMetadata["OptionSet"] = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
                    Name          = $GlobalOptionSetName
                }
            }
            elseif ($Choices) {
                $attributeMetadata["OptionSet"] = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
                    Options       = @()
                    OptionSetType = "Picklist"
                }
                $value = 1
                foreach ($choiceLabel in $Choices) {
                    $attributeMetadata["OptionSet"]["Options"] += @{
                        Value = $value
                        Label = New-Label $choiceLabel
                    }
                    $value++
                }
            }
        }
        "MultiChoice" {
            # Multi-select Option Set (MultiSelectPicklist)
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.MultiSelectPicklistAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                AttributeType    = "Virtual"
                AttributeTypeName = @{ Value = "MultiSelectPicklistType" }
            }
            if ($GlobalOptionSetName) {
                $attributeMetadata["OptionSet"] = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
                    Name          = $GlobalOptionSetName
                }
            }
            elseif ($Choices) {
                $attributeMetadata["OptionSet"] = @{
                    "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
                    Options       = @()
                    OptionSetType = "Picklist"
                }
                $value = 1
                foreach ($choiceLabel in $Choices) {
                    $attributeMetadata["OptionSet"]["Options"] += @{
                        Value = $value
                        Label = New-Label $choiceLabel
                    }
                    $value++
                }
            }
        }
        "Lookup" {
            # Lookup field (reference to another table)
            if (-not $Lookup) {
                Throw "Lookup must be specified for the Lookup column."
            }
            $attributeMetadata = 
                @{
                    SchemaName       = $SchemaName + "_" + $TableLogicalName
                    "@odata.type"    = "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata"
                    AssociatedMenuConfiguration = @{
                        Behavior = "UseCollectionName"
                        Group    = "Details"
                        Label    = New-Label $CollectionName
                        Order    = 10000
                    }
                    CascadeConfiguration = @{
                        Assign     = "Cascade"
                        Delete     = "Cascade"
                        Merge      = "Cascade"
                        Reparent   = "Cascade"
                        Share      = "Cascade"
                        Unshare    = "Cascade"
                    }
                    ReferencedAttribute = "${Lookup}id"  #GUID attribute of the target entity
                    ReferencedEntity = $Lookup
                    ReferencingEntity = $TableLogicalName
                    Lookup         = @{AttributeType = "Lookup" 
                        AttributeTypeName = @{Value="LookupType"}
                        Description      = New-Label $Description
                        DisplayName      = New-Label $DisplayName
                        RequiredLevel    = $reqLevel
                        SchemaName       = $SchemaName
                        "@odata.type"    = "Microsoft.Dynamics.CRM.LookupAttributeMetadata"
                    }
                }
            $url = "$EnvironmentUrl/api/data/v9.2/RelationshipDefinitions"
        }
        "Polymorphic" {
            # polymorphic Lookup field (reference other tables)
            if (-not $ReferencedTables -or $ReferencedTables.Count -eq 0) {
                Throw "ReferencedTables must be specified for the Polymorphic column."
            }
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.LookupAttributeMetadata"
                SchemaName       = "$TableLogicalName_" + $Lookup.Substring(4)+"_$SchemaName"
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                AttributeType    = "Lookup"
                OneToManyRelationships = $ReferencedTables
            }
            #Polymorphic lookup creation uses a different endpoint
            $url = "$EnvironmentUrl/api/data/v9.2/CreatePolymorphicLookupAttribute"
        }
        "Customer" {
            # Customer lookup field (special type typically referencing Account/Contact)
            if (-not $Lookup -or $Lookup.Count -lt 2) {
                Throw "Specify two entities (e.g., account and contact) in Lookup for a Customer column."
            }
            $attributeMetadata = @{
                "@odata.type"    = "Microsoft.Dynamics.CRM.CustomerAttributeMetadata"
                SchemaName       = $SchemaName
                DisplayName      = New-Label $DisplayName
                Description      = New-Label $Description
                RequiredLevel    = $reqLevel
                AttributeType    = "Lookup"
                Targets          = $Lookup
            }
        }
    }

    # Convert metadata hashtable to JSON
    $jsonBody = ($attributeMetadata | ConvertTo-Json -Depth 15)
    Write-Host $jsonBody
    #return
    # HTTP call to create the column on the table
    $url = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions(LogicalName='$TableLogicalName')/Attributes"
    $headers = @{
        Accept = 'application/json; charset=utf-8'
        "Content-Type" = 'application/json; charset=utf-8'
    }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }
    # Add column to specific solution if specified
    if ($SolutionUniqueName) {
        $headers["MSCRM.SolutionUniqueName"] = $SolutionUniqueName
    }
    try {
        Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $jsonBody -ErrorAction Stop
        Write-Host "New column '$DisplayName' (Type: $Type) created on $TableLogicalName."
    }
    catch {
        Throw "Could not create column '$SchemaName' on $TableLogicalName. Error: $($_.Exception.Message)"
    }
    return $jsonBody
}
Export-ModuleMember -Function New-XbDVColumn

# Examples:
# 1. Add a new required text field "Project Code" (max 50 chars) to custom table 'new_project'
# New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "new_project" -SchemaName "new_ProjectCode" `
#    -DisplayName "Project Code" -Description "Unique project code" -Type Text -MaxLength 50 -RequiredLevel ApplicationRequired
#
# 2. Add a Choice field "Priority" with three local option values
# New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "incident" -SchemaName "new_Priority" `
#    -DisplayName "Priority" -Type Choice -Choices @("Low","Medium","High")
#
# 3. Add a Lookup field "Primary Contact" on a custom 'AccountPlan' table pointing to Contact
# New-XbDVColumn -EnvironmentUrl $envUrl -TableLogicalName "new_accountplan" -SchemaName "new_PrimaryContact" `
#    -DisplayName "Primary Contact" -Type Lookup -Lookup @("contact") - CollectionName "Contacts"
