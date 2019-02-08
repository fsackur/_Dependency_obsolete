using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands
using module .\ModuleSpec.Class.psm1
using module .\ModuleFetcher.Class.psm1

class DependencyBuilder
{
    [ModuleFetcher]$Fetcher = [FileSystemModuleFetcher]::new()

    [ModuleSpec] GetDependencies([ModuleSpec]$Node)
    {
        try
        {
            $NodeAsModule = $this.Fetcher.GetModule($Node)
        }
        catch [ItemNotFoundException]
        {
            return $null
        }

        $NodeAsModule.RequiredModules.ForEach({

            $ChildNode = [ModuleSpec]$_

            $ChildNode.Parent = $Node

            $Node.Children.Add(
                $this.GetDependencies($ChildNode)
            )
        })

        return $Node
    }
}