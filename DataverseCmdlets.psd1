@{
    RootModule        = 'DataverseCmdlets.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'eb7a4d3c-67ce-45bf-858c-e5d5f72d7214'
    Author            = 'Kristian Holm Buch'
    CompanyName       = 'NexaBlue'
    Copyright         = '(c) 2025 - Kristian Holm Buch. All rights reserved.'
    Description       = 'Enterprise Dataverse cmdlets for PowerShell (DataverseCmdlets)'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = @(
        'Connect-Dataverse',
        'Get-PPEnvironments',
        'Get-DVData',
        'New-DVRecord',
        'Update-DVRecord',
        'New-DVTable',
        'Remove-DVTable',
        'New-DVColumn',
        'New-DVChoice',
        'New-DVPolymorphicLookup',
        'Get-DVTableMetadata'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    HelpInfoUri       = 'https://github.com/kristianbuch/DataverseCmdlets'
    PrivateData       = @{
        PSData = @{
            Tags = @('Dataverse', 'PowerPlatform', 'CDS', 'REST', 'Metadata')
            ProjectUri = 'https://github.com/kristianbuch/DataverseCmdlets'
        }
    }
}
