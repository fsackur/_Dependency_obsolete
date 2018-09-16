class EquatableModuleSpecification : Microsoft.PowerShell.Commands.ModuleSpecification, IEquatable[EquatableModuleSpecification]
{
    # Constructors
    EquatableModuleSpecification ([string]$Name) : base (@{ModuleName = $Name; ModuleVersion = '0.0.0.0'}) {}
    EquatableModuleSpecification ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}
    EquatableModuleSpecification ([Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec) : base (  # have to chain base ctor because properties are read-only
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
        $ComparisonObj = $Obj -as [EquatableModuleSpecification]
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
    [bool] Equals([EquatableModuleSpecification]$ComparisonObj)     # Base type does not have useful ToString()
    {
        return $this.ToString() -ilike $ComparisonObj.ToString()
    }
}