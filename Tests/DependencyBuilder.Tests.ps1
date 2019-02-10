using namespace Microsoft.PowerShell.Commands
using module ..\Class\ModuleSpec.Class.psm1
using module ..\Class\ModuleFetcher.Class.psm1
using module ..\Class\DependencyBuilder.Class.psm1

Describe "DependencyBuilder" {

    $TestModulePath = "TestDrive:\TestModules"
    $null = New-Item $TestModulePath -ItemType Directory -ErrorAction Stop

    function New-MockModule
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory, Position = 0)]
            [ModuleSpecification]$Spec,

            [ModuleSpecification[]]$Required
        )

        $Name = $Spec.Name
        $Version = $Spec.Version
        $Base = Join-Path $TestModulePath $Name
        $Path = Join-Path $Base "$Name.psd1"
        $null = New-Item $Base -ItemType Directory -ErrorAction Stop

        $RequiredString = $Required.Foreach({
            '@{',
            (
                ($Spec | Out-String -Stream)        `
                    -match ':\s\S'                  `
                    -replace '^(?=[^M])', 'Module'  `
                    -replace ': ', '= "'            `
                    -replace '$', '"'               `
                    -replace '\s+', ' '             `
                    -join '; '
            ),
            '}' -join ''
        }) -join ', '

        "@{ModuleVersion = '$Version'; RequiredModules = @($RequiredString)}" |
            Out-File $Path -Force
    }

    $Specs = @{}
    1..10 | ForEach-Object {
        $Name = "m$_"
        $Spec = [ModuleSpecification]@{
            ModuleName    = $Name
            ModuleVersion = "1.0.$(Get-Random -Minimum 0 -Maximum 9)"
        }
        $Specs[$_] = $Spec
    }


    New-MockModule $Specs[1]

    $Fetcher = [FileSystemModuleFetcher]::new($TestModulePath)
    $Builder = [DependencyBuilder]::new($Fetcher)
    $Tree = $Builder.GetDependencies($Specs[1])

    It "Builds a single-node tree" {
        $Tree | Should -BeOfType "ModuleSpec"
        $Tree.Parent | Should -BeNullOrEmpty
        $Tree.Children | Should -BeNullOrEmpty
    }

    New-MockModule $Specs[2] -Required $Specs[3], $Specs[4]
    New-MockModule $Specs[3]
    New-MockModule $Specs[4] -Required $Specs[5]
    New-MockModule $Specs[5]

    $Tree = $Builder.GetDependencies($Specs[2])

    It "Builds a multi-node tree" {
        $Tree | Should -BeOfType "ModuleSpec"
        $Tree.Parent | Should -BeNullOrEmpty
        $Tree.Children.Count | Should -Be 2
        $Tree.Children[0].Children[0] | Should -BeNullOrEmpty
        $Tree.Children[1].Children[0] | Should -BeOfType "ModuleSpec"
    }
}