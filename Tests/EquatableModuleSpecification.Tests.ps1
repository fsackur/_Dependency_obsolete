using module ..\Class\EquatableModuleSpecification.Class.psm1


$Name1 = 'Cat'
$Name2 = 'Dog'

$Version1 = '1.2.3'
$Version2 = '4.5.6'
$Version3 = '7.8.9'

$Guid1 = (New-Guid).Guid
$Guid2 = (New-Guid).Guid


Describe "EquatableModuleSpecification" {

    It "Tests equality" {
        [EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        } -eq [EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        } | Should -Be $true

        [EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        } -eq [EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version2 #
        } | Should -Be $false

        [EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        } -eq [EquatableModuleSpecification]@{
            ModuleName    = $Name2 #
            ModuleVersion = $Version1
        } | Should -Be $false

        [EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
            Guid          = $Guid1
        } -eq [EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
            Guid          = $Guid2 #
        } | Should -Be $false
    }

    It "Tests that a module satisfies a specification" {

        # Version: version should be greater than or equal
        ([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        }) | Should -Be $true

        ([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version2
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1 #
        }) | Should -Be $true

        ([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version2 #
        }) | Should -Be $false

        # MaximumVersion: version should be less than or equal
        ([EquatableModuleSpecification]@{
            ModuleName     = $Name1
            ModuleVersion  = $Version1
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName     = $Name1
            MaximumVersion = $Version1 #
        }) | Should -Be $true

        ([EquatableModuleSpecification]@{
            ModuleName     = $Name1
            ModuleVersion  = $Version2
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName     = $Name1
            MaximumVersion = $Version1 #
        }) | Should -Be $false

        # RequiredVersion: version should be exactly equal
        ([EquatableModuleSpecification]@{
            ModuleName      = $Name1
            ModuleVersion   = $Version2
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName      = $Name1
            RequiredVersion = $Version1 #
        }) | Should -Be $false

        ([EquatableModuleSpecification]@{
            ModuleName      = $Name1
            ModuleVersion   = $Version1
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName      = $Name1
            RequiredVersion = $Version1 #
        }) | Should -Be $true

        # Names must match
        ([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName    = $Name2 #
            ModuleVersion = $Version1
        }) | Should -Be $false

        # Guids must match
        ([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
            Guid          = $Guid1
        }).MeetsSpec([EquatableModuleSpecification]@{
            ModuleName    = $Name1
            ModuleVersion = $Version1
            Guid          = $Guid2 #
        }) | Should -Be $false
    }
}