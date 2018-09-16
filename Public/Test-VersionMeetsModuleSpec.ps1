function Test-VersionMeetsModuleSpec
{
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param
    (
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [version]$Version,

        [Parameter(Mandatory, Position = 0)]
        [Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec
    )

    process
    {
        if ($ModuleSpec.RequiredVersion)
        {
            return $Version -eq [version]$ModuleSpec.RequiredVersion
        }

        if ($ModuleSpec.Version -and $Version -lt [version]$ModuleSpec.Version)
        {
            return $false
        }


        if ($ModuleSpec.MaximumVersion -and $Version -gt [version]$ModuleSpec.MaximumVersion)
        {
            return $false
        }

        return $true
    }
}