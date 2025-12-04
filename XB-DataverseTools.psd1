@{
    RootModule        = 'XB-DataverseTools.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'eb7a4d3c-67ce-45bf-858c-e5d5f72d7214'
    Author            = 'Kristian Holm Buch'
    CompanyName       = 'NexaBlue'
    Copyright         = '(c) 2025 - Kristian Holm Buch. All rights reserved.'
    Description       = 'Enterprise Dataverse Automation Toolkit for PowerShell'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = @(
        'Connect-XbDataverse',
        'Get-XbPPEnvironments',
        'Get-XbDVData',
        'New-XbDVRecord',
        'Update-XbDVRecord',
        'New-XbDVTable',
        'Remove-XbDVTable',
        'New-XbDVColumn',
        'New-XbDVChoice',
        'Get-XbDVTableMetadata'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    HelpInfoUri       = 'https://github.com/kristianbuch/XB-DataverseTools'
    PrivateData       = @{
        PSData = @{
            Tags = @('Dataverse', 'PowerPlatform', 'CDS', 'REST', 'Metadata')
            ProjectUri = 'https://github.com/kristianbuch/XB-DataverseTools'
        }
    }
}