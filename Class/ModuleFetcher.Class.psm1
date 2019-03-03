using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands
using namespace System.IO
using module .\EquatableModuleSpecification.Class.psm1

class ModuleFetcher
{
    ModuleFetcher ()
    {
        if ($this.GetType() -eq [ModuleFetcher])
        {
            throw ([NotImplementedException]::new("$($this.GetType()) is an interface. You must use a derived class."))
        }
    }

    [PSModuleInfo] GetModule([ModuleSpecification]$ModuleSpec)
    {
        throw ([NotImplementedException]::new("$($this.GetType()) is an interface. You must use a derived class."))
    }
}

class FileSystemModuleFetcher : ModuleFetcher
{
    FileSystemModuleFetcher ()
    {
        $this.ModulePath = $env:PSModulePath -split ';' -replace '\\?$'
    }

    FileSystemModuleFetcher ([string[]] $ModulePath)
    {
        $this.ModulePath = $ModulePath -split ';' -replace '\\?$'
    }

    hidden [string[]] $ModulePath

    [PSModuleInfo] GetModule([ModuleSpecification]$ModuleSpec)
    {
        $SearchPath = $this.ModulePath.ForEach({
            Join-Path $_ $ModuleSpec.Name
        })
        Write-Debug "Searching '$($SearchPath -join "', '")'..."

        $Module = (Get-Module $SearchPath -ListAvailable).Where({
            ([EquatableModuleSpecification]$_).MeetsSpec($ModuleSpec)
        }, 'First')

        if ($Module)
        {
            Write-Debug "Found module '$Module'."
            return $Module[0]
        }
        else
        {
            throw ([ItemNotFoundException]::new("No modules were found matching argument '$ModuleSpec'."))
        }
    }
}