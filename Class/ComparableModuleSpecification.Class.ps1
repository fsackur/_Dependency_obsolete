class ComparableModuleSpecification : EquatableModuleSpecification, IComparable
{
    <#
        .SYNOPSIS
        This class gives us module specification objects that can be sorted. Sorting is on Name, then Version.

        .EXAMPLE
        $Module1 = [ComparableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.8.6'}
        $Module2 = [ComparableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.8.6'}
        $Module3 = [ComparableModuleSpecification]@{ModuleName = 'DBATools'; ModuleVersion = '0.9.3'}
        $Module4 = [ComparableModuleSpecification]@{ModuleName = 'PoshRSJob'; ModuleVersion = '0.9.3'}
        $Module1, $Module2, $Module3, $Module4 | Sort-Object -Descending -Unique

        Name      Version
        ----      -------
        PoshRSJob 0.9.3
        DBATools  0.9.3
        DBATools  0.8.6
    #>

    # Constructors
    ComparableModuleSpecification ([string]$Name) : base (@{ModuleName = $Name; ModuleVersion = '0.0.0.0'}) {}
    ComparableModuleSpecification ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}
    ComparableModuleSpecification ([Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec) : base (  #have to chain base ctor because properties are read-only
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


    # Implement IComparable. This allows comparison operators to work as expected.
    [int] CompareTo ([Object]$obj)
    {
        if ($Obj -isnot $this.GetType())
        {
            throw New-Object System.ArgumentException ("The type '$($Obj.GetType())' of comparison object '$Obj' is not the same as '$($this.GetType())'.")
        }

        if ($this.Name -inotlike $Obj.Name)
        {
            if ($this.Guid -and $Obj.Guid -and $this.Guid -ne $Obj.Guid)
            {
                throw New-Object System.ArgumentException ("The GUID '$($Obj.Guid)' of comparison object '$Obj' is not the same as '$($this.Guid)'.")
            }

            return $this.Name.ToLower().CompareTo($Obj.Name.ToLower())
        }
        else
        {
            return $this.Version.CompareTo($Obj.Version)
        }
    }
}