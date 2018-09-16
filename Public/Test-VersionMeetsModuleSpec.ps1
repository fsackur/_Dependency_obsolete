function Test-VersionMeetsModuleSpec
{
    <#
        .SYNOPSIS
        Tests whether a version falls within the acceptable range specified by a module specification object.

        .DESCRIPTION
        Given a module specification, tests whether a given version satisifes it.

        If the module specification has a RequiredVersion, then this command performs an exact comparison against
        the RequiredVersion property. Otherwise, this command tests that the version is greater than or equal to
        the Version property and, if present, less than or equal to the MaximumVersion property.

        .PARAMETER Version
        The version to test against the module specification.

        .PARAMETER ModuleSpec
        The module specification against which the version is to be tested.

        .OUTPUTS
        [bool]

        .EXAMPLE
        $ModuleSpec = @{ModuleName = 'AzureTemplating'; ModuleVersion = '1.3.0.7'}
        "1.2.0.0" | Test-VersionMeetsModuleSpec -ModuleSpec $ModuleSpec

        False

        Tests whether the version "1.2.0.0" meets the requirement of the module specification.

        .LINK
        https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.modulespecification
    #>
    [CmdletBinding()]
    [OutputType([bool])]
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