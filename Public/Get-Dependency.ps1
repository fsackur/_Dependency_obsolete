function Get-Dependency
{
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.ModuleSpecification])]
    param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ModuleDependency]$DependingModule,

        [Parameter(Mandatory = $false, Position = 1)]
        [scriptblock]$ManifestReader = (Get-FilesystemManifestReader)
    )

    process
    {
        $DependingManifest = & $ManifestReader $DependingModule
        [ModuleDependency[]]$Required = $DependingManifest.RequiredModules

        if ($Required)
        {
            $DependingModule.Children = $Required | Get-Dependency -ManifestReader $ManifestReader
            $DependingModule.Children | ForEach-Object {$_.Parent = $DependingModule}
        }

        $DependingModule
    }
}
