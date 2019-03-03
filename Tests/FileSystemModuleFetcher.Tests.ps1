using module ..\Class\ModuleFetcher.Class.psm1
using module ..\Class\ModuleSpec.Class.psm1


Describe "FileSystemModuleFetcher" {

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
        ModuleVersion = $Version1
    }
    $FleaSpec1 = [ModuleSpec]@{
        ModuleName    = 'Flea'
        ModuleVersion = $Version1
    }
    $FleaSpec2 = [ModuleSpec]@{
        ModuleName    = 'Flea'
        ModuleVersion = $Version3
    }

    $TestModulePath = "TestDrive:\TestModules"
    $Global:CatPath = Join-Path $TestModulePath 'Cat'
    $Global:DogPath = Join-Path $TestModulePath 'Dog'
    #endregion setup globals


    Mock -ModuleName "ModuleFetcher.Class" Get-Module {
        if (-not $ListAvailable)
        {
            throw [ArgumentException]::new("Mock should be called with -ListAvailable.")}

        foreach ($n in $Name)
        {
            $ModuleBase = Split-Path $n
            $ModuleName = Split-Path $n -Leaf

            if ($ModuleBase -eq $Global:CatPath -and $ModuleName -in ('Cat', 'Flea'))
            {
                $Module = New-Module -Name $ModuleName {}
                [PSModuleInfo].GetField("_version", "Instance, NonPublic").SetValue($Module, [version]$Version1)
                [PSModuleInfo].GetField("_moduleBase", "Instance, NonPublic").SetValue($Module, $ModuleBase)
                return $Module
            }
            elseif ($ModuleBase -eq $Global:DogPath -and $ModuleName -in ('Dog', 'Flea'))
            {
                $Module = New-Module -Name $ModuleName {}
                [PSModuleInfo].GetField("_version", "Instance, NonPublic").SetValue($Module, [version]$Version2)
                [PSModuleInfo].GetField("_moduleBase", "Instance, NonPublic").SetValue($Module, $ModuleBase)
                return $Module
            }
        }

        throw [FileNotFoundException]::new("
            Mock sez: The specified module '$n' was not found.
        ".Trim())
    }


    $Fetcher = [FileSystemModuleFetcher]::new([string[]]@($CatPath, $DogPath))


    It "Returns first match from first search path" {
        $Module = $Fetcher.GetModule($CatSpec)
        $Module.Name | Should -Be 'Cat'
        $Module.ModuleBase | Should -Match 'Cat'
        Assert-MockCalled -ModuleName "ModuleFetcher.Class" Get-Module -Times 1 -Exactly

        $Module = $Fetcher.GetModule($FleaSpec1)
        $Module.Name | Should -Be 'Flea'
        $Module.ModuleBase | Should -Match 'Cat'
        Assert-MockCalled -ModuleName "ModuleFetcher.Class" Get-Module -Times 2 -Exactly
    }

    It "Searches subsequent paths if needed" {
        $Module = $Fetcher.GetModule($DogSpec)
        $Module.Name | Should -Be 'Dog'
        $Module.ModuleBase | Should -Match 'Dog'
        Assert-MockCalled -ModuleName "ModuleFetcher.Class" Get-Module -Times 3 -Exactly
    }

    It "Throws if version requirement is not met" {
        {$Fetcher.GetModule($FleaSpec2)} | Should -Throw "No modules were found"
    }
}
