using namespace Microsoft.PowerShell.Commands
using namespace System.Management.Automation
using module ..\Class\DependencyBuilder.Class.psm1
using module ..\Class\ModuleFetcher.Class.psm1
using module ..\Class\ModuleSpec.Class.psm1


Describe "DependencyBuilder" {

    class MockFetcher : ModuleFetcher
    {
        MockFetcher () {}

        [PSModuleInfo] GetModule ([ModuleSpecification]$ModuleSpec)
        {
            $Global:FetcherMethodHitCount++

            $Module = Get-Module -FullyQualifiedName $ModuleSpec |
                Sort-Object Version |
                Select-Object -First 1

            if ($Module)
            {
                Write-Debug "Found module '$Module'."
                return $Module[0]
            }
            else
            {
                throw ([ItemNotFoundException]::new("No mock modules were found matching argument '$ModuleSpec'."))
            }
        }
    }


    #region setup globals
    $Global:Name1 = 'Cat'
    $Global:Name2 = 'Dog'
    $Global:Name3 = 'Flea'

    $Global:Version1 = '1.2.3'
    $Global:Version2 = '4.5.6'
    $Global:Version3 = '7.8.9'


    $CatSpec = [ModuleSpec]@{
        ModuleName    = 'Cat'
        ModuleVersion = $Version1
    }
    $DogSpec = [ModuleSpec]@{
        ModuleName    = 'Dog'
        ModuleVersion = $Version2
    }
    $FleaSpec1 = [ModuleSpec]@{
        ModuleName    = 'Flea'
        ModuleVersion = $Version1
    }
    $FleaSpec2 = [ModuleSpec]@{
        ModuleName    = 'Flea'
        ModuleVersion = $Version2
    }
    $FleaSpec3 = [ModuleSpec]@{
        ModuleName    = 'Flea'
        ModuleVersion = $Version3
    }


    $TestModulePath = "TestDrive:\TestModules"
    $null      = New-Item $TestModulePath -ItemType Directory -ErrorAction Stop
    $CatPath   = New-Item $TestModulePath\Cat -ItemType Directory -ErrorAction Stop
    $DogPath   = New-Item $TestModulePath\Dog -ItemType Directory -ErrorAction Stop
    $FleaPath  = New-Item $TestModulePath\Flea -ItemType Directory -ErrorAction Stop
    $null      = New-Item $TestModulePath\Flea\$Version1 -ItemType Directory -ErrorAction Stop
    $null      = New-Item $TestModulePath\Flea\$Version2 -ItemType Directory -ErrorAction Stop

    # Cat
    "@{
        ModuleVersion   = '$Version1'
        RequiredModules = @(
            @{
                ModuleName    = 'Dog'
                ModuleVersion = '$Version2'
            },
            @{
                ModuleName    = 'Flea'
                ModuleVersion = '$Version1'
            }
        )
    }" | Out-File $CatPath\Cat.psd1

    # Dog
    "@{
        ModuleVersion   = '$Version2'
        RequiredModules = @(
            @{
                ModuleName    = 'Flea'
                ModuleVersion = '$Version2'
            }
        )
    }" | Out-File $DogPath\Dog.psd1

    # Flea 1.2.3
    "@{
        ModuleVersion   = '$Version1'
        RequiredModules = @()
    }" | Out-File $FleaPath\$Version1\Flea.psd1

    # Flea 4.5.6
    "@{
        ModuleVersion   = '$Version2'
        RequiredModules = @()
    }" | Out-File $FleaPath\$Version2\Flea.psd1


    Import-Module $FleaPath -RequiredVersion $Version1 -Global
    Import-Module $FleaPath -RequiredVersion $Version2 -Global
    Import-Module $DogPath -Global
    Import-Module $CatPath -Global
    #endregion setup globals


    $Fetcher = [MockFetcher]::new()
    $Builder = [DependencyBuilder]::new($Fetcher)


    $Global:FetcherMethodHitCount = 0
    $Result = $Builder.GetDependencies($FleaSpec1)

    It "Builds a single-node tree" {
        $Result.Name | Should -Be 'Flea'
        $Result.Version | Should -Be $Version1
        $Result.Parent | Should -BeNullOrEmpty
        $Result.Children | Should -BeNullOrEmpty

        $Global:FetcherMethodHitCount | Should -Be 1
    }


    $Global:FetcherMethodHitCount = 0
    $Result = $Builder.GetDependencies($CatSpec)

    It "Builds a multi-node tree" {
        $Result.Name | Should -Be 'Cat'
        $Result.Version | Should -Be $Version1
        $Result.Parent | Should -BeNullOrEmpty
        $Result.Children.Count | Should -Be 2

        $Result.Children[0].Name | Should -Be 'Dog'
        $Result.Children[0].Version | Should -Be $Version2
        $Result.Children[0].Parent.Name | Should -Be 'Cat'
        $Result.Children[0].Parent.Version | Should -Be $Version1
        $Result.Children[0].Children.Count | Should -Be 1

        $Result.Children[1].Name | Should -Be 'Flea'
        $Result.Children[1].Version | Should -Be $Version1
        $Result.Children[1].Parent.Name | Should -Be 'Cat'
        $Result.Children[1].Parent.Version | Should -Be $Version1
        $Result.Children[1].Children | Should -BeNullOrEmpty

        $Result.Children[0].Children[0].Name | Should -Be 'Flea'
        $Result.Children[0].Children[0].Version | Should -Be $Version2
        $Result.Children[0].Children[0].Parent.Name | Should -Be 'Dog'
        $Result.Children[0].Children[0].Parent.Version | Should -Be $Version2

        $Global:FetcherMethodHitCount | Should -Be 4
    }


    $Global:FetcherMethodHitCount = 0

    It "Throws if it can't find a module" {
        {$Builder.GetDependencies($FleaSpec3)} | Should -Throw "No mock modules were found"

        $Global:FetcherMethodHitCount | Should -Be 1
    }


    $Global:FetcherMethodHitCount = 0
    Get-Module -FullyQualifiedName $FleaSpec2 | Remove-Module -Force

    It "Throws if it can't find a dependency module" {
        {$Builder.GetDependencies($CatSpec)} | Should -Throw "No mock modules were found"

        $Global:FetcherMethodHitCount | Should -Be 3
    }
}


# Cleanup
Get-Module Cat, Dog, Flea | Remove-Module -Force -ErrorAction SilentlyContinue
