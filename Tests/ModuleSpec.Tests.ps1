using module ..\Class\ModuleSpec.Class.psm1


$MockingClassesPath = Join-Path (Join-Path (Join-Path $PSScriptRoot MockingPSClassesPoC) module) MockingPSClassesPoC
try
{
    Import-Module $MockingClassesPath -ErrorAction Stop
}
catch [System.IO.FileNotFoundException]
{
    git submodule update --init --recursive
    Import-Module $MockingClassesPath -ErrorAction Stop
}


$Name1 = 'Cat'
$Name2 = 'Dog'
$Name3 = 'Flea'

$Version1 = '1.2.3'
$Version2 = '4.5.6'
$Version3 = '7.8.9'

$Guid1 = (New-Guid).Guid
$Guid2 = (New-Guid).Guid
$Guid3 = (New-Guid).Guid

$Module1 = [ModuleSpec]@{
    ModuleName    = $Name1
    ModuleVersion = $Version1
}
$Module2 = [ModuleSpec]@{
    ModuleName    = $Name2
    ModuleVersion = $Version2
}
$Module3 = [ModuleSpec]@{
    ModuleName    = $Name3
    ModuleVersion = $Version1
}
$Module3a = [ModuleSpec]@{
    ModuleName    = $Name3
    ModuleVersion = $Version3
}

$Module1.Children = $Module2, $Module3
$Module2.Parent   = $Module1
$Module3.Parent   = $Module1
$Module2.Children = @($Module3a)
$Module3a.Parent  = $Module2

$Tree = @'
Cat 1.2.3
    Dog 4.5.6
        Flea 7.8.9
    Flea 1.2.3
'@

Describe "ModuleSpec" {

    It "Outputs list, depth-first" {
        $List = $Module1.ToList()
        $List | Select-Object -ExpandProperty Name |
            Should -Be $Name1, $Name2, $Name3, $Name3
        $List | Select-Object -ExpandProperty Version |
            Should -Be $Version1, $Version2, $Version3, $Version1
    }

    It "Gets import order" {
        $ImportOrder = $Module1.GetModuleImportOrder()
        $ImportOrder | Select-Object -ExpandProperty Name |
            Should -Be $Name3, $Name3, $Name2, $Name1
        $ImportOrder | Select-Object -ExpandProperty Version |
            Should -Be $Version1, $Version3, $Version2, $Version1
    }

    It "Prints tree" {
        $Module1.PrintTree().Trim() | Should -BeExactly $Tree
    }


    $Module2.Children = @($Module3)

    It "Gets distinct list" {
        $DistinctList = $Module1.GetDistinctList()
        $DistinctList | Select-Object -ExpandProperty Name |
            Should -Be $Name1, $Name2, $Name3
        $DistinctList | Select-Object -ExpandProperty Version |
            Should -Be $Version1, $Version2, $Version1
    }

    It "Gets distinct import order" {
        $ImportOrder = $Module1.GetModuleImportOrder()
        $ImportOrder | Select-Object -ExpandProperty Name |
            Should -Be $Name3, $Name2, $Name1
        $ImportOrder | Select-Object -ExpandProperty Version |
            Should -Be $Version1, $Version2, $Version1
    }
}