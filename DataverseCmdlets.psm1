# Heritage: formerly XB-DataverseTools (NexaBlue)
# This module file auto-imports function scripts from the Public folder

# Auto-import all functions from Public folder
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse | ForEach-Object {
    try {
        . $_.FullName
    }
    catch {
        Write-Error "Failed to import function from $($_.FullName): $_"
    }
}
