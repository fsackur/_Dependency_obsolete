using namespace System.Collections.Generic
using namespace Microsoft.PowerShell.Commands
using module .\EquatableModuleSpecification.Class.psm1
using module .\ComparableModuleSpecification.Class.psm1

class ModuleSpec : ComparableModuleSpecification
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
        This module provides the Get-ModuleDependency function to build the tree.
    #>

    [ModuleSpec]$Parent
    [ModuleSpec[]]$Children

    # Constructors
    ModuleSpec ([string]$Name) : base (@{ModuleName = $Name; ModuleVersion = '0.0.0.0'}) {}
    ModuleSpec ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}
    ModuleSpec ([ModuleSpecification]$ModuleSpec) : base (  #have to chain base ctor because properties are read-only
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
    [List[ModuleSpec]] ToList()
    {
        $List = [List[ModuleSpec]]::new()
        $List.Add($this)

        foreach ($Child in $this.Children)
        {
            $List.AddRange($Child.ToList())
        }

        return $List
    }

    # List with duplicates removed
    [List[ModuleSpec]] GetDistinctList()
    {
        return [List[ModuleSpec]]($this.ToList() | Select-Object -Unique)
    }

    # List with duplicates removed and in reverse order
    [List[ModuleSpec]] GetModuleImportOrder()
    {
        $List = $this.ToList()
        $List.Reverse()
        return [List[ModuleSpec]]($List | Select-Object -Unique)
    }

    # Visual output with dependencies indented
    [string] PrintTree()
    {
        return $this.PrintTree("")
    }

    [string] PrintTree([string]$Indentation)
    {
        $SB   = New-Object System.Text.StringBuilder (200)
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