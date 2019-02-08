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
    hidden static [string[]] $ModulePath = $env:PSModulePath -split ';' -replace '\\?$', '\*'
    hidden static [PSModuleInfo[]] $AvailableModules

    static [void] SetModulePath([string]$ModulePath)
    {
        if ([FileSystemModuleFetcher]::ModulePath -ne $ModulePath)
        {
            [FileSystemModuleFetcher]::ModulePath = $ModulePath -split ';' -replace '\\?\*?$', '\*'
            [FileSystemModuleFetcher]::AvailableModules = $null
        }
    }

    hidden static [PSModuleInfo[]] GetAvailableModules ()
    {
        if (-not ([FileSystemModuleFetcher]::AvailableModules))
        {
            [FileSystemModuleFetcher]::AvailableModules = Get-Module ([FileSystemModuleFetcher]::ModulePath) -ListAvailable
        }

        return [FileSystemModuleFetcher]::AvailableModules
    }

    [PSModuleInfo] GetModule([ModuleSpecification]$ModuleSpec)
    {
        $Module = [FileSystemModuleFetcher]::GetAvailableModules().Where({
            ([EquatableModuleSpecification]$_).MeetsSpec($ModuleSpec)
        }, 'First')

        if ($Module)
        {
            return $Module[0]
        }
        else
        {
            throw ([ItemNotFoundException]::new("No modules were found matching argument '$ModuleSpec'."))
        }
    }
}