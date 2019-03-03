using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands
using namespace System.IO
using module .\EquatableModuleSpecification.Class.psm1
using module .\ModuleFetcher.Class.psm1


class GithubModuleFetcher : FileSystemModuleFetcher
{
    GithubModuleFetcher ()
    {
        throw ([ArgumentException]::new("Could not find a constructor matcing  the argument cout: 0"))
    }

    GithubModuleFetcher ([string]$ModulePath, [string]$GithubBaseUrl, [string]$GithubUser, [string]$GithubToken)
    {
        $this.ModulePath    = $ModulePath
        $this.GithubBaseUrl = $GithubBaseUrl -replace '/$'
        $this.GithubUser    = $GithubUser
        $this.GithubToken   = $GithubToken
    }
    [string] $ModulePath
    [string] $GithubBaseUrl
    [string] $GithubUser
    hidden [string] $GithubToken    # Not exactly secure, but does reduce chance of accidentally leaking token

    [PSModuleInfo] GetModule([ModuleSpecification]$ModuleSpec)
    {
        try
        {
            # Search locally first
            return ([FileSystemModuleFetcher]$this).GetModule($ModuleSpec)
        }
        catch
        {
            Write-Verbose "Module matching spec '$($ModuleSpec.ToString())' not found in '$($this.ModulePath -join "', '")'. Fetching from '$($this.GithubBaseUrl)'."
        }


        $SpecVersion = ([EquatableModuleSpecification]$ModuleSpec).GetVersion()
        $ExactMatch  = [bool]$ModuleSpec.RequiredVersion


        $ReleaseSplat = @{
            Uri = "{0}/repos/{1}/{2}/releases?token={3}" -f (
                $this.GithubBaseUrl,
                $this.GithubUser,
                $ModuleSpec.Name,
                $this.GithubToken
            )
            Method = 'GET'
        }
        $Releases = Invoke-RestMethod @ReleaseSplat | Sort-Object tag_name -Descending


        $TagVersion = $null
        $Release = @($Releases).Where({
            $TagVersion = [version]($_.tag_name -replace '^v' -replace '[^\d^\.].*')
            return (
                ($ExactMatch -and $TagVersion -eq $SpecVersion) -or
                (-not $ExactMatch -and $TagVersion -ge $SpecVersion)
            )
        }, 'First')

        if (-not $Release)
        {
            throw ([ItemNotFoundException]::new("No modules were found matching argument '$ModuleSpec'."))
        }


        $ZipPath = Join-Path $env:TEMP ("{0}_{1}.zip" -f $ModuleSpec.Name, $SpecVersion.ToString())
        $ZipSplat = @{
            Uri    = $Release.zipball_url, $this.GithubToken -join '?token='
            Method = 'GET'
            OutFile = $ZipPath
        }
        Invoke-RestMethod @ZipSplat


        $ModuleBase = Join-Path $this.ModulePath $ModuleSpec.Name
        Expand-Archive $ZipPath $ModuleBase

        # Github places content in subfolder. Rename to version after extracting.
        Get-ChildItem $ModuleBase -Filter ("{0}-{1}-*" -f $this.GithubUser, $ModuleSpec.Name) |
            Sort-Object LastWriteTime |
            Select-Object -ExpandProperty FullName -Last 1 |
            Rename-Item -NewName $TagVersion -Force
        <#
        Get-ChildItem $ModuleBase -Filter ("{0}-{1}-*" -f $this.GithubUser, $ModuleSpec.Name) |
            Sort-Object LastWriteTime |
            Select-Object -ExpandProperty FullName -Last 1 |
            Rename-Item -NewName $TagVersion -Force
        #>
        Remove-Item $ZipPath


        return ([FileSystemModuleFetcher]$this).GetModule($ModuleSpec)
    }
}