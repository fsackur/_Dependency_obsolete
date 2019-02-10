using module ..\Class\ComparableModuleSpecification.Class.psm1


$Name1 = 'Cat'
$Name2 = 'Dog'

$Version1 = '1.2.3'
$Version2 = '4.5.6'
$Version3 = '7.8.9'

$Guid1 = (New-Guid).Guid
$Guid2 = (New-Guid).Guid


Describe "ComparableModuleSpecification" {

    It "Allows sorting" {
        [ComparableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version3
        },
        [ComparableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version2
        },
        [ComparableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        },
        [ComparableModuleSpecification]@{
            ModuleName    = $Name2
            ModuleVersion = $Version3
        },
        [ComparableModuleSpecification]@{
            ModuleName    = $Name2
            ModuleVersion = $Version1
        } |
            Sort-Object |
            Select-Object -ExpandProperty Version |
            Should -Be $Version1, $Version2, $Version3, $Version1, $Version3
    }
}