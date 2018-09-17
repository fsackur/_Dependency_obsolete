function Get-FilesystemManifestFinder
{
    <#
        .SYNOPSIS
        Gets a pluggable scriptblock for finding modules in a filesystem.

        .DESCRIPTION
        The command Get-ModuleDependency delegates the search for module manifest files to a scriptblock. This command
        creates one possible implementation for that scriptblock.

        .PARAMETER ModulePath
        A semi-colon-separated list of paths, or array of paths, containing PS modules to be searched.

        .PARAMETER VersionMatchingPreference
        When more than one module version is found that falls within the version range allowed by the module
        specification, specify whether to prefer the highest matching version or the lowest matching version.

        .OUTPUTS
        [scriptblock]

        A scriptblock that:

        - Accepts an argument of type Microsoft.PowerShell.Commands.ModuleSpecification
        - Searches the provided path list for modules matching that module specification
        - returns a tuple containing data from the discovered module's manifest, and the URI of the module

        .EXAMPLE
        Get-FilesystemManifestFinder -ModulePath 'C:\dev'

        {
            param
            (
                [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
                [Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec
            )

              ...
        }

        Gets a pluggable scriptblock for finding modules in a filesystem. This scriptblock will search the path 'C:\dev'.

        .LINK
        https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.modulespecification
    #>
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param
    (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string[]]$ModulePath = $env:PSModulePath,

        [Parameter()]
        [ValidateSet('Highest', 'Lowest')]
        [string]$VersionMatchingPreference = 'Lowest'
    )

    end
    {
        if ($PSCmdlet.ExpectingInput -and $PSBoundParameters.ContainsKey('ModulePath'))
        {
            $ModulePath = $input
        }
        $ModulePath = $ModulePath -split ';'


        $FilesystemFinder = {
            <#
                .SYNOPSIS
                Finds a module mamifest matching a module specification within a filesystem.

                .DESCRIPTION
                Searches a list of folder paths for a module. The name of the module is taken from the input module
                specification.

                Looks within module folders for a version that matches the version component of the module specification.

                Two input parameters, 'ModulePath' and 'VersionMatchingPreference', are set at creation time, not at runtime.

                .PARAMETER ModuleSpec
                The module specification against which the version is to be tested.

                .OUTPUTS
                [Tuple[hashtable, uri]]

                A tuple containing data from the first discovered module's manifest, and the URI of the module.

                .EXAMPLE
                $Finder = Get-FilesystemManifestFinder -ModulePath 'C:\dev'
                & $Finder @{ModuleName = 'AzureTemplating'; ModuleVersion = '1.3.0.7'}

                @{
                    Description = 'Module for working with Azure templates.'
                    RootModule  = 'AzureTemplating.psm1'
                       ....
                }

                Searches C:\dev for the AzureTemplating module, and returns the contents of the module manifest.
            #>
            [CmdletBinding()]
            [OutputType([Tuple[hashtable, uri]])]
            param
            (
                [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
                [Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleSpec
            )

            $ModuleName = $ModuleSpec.Name

            foreach ($ModuleRoot in $ModulePath)    # ModulePath is bound from parent scope by GetNewClosure()
            {
                $ModuleBase = Join-Path $ModuleRoot $ModuleName
                if (-not (Test-Path $ModuleBase -PathType Container))
                {
                    continue
                }

                # Does the module folder have version-number folders inside?
                $ContainedVersions = Get-ChildItem $ModuleBase -Directory |
                    Where-Object   {$_.Name -match '(\d+\.){2,3}\d+'} |
                    ForEach-Object {[version]$_.Name} |
                    Where-Object   {$_ | Test-VersionMeetsModuleSpec $ModuleSpec}

                # Pick version number according to preference
                $SortSplat = @{}
                if ($VersionMatchingPreference -eq 'Highest')
                {
                    $SortSplat['Descending'] = $true
                }
                $ContainedVersion = $ContainedVersions |
                    Sort-Object @SortSplat |
                    Select-Object -First 1

                $ModuleBase = Join-Path $ModuleBase $ContainedVersion  # Has no effect if ChildPath argument is null, so will fall back to the original ModuleBase
                $Psd1Path   = Join-Path $ModuleBase "$ModuleName.psd1"

                if (Test-Path $Psd1Path -PathType Leaf)
                {
                    $Manifest = Import-PowerShellDataFile $Psd1Path -ErrorAction Stop
                    if (Test-VersionMeetsModuleSpec $ModuleSpec $Manifest.ModuleVersion)
                    {
                        return [Tuple[hashtable, uri]]::new($Manifest, [uri]$Psd1Path)
                    }
                }
            }

            throw New-Object System.Management.Automation.ItemNotFoundException (
                "Could not find any module meeting specification '$($ModuleSpec)' in path list '$($ModulePath -join ';')'."
            )

        }.GetNewClosure()   # GetNewClosure binds any variables in the scriptblock to the values they have in the enclosing scope.
        # This is how we fix the values of $ModulePath and $VersionMatchingPreference within the scriptblock to whatever their
        # values were in the outer function.


        return $FilesystemFinder
    }
}
