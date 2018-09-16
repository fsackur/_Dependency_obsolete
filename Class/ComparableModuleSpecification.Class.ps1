class ComparableModuleSpecification : Microsoft.PowerShell.Commands.ModuleSpecification, IComparable, IEquatable[Microsoft.PowerShell.Commands.ModuleSpecification]
{
    [ComparableModuleSpecification[]] $Parent
    [ComparableModuleSpecification[]] $Children

    # Constructor; just chains base ctor
    ComparableModuleSpecification ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}


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
    [System.Collections.Generic.List[Microsoft.PowerShell.Commands.ModuleSpecification]] GetList()
    {
        $List = [System.Collections.Generic.List[Microsoft.PowerShell.Commands.ModuleSpecification]]::new()
        $this.Children | ForEach-Object {
            $ChildList = $_.GetList()
            if ($ChildList) {$List.AddRange([System.Collections.Generic.List[Microsoft.PowerShell.Commands.ModuleSpecification]]$ChildList)}
        }
        $List.Add($this)

        [System.Collections.Generic.List[Microsoft.PowerShell.Commands.ModuleSpecification]]$L2 = $List | Get-Unique
        return $L2
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