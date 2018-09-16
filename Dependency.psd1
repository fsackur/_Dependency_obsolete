@{
    Description       = 'Build a tree of PS module dependencies.'
    ModuleToProcess   = 'Dependency.psm1'
    ModuleVersion     = '0.0.0.1'
    GUID              = '7606a4d7-c5c6-42a8-94ad-f5a9a30ca80f'

    Author            = 'Freddie Sackur'
    CompanyName       = 'dustyfox.uk'
    Copyright         = '(c) 2018 Freddie Sackur. All rights reserved.'
    PowerShellVersion = '5.0'

    ScriptsToProcess  = @(
        #'Class\EquatableModuleSpecification.Class.psm1',
        #'Class\ComparableModuleSpecification.Class.psm1',
        #'Class\ModuleTreeNode.Class.psm1'
    )
    RequiredModules   = @()
    FunctionsToExport = @(
        '*'
    )
    FormatsToProcess  = @('Dependency.Format.ps1xml')

    PrivateData = @{
        PSData = @{
            Tags = @('Module', 'Dependency', 'Dependencies')
        }
    }
}
