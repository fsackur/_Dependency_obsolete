class ComparableModuleSpecification : Microsoft.PowerShell.Commands.ModuleSpecification, IComparable, IEquatable[Microsoft.PowerShell.Commands.ModuleSpecification]
{
    [ComparableModuleSpecification[]] $Parent
    [ComparableModuleSpecification[]] $Children

    # Constructor; just chains base ctor
    ComparableModuleSpecification ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}

    ComparableModuleSpecification ([Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec) : base (
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


    # Override method from Object
    [string] ToString() {return $this.Name, $this.Version -join ' '}

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

    # List of all dependencies; reverse this to get a viable module import order
    [System.Collections.Generic.List[ComparableModuleSpecification]] ToList()
    {
        $List = [System.Collections.Generic.List[ComparableModuleSpecification]]::new()
        $List.Add($this)

        foreach ($Child in $this.Children)
        {
            $ChildList = $Child.ToList()
            if ($ChildList) {$List.AddRange([System.Collections.Generic.List[ComparableModuleSpecification]]$ChildList)}
        }

        return $List
    }

    # List with duplicates removed
    [System.Collections.Generic.List[ComparableModuleSpecification]] GetDistinctList()
    {
        return [System.Collections.Generic.List[ComparableModuleSpecification]]($this.ToList() | Select-Object -Unique)
    }

    # List with duplicates removed and in reverse order
    [System.Collections.Generic.List[ComparableModuleSpecification]] GetModuleImportOrder()
    {
        return $this.GetDistinctList().Reverse()
    }

    # Visual output with dependencies indented
    [string] PrintTree([string]$Indentation = "")
    {
        $SB = New-Object System.Text.StringBuilder (200)
        $null = $SB.Append($Indentation).AppendLine($this.ToString())  # Output self
        foreach ($Child in $this.Children)
        {
            $null = $SB.AppendLine($Child.PrintTree(($Indentation + "    ")))  # Output children, one by one, with increased indentation
        }
        return $SB.ToString()
    }
}