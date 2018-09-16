class ModuleDependency : ComparableModuleSpecification
{
    <#
        .SYNOPSIS
        This class gives us module specification objects that can be nodes in a tree structure.

        .DESCRIPTION
        This class provides:

        - ToList()               : Outputs a list of dependency modules, including duplicates
        - GetDistinctList()      : Outputs a list of dependency modules, with duplicates removed
        - GetModuleImportOrder() : Outputs a list of dependency modules, in reverse order
        - PrintTree()            : Outputs a string with the tree structure shown by indentation

        .NOTES
        This module provides the Get-Dependency function to build the tree.
    #>

    [ModuleDependency]$Parent
    [ModuleDependency[]]$Children

    # Constructors
    ModuleDependency ([string]$Name) : base (@{ModuleName = $Name; ModuleVersion = '0.0.0.0'}) {}
    ModuleDependency ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}
    ModuleDependency ([Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec) : base (  #have to chain base ctor because properties are read-only
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

    hidden [string] PrintTree([string]$Indentation)
    {
        $SB = New-Object System.Text.StringBuilder (200)
        $null = $SB.Append($Indentation).AppendLine($this.ToString())  # Output self
        foreach ($Child in $this.Children)
        {
            # Output children, one by one, with increased indentation
            $ChildTree = $Child.PrintTree(($Indentation + "    "))
            if (-not [string]::IsNullOrWhiteSpace($ChildTree))
            {
                $null = $SB.Append($ChildTree)
            }
        }
        return $SB.ToString()
    }
}