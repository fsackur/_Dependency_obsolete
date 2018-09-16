class EquatableModuleSpecification : Microsoft.PowerShell.Commands.ModuleSpecification, IEquatable[Microsoft.PowerShell.Commands.ModuleSpecification]
{
    # Constructor; just chains base ctor
    EquatableModuleSpecification ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}

    # 'Type accelerator' constructor; have to chain base ctor because properties are read-only
    EquatableModuleSpecification ([Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec) : base (
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

    [version] GetVersion()
    {
        if ($this.RequiredVersion) {return [version]$this.RequiredVersion} else {return [version]$this.Version}
    }

    # Override method from Object
    [string] ToString() {
        return $this.Name, $this.GetVersion() -join ' '
    }

    # Important for equality testing
    [int] GetHashCode() {return $this.ToString().ToLower().GetHashCode()}

    # Override method from Object by testing for null and calling implementation of IEquatable
    [bool] Equals([System.Object]$Obj)
    {
        $ComparisonObj = $Obj -as [Microsoft.PowerShell.Commands.ModuleSpecification]
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
    [bool] Equals([Microsoft.PowerShell.Commands.ModuleSpecification]$ComparisonObj)
    {
        return $this.ToString() -ilike $ComparisonObj.ToString()
    }
}