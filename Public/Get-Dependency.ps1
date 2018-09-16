using module ..\Class\ModuleTreeNode.Class.psm1

function Get-Dependency
{
    <#
        .SYNOPSIS
        Builds a dependency tree for a module.

        .DESCRIPTION
        Given a module specification, searches for the module and looks for the RequiredModules in the module manifest. Adds
        required modules as child nodes of the original module, and recursively searches for these child modules to build the
        tree structure.

        The search algorithm is pluggable. By default, paths in the PSModulePath environment variable will be searched. The
        user can alter this behaviour by passing a scriptblock to the ManifestFinder parameter. The scriptblock could
        implement search for an online gallery or source control system, for example.

        Modules must have a module manifest, or an ItemNotFound exception will be thrown.

        .PARAMETER DependingModule
        Specify the module for which to build the dependency tree.

        .PARAMETER ManifestFinder
        Specify a scriptblock with the following characteristics:

        - Accepts an argument of type Microsoft.PowerShell.Commands.ModuleSpecification
        - Searches for modules matching that module specification
        - returns a tuple containing data from the discovered module's manifest, and the URI of the module

        .OUTPUTS
        [ModuleTreeNode]

        This command outputs an object of type [ModuleTreeNode], which derives from
        [Microsoft.PowerShell.Commands.ModuleSpecification].

        .EXAMPLE
        Get-Dependency @{ModuleName = 'AzureTemplating'; ModuleVersion = '1.3.0.7'}

        Name            Version
        ----            -------
        AzureTemplating 1.3.0.7

        Gets the dependency tree for the 'AzureTemplating' module and outputs the module.

        .EXAMPLE
        $Module = Get-Dependency @{ModuleName = 'AzureTemplating'; ModuleVersion = '1.3.0.7'}
        $Module.ToList()

        Name            Version
        ----            -------
        AzureTemplating 1.3.0.7
        AzureBuilder    2.0.1.3
        AzureRM         1.1.3.0

        Gets the dependency tree for the 'AzureTemplating' module and outputs the list of
        modules that it depends on.

        .EXAMPLE
        $Module = Get-Dependency @{ModuleName = 'AzureTemplating'; ModuleVersion = '1.3.0.7'}
        $Module.PrintTree()

        AzureTemplating 1.3.0.7
            AzureBuilder    2.0.1.3
                AzureRM         1.1.3.0

        Gets the dependency tree for the 'AzureTemplating' module and outputs a visual
        representation.

        .LINK
        https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.modulespecification
    #>
    [CmdletBinding()]
    [OutputType([ModuleTreeNode])]
    param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.ModuleSpecification]$DependingModule,

        [Parameter(Mandatory = $false, Position = 1)]
        [scriptblock]$ManifestFinder = (Get-FilesystemManifestFinder)
    )

    process
    {
        $Found             = $ManifestFinder.Invoke($DependingModule)
        $DependingManifest = $Found.Item1
        $ModuleUri         = $Found.Item2

        # Reimport to set the version discovered by the finder
        $DependingModule   = [ModuleTreeNode]@{
            ModuleName    = $DependingModule.Name
            ModuleVersion = $DependingManifest.ModuleVersion
        }

        [ModuleTreeNode[]]$Required = $DependingManifest.RequiredModules

        if ($Required)
        {
            $DependingModule.Children = $Required | Get-Dependency -ManifestFinder $ManifestFinder
            $DependingModule.Children | ForEach-Object {$_.Parent = $DependingModule}
        }

        $DependingModule
    }
}
