function Get-DVTableMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$TableLogicalName,  # table name (logical name, e.g., 'account')
        [string]$AccessToken
    )
    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    }
    # Retrieve table metadata including all fields (attributes) and relevant properties
    $metaUrl = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions(LogicalName='$TableLogicalName')?`$expand=Attributes(`$select=LogicalName,AttributeType,IsValidForUpdate,IsValidForCreate,RequiredLevel,Description`)&`$select=LogicalName"
    try {
        $entityMeta = Invoke-RestMethod -Method GET -Uri $metaUrl -Headers $headers -ErrorAction Stop
    }
    catch {
        Throw "Could not retrieve metadata for '$TableLogicalName'. Error: $($_.Exception.Message)"
    }
    # Build list of field information
    $fields = @()
    foreach ($attr in $entityMeta.Attributes) {
        $fieldName    = $attr.LogicalName
        $fieldType    = $attr.AttributeType        # e.g., 'String', 'Integer', 'Picklist', 'Lookup', etc.
        # RequiredLevel is a complex type (ManagedProperty); we check its Value
        $reqLevelVal  = $attr.RequiredLevel.Value
        $isRequired   = ($reqLevelVal -eq 'ApplicationRequired' -or $reqLevelVal -eq 'SystemRequired')  # true if field is required
        $isEditable   = $attr.IsValidForUpdate     # true if the value can be updated (non-editable fields will be false)
        # Description: use the user's localized label if available, otherwise blank
        $desc = ""
        if ($attr.Description) {
            if ($attr.Description.UserLocalizedLabel) {
                $desc = $attr.Description.UserLocalizedLabel.Label
            } elseif ($attr.Description.LocalizedLabels) {
                $desc = ($attr.Description.LocalizedLabels | Select-Object -First 1).Label
            }
        }
        $fields += [PSCustomObject]@{
            FieldName    = $fieldName
            Type         = $fieldType
            Required     = if ($isRequired) { $true } else { $false }
            Editable     = if ($isEditable) { $true } else { $false }
            Description  = $desc
        }
    }
    return $fields
}

# Example: Retrieve metadata for the 'contact' table and display selected fields
# $contactFields = Get-DVTableMetadata -EnvironmentUrl $environments[0].EnvironmentUrl -TableLogicalName "contact"
# $contactFields | Where-Object Required -eq $true | Format-Table FieldName, Type, Description
