﻿using namespace Microsoft.PowerShell.Commands
using module .\EquatableModuleSpecification.Class.psm1

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
    ComparableModuleSpecification ([hashtable]$Hashtable) : base ([hashtable]$Hashtable) {}
    ComparableModuleSpecification ([ModuleSpecification]$ModuleSpec) : base ($ModuleSpec) {}
    ComparableModuleSpecification ([PSModuleInfo]$Module) : base ($Module) {}
    ComparableModuleSpecification ([string]$Name) : base ($Name) {}


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