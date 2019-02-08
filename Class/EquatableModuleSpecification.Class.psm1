using namespace Microsoft.PowerShell.Commands

class EquatableModuleSpecification : ModuleSpecification, IEquatable[ModuleSpecification]
{
    <#
        .SYNOPSIS
        This class gives us module specification objects that can be tested for equality.

        .EXAMPLE
        $Module1 = [EquatableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.8.6'}
        $Module2 = [EquatableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.8.6'}
        $Module1 -eq $Module2

        True

        .EXAMPLE
        $Module2 = [EquatableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.8.6'}
        $Module3 = [EquatableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.9.3'}
        $Module2 -eq $Module3

        False

        .EXAMPLE
        $Module3 = [EquatableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.9.3'}
        $Module4 = [EquatableModuleSpecification]@{ModuleName = 'PoshRSJob'; ModuleVersion = '0.9.3'}
        $Module3 -eq $Module4

        False
    #>

    # Constructors
    EquatableModuleSpecification ([string]$Name) : base (@{ModuleName = $Name; ModuleVersion = '0.0.0.0'}) {}
    EquatableModuleSpecification ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}
    EquatableModuleSpecification ([ModuleSpecification]$ModuleSpec) : base (  # have to chain base ctor because properties are read-only
        $(
            $Hashtable = @{
                ModuleName        = $ModuleSpec.Name
                Guid              = $ModuleSpec.Guid
                ModuleVersion     = $ModuleSpec.Version
                RequiredVersion   = $ModuleSpec.RequiredVersion
            }
            if ($ModuleSpec.MaximumVersion) {$Hashtable.MaximumVersion = $ModuleSpec.MaximumVersion}

            $Hashtable
        )
    ) {}

    # A module specification has either a Version or a RequiredVersion, but not both. This gets whichever it has.
    [version] GetVersion()
    {
        if ($this.RequiredVersion) {return [version]$this.RequiredVersion} else {return [version]$this.Version}
    }

    # Override method from Object
    [string] ToString() {
        return $this.Name, $this.GetVersion() -join ' '
    }

    # Override method from Object - important for equality testing
    [int] GetHashCode() {return $this.ToString().ToLower().GetHashCode()}

    # Override method from Object by testing for null and calling implementation of IEquatable
    [bool] Equals([System.Object]$Obj)
    {
        $ComparisonObj = $Obj -as [ModuleSpecification]
        if ($null -eq $ComparisonObj)
        {
            return $false
        }
        else
        {
            return $this.Equals($ComparisonObj)
        }
    }

    # Implement IEquatable
    [bool] Equals([ModuleSpecification]$ComparisonObj)
    {
        $C = [EquatableModuleSpecification]$ComparisonObj   # Base type does not have useful ToString()
        return $this.ToString() -ilike $ComparisonObj.ToString()
    }
}