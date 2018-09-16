function Get-FilesystemManifestReader
{
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param
    (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string[]]$ModulePath = $env:PSModulePath
    )

    end
    {
        if ($PSCmdlet.ExpectingInput -and $PSBoundParameters.ContainsKey('ModulePath'))
        {
            $ModulePath = $input
        }
        $ModulePath = $ModulePath -split ';'


        $FilesystemReader = {
            [CmdletBinding()]
            [OutputType([hashtable])]
            param
            (
                [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
                [Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec
            )

            $ModuleName = $ModuleSpec.Name

            foreach ($ModuleRoot in $ModulePath)
            {
                $ModuleBase = Join-Path $ModuleRoot $ModuleName

                if (-not (Test-Path $ModuleBase -PathType Container)) {continue}

                $ContainedVersions = Get-ChildItem $ModuleBase -Directory |
                    Where-Object {$_.Name -match '(\d+\.){2,3}\d+'} |
                    ForEach-Object {[version]$_.Name} |
                    Where-Object {$_ | Test-VersionMeetsModuleSpec $ModuleSpec}

                $SortSplat = @{}
                if ($GreedyVersionMatching)
                {
                    $SortSplat['Descending'] = $true
                }
                $ContainedVersion = $ContainedVersions | Sort-Object @SortSplat | Select-Object -First 1

                $ModuleBase = Join-Path $ModuleBase $ContainedVersion  # Has no effect if ChildPath argument is null
                
                $Psd1Path = Join-Path $ModuleBase "$ModuleName.psd1"

                if (Test-Path $Psd1Path -PathType Leaf)
                {
                    $Manifest = Import-PowerShellDataFile $Psd1Path -ErrorAction Stop
                    if (Test-VersionMeetsModuleSpec $ModuleSpec $Manifest.ModuleVersion)
                    {
                        return $Manifest
                    }
                }
            }

            throw New-Object System.Management.Automation.ItemNotFoundException (
                "Could not find module meeting spec '$ModuleSpec' in path list '$($ModulePath -join ';')'."
            )

        }.GetNewClosure()


        return $FilesystemReader
    }
}
