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

        $DependingModule | Add-Member 'NoteProperty' -Name 'Children' -Force -Value @()
        $DependingModule | Add-Member 'NoteProperty' -Name 'Parent' -Force -Value $null
        if ($Required)
        {
            $DependingModule.Children = $Required | Get-Dependency
            $DependingModule.Children | ForEach-Object {$_.Parent = $DependingModule}
        }

        $DependingModule | Add-Member 'ScriptMethod' -Name 'ToString' -Force -Value {$this.Name, $this.Version -join ' '}
        $DependingModule | Add-Member 'ScriptMethod' -Name 'GetHashCode' -Force -Value {$this.ToString().GetHashCode() <#($this.Name + $this.Version).GetHashCode() #>}
        $DependingModule | Add-Member 'ScriptMethod' -Name 'PrintTree' -Force -Value {
            param ([string]$Indentation = "")
            $Indentation + $this.ToString()
            foreach ($Child in $this.Children) {$Child.PrintTree(($Indentation + "    "))}
        }
        $DependingModule | Add-Member 'ScriptMethod' -Name 'Equals' -Force -Value {
            $this.Name -eq $args[0].Name #-and $this.Version -eq $args[0].Version
        }
        
        
        $DependingModule | Add-Member 'ScriptMethod' -Name 'GetList' -Force -Value {
            $List = [System.Collections.Generic.List[Microsoft.PowerShell.Commands.ModuleSpecification]]::new()
            $this.Children | ForEach-Object {
                $ChildList = $_.GetList()
                if ($ChildList) {$List.AddRange([System.Collections.Generic.List[Microsoft.PowerShell.Commands.ModuleSpecification]]$ChildList)}
            }
            $List.Add($this)
            
            $L2 = $List | Get-Unique 
            [System.Collections.Generic.List[Microsoft.PowerShell.Commands.ModuleSpecification]]$L2
        }

        $DependingModule
    }
}
