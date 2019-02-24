using module ..\Class\GithubModuleFetcher.Class.psm1
using module ..\Class\ModuleSpec.Class.psm1


Describe "GithubModuleFetcher" {

    #region setup globals
    $Global:Name1 = 'Cat'
    $Global:Name2 = 'Dog'
    $Global:Name3 = 'Flea'

    $Global:Version1 = '1.2.3'
    $Global:Version2 = '4.5.6'
    $Global:Version3 = '7.8.9'

    $CatSpec = [ModuleSpec]@{
        ModuleName    = 'Cat'
        ModuleVersion = $Version1
    }
    $DogSpec = [ModuleSpec]@{
        ModuleName    = 'Dog'
        ModuleVersion = $Version1
    }
    $FleaSpec1 = [ModuleSpec]@{
        ModuleName    = 'Flea'
        ModuleVersion = $Version1
    }
    $FleaSpec2 = [ModuleSpec]@{
        ModuleName    = 'Flea'
        ModuleVersion = $Version3
    }
    $Global:Specs = $CatSpec, $DogSpec, $FleaSpec1, $FleaSpec2
    $Global:Specs | Add-Member NoteProperty IsOnFileSystem $false
    $Global:Specs | Add-Member NoteProperty IsOnGithub $true
    $CatSpec.IsOnFileSystem = $true
    $FleaSpec2.IsOnGithub = $false

    $Global:TestModulePath = "TestDrive:\TestModules"
    $Global:CatPath = Join-Path $TestModulePath 'Cat'
    $Global:DogPath = Join-Path $TestModulePath 'Dog'

    $Global:GithubBaseUrl = 'https://api.github.com'
    $Global:GithubUser = 'fsackur'
    $Global:GithubToken = 'deadbeefdeadbeefdeadbeefdeadbeef'
    #endregion setup globals


    Mock -ModuleName "ModuleFetcher.Class" Get-Module {
        if (-not $ListAvailable)
        {
            throw [ArgumentException]::new("Mock should be called with -ListAvailable.")
        }

        $Modules = @()
        foreach ($n in $Name)
        {
            $ModuleBase = Split-Path $n
            $ModuleName = Split-Path $n -Leaf
            $FoundSpecs = $Global:Specs.Where({$_.Name -eq $ModuleName -and $_.IsOnFileSystem})

            if ($ModuleBase -eq $Global:TestModulePath)
            {
                $FoundSpecs.ForEach({
                    $Module = New-Module -Name $_.Name {}
                    [PSModuleInfo].GetField("_version", "Instance, NonPublic").SetValue($Module, [version]$_.Version)
                    [PSModuleInfo].GetField("_moduleBase", "Instance, NonPublic").SetValue($Module, $n)
                    $Modules += $Module
                })
            }
        }

        if ($Modules)
        {
            return $Modules
        }
        else
        {
            throw [FileNotFoundException]::new("
                Mock sez: The specified module '$n' was not found.
            ".Trim())
        }
    }


    Mock -ModuleName "GithubModuleFetcher.Class" Invoke-RestMethod {
        if ($Uri -match "(?<BaseUrl>.+)/repos/(?<Username>\w+)/(?<Repo>\w+)/(?<Endpoint>.*)\?token=(?<Token>\w+)")
        {
            $UriParts = [pscustomobject]$Matches
            if ($UriParts.BaseUrl -ne $Global:GithubBaseUrl) {throw "Wrong URL"}
            if ($UriParts.Username -ne $Global:GithubUser) {throw "Wrong user"}
            if ($UriParts.Token -ne $Global:GithubToken) {throw "Wrong token"}

            if ($UriParts.Endpoint -eq 'releases')
            {
                $Global:Specs.Where({$_.Name -eq $UriParts.Repo -and $_.IsOnGithub}).ForEach({
                    $TagName = "v$($_.Version)"
                    [pscustomobject]@{
                        tag_name = $TagName
                        zipball_url = $Uri -replace 'releases.*', "zipball/$TagName"
                    }
                })
            }
            elseif ($UriParts.Endpoint -match '^zipball/v(?<Version>[\d\.]+)$')
            {
                if (-not $OutFile) {throw "Hit the zipball endpoint, but didn't specify where to save the module"}
            }
        }
    }

    Mock -ModuleName "GithubModuleFetcher.Class" Expand-Archive {
        if ((Split-Path $Path) -ne $env:TEMP) {throw "Expanding path '$Path': Didn't save to temp folder!"}
        if ((Split-Path $DestinationPath) -ne $Global:TestModulePath) {throw "Tried to expand to wrong path."}
    }

    Mock -ModuleName "GithubModuleFetcher.Class" Get-ChildItem {
        $ModuleBase = $Path
        $ModuleRoot = Split-Path $ModuleBase
        $ModuleName = Split-Path $ModuleBase -Leaf

        if ($ModuleRoot -ne $Global:TestModulePath) {throw "Not searching module root folder!"}
        if ($ModuleName -notin $Global:Specs.Name) {throw "Wasn't a recognised test module."}
        if ($Filter -match ("(?<GithubUser>\w+)-(?<ModuleName>\w+)-.*"))
        {
            if ($Matches.ModuleName -ne $ModuleName) {throw "Expanded zip into wrong module base."}
            [pscustomobject]@{
                LastWriteTime = Get-Date
                FullName      = Join-Path $ModuleBase $Filter
            }
        }
        else
        {
            throw "Getting wrong expanded folder."
        }
    }

    Mock -ModuleName "GithubModuleFetcher.Class" Rename-Item {

        $ModuleBase = Split-Path $Path
        $ModuleRoot = Split-Path $ModuleBase
        $ModuleName = Split-Path $ModuleBase -Leaf

        if ($ModuleRoot -ne $Global:TestModulePath) {throw "Didn't expand to module root folder!"}
        if ($ModuleName -notin $Global:Specs.Name) {throw "Wasn't a recognised test module."}

        $NewName = Split-Path $NewName -Leaf
        $Version = $null
        if (-not [version]::TryParse($NewName, [ref]$Version)) {throw "Tried to rename to something that wasn't a version."}

        $FoundSpecs = $Global:Specs.Where({$_.Name -eq $ModuleName -and $_.Version -eq $Version})
        if ($FoundSpecs)
        {
            $FoundSpecs.ForEach({$_.IsOnFileSystem = $true})
        }
        else
        {
            $Spec = [Microsoft.PowerShell.Commands.ModuleSpecification]@{
                ModuleName    = $ModuleName
                ModuleVersion = $Version
            }
            $Spec | Add-Member NoteProperty IsOnFileSystem $true
            $Global:Specs += $Spec
        }
    }

    Mock -ModuleName "GithubModuleFetcher.Class" Remove-Item {}

    $Fetcher = [GithubModuleFetcher]::new(
        $Global:TestModulePath,
        $Global:GithubBaseUrl,
        $Global:GithubUser,
        $Global:GithubToken
    )


    $Module = $Fetcher.GetModule($CatSpec)

    It "Returns from filesystem, where found" {
        $Module.Name | Should -Be 'Cat'
        $Module.ModuleBase | Should -Match 'Cat'
        Assert-MockCalled -ModuleName "ModuleFetcher.Class" Get-Module -Times 1 -Exactly
        Assert-MockCalled -ModuleName "GithubModuleFetcher.Class" Invoke-RestMethod -Times 0 -Exactly
    }

    $Module = $Fetcher.GetModule($DogSpec)

    It "Downloads from Github to ModulePath" {
        $Module.Name | Should -Be 'Dog'
        $Module.ModuleBase | Should -Match 'Dog'
        Assert-MockCalled -ModuleName "ModuleFetcher.Class" Get-Module -Times 3 -Exactly
        Assert-MockCalled -ModuleName "GithubModuleFetcher.Class" Invoke-RestMethod -Times 2 -Exactly
        Assert-MockCalled -ModuleName "GithubModuleFetcher.Class" Expand-Archive -Times 1 -Exactly
        Assert-MockCalled -ModuleName "GithubModuleFetcher.Class" Get-ChildItem -Times 1 -Exactly
        Assert-MockCalled -ModuleName "GithubModuleFetcher.Class" Rename-Item -Times 1 -Exactly
    }

    It "Throws if version requirement is not met" {
        {$Fetcher.GetModule($FleaSpec2)} | Should -Throw -ExceptionType ([System.Management.Automation.ItemNotFoundException])
    }
}
