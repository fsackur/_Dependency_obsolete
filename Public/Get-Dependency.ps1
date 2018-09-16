function Get-Dependency
{
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.ModuleSpecification])]
    param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.ModuleSpecification]$DependingModule,

        [Parameter(Mandatory = $false, Position = 1)]
        [scriptblock]$ManifestReader = (Get-ManifestReader)
    )

    process
    {
        $DependingManifest = & $ManifestReader $DependingModule.Name
        [Microsoft.PowerShell.Commands.ModuleSpecification[]]$Required = $DependingManifest.RequiredModules

        if ($Required)
        {
            $DependingModule.Children = $Required | Get-Dependency
            $DependingModule.Children | ForEach-Object {$_.Parent = $DependingModule}
        }

        $DependingModule
    }
}
