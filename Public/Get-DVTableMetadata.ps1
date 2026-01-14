# Heritage: formerly XB-DataverseTools (NexaBlue)
function Get-DVTableMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$TableLogicalName,
        [string]$AccessToken
    )
    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }

    $metaUrl = "$EnvironmentUrl/api/data/v9.2/EntityDefinitions(LogicalName='$TableLogicalName')?`$expand=Attributes(`$select=LogicalName,AttributeType,IsValidForUpdate,IsValidForCreate,RequiredLevel,Description`)&`$select=LogicalName"
    try { $entityMeta = Invoke-RestMethod -Method GET -Uri $metaUrl -Headers $headers -ErrorAction Stop }
    catch { Throw "Could not retrieve metadata for '$TableLogicalName'. Error: $($_.Exception.Message)" }

    $fields = @()
    foreach ($attr in $entityMeta.Attributes) {
        $fieldName    = $attr.LogicalName
        $fieldType    = $attr.AttributeType
        $reqLevelVal  = $attr.RequiredLevel.Value
        $isRequired   = ($reqLevelVal -eq 'ApplicationRequired' -or $reqLevelVal -eq 'SystemRequired')
        $isEditable   = $attr.IsValidForUpdate
        $desc = ""
        if ($attr.Description) {
            if ($attr.Description.UserLocalizedLabel) { $desc = $attr.Description.UserLocalizedLabel.Label }
            elseif ($attr.Description.LocalizedLabels) { $desc = ($attr.Description.LocalizedLabels | Select-Object -First 1).Label }
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
Export-ModuleMember -Function Get-DVTableMetadata

# Example: Retrieve metadata for the 'contact' table
# $contactFields = Get-DVTableMetadata -EnvironmentUrl $environments[0].EnvironmentUrl -TableLogicalName "contact"
# $contactFields | Where-Object Required -eq $true | Format-Table FieldName, Type, Description
