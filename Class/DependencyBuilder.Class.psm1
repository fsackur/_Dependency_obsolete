using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands
using module .\ModuleSpec.Class.psm1
using module .\ModuleFetcher.Class.psm1

class DependencyBuilder
{
    DependencyBuilder ([ModuleFetcher]$Fetcher)
    {
        $this.Fetcher = $Fetcher
    }

    [ValidateNotNull()]
    [ModuleFetcher]$Fetcher

    [ModuleSpec] GetDependencies([ModuleSpec]$Node)
    {
        # throws ItemNotFoundException
        $NodeAsModule = $this.Fetcher.GetModule($Node)

        $NodeAsModule.RequiredModules.ForEach({
            $ChildNode = [ModuleSpec]$_
            $ChildNode.Parent = $Node
            $Node.Children += $this.GetDependencies($ChildNode)
        })

        return $Node
    }
}