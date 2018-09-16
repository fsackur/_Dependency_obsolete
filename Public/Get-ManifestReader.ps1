function Get-ManifestReader
{
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param ()

    $FilesystemReader = {
        [CmdletBinding()]
        [OutputType([hashtable])]
        param
        (
            [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
            [string]$ModuleName
        )

        $GitRoot = 'C:\dev'

        $ModuleBase = Join-Path $GitRoot $ModuleName

        $Psd1Path = Join-Path $ModuleBase "$ModuleName.psd1"

        try
        {
            Import-PowerShellDataFile $Psd1Path -ea Stop
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
            $GitRoot = 'C:\dev'

            $ModuleBase = Join-Path $GitRoot $ModuleName

            $Psd1Path = Join-Path $ModuleBase "$ModuleName.psd1"

            Import-PowerShellDataFile $Psd1Path -ea Stop
        }
    }

    return $FilesystemReader
}
