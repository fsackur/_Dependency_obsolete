class ModuleDependency : ComparableModuleSpecification
{
    [ModuleDependency[]] $Parent
    [ModuleDependency[]] $Children

    # Constructor; just chains base ctor
    ModuleDependency ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}

    # 'Type accelerator' constructor; have to chain base ctor because properties are read-only
    ModuleDependency ([Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec) : base (
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


    # List of all dependencies; reverse this to get a viable module import order
    [System.Collections.Generic.List[ModuleDependency]] ToList()
    {
        $List = [System.Collections.Generic.List[ModuleDependency]]::new()
        $List.Add($this)

        foreach ($Child in $this.Children)
        {
            $ChildList = $Child.ToList()
            if ($ChildList) {$List.AddRange([System.Collections.Generic.List[ModuleDependency]]$ChildList)}
        }

        return $List
    }

    # List with duplicates removed
    [System.Collections.Generic.List[ModuleDependency]] GetDistinctList()
    {
        return [System.Collections.Generic.List[ModuleDependency]]($this.ToList() | Select-Object -Unique)
    }

    # List with duplicates removed and in reverse order
    [System.Collections.Generic.List[ModuleDependency]] GetModuleImportOrder()
    {
        return $this.GetDistinctList().Reverse()
    }

    # Visual output with dependencies indented
    [string] PrintTree()
    {
        return $this.PrintTree("")
    }
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