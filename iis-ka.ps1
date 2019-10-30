<#
# This plugin requires IIS plugin and file with ka information
#
# (c) 2016-07-21 
 #>
param (
    # File needed 
    $ka = "D:\services\kalive\ka-all.txt",
    $active_dir = 'D:\Services\kalive\active',
    $inactive_dir = 'D:\Services\kalive\inactive'
)


# -------------------------------------
# re-use IIS Inventory to obtain status

[string]$check_mk_path = (Get-ItemProperty -Path "$(if ($Env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { 'HKLM:\SOFTWARE\Wow6432Node\check_mk_agent' } else { 'HKLM:\SOFTWARE\check_mk_agent' })").Install_Dir
[string]$InventoryFilePath = Join-Path -Path $check_mk_path -ChildPath 'tasks\IIS-Inventory.log' -ErrorAction Stop

$site_status = Import-Csv -Path $InventoryFilePath | ? { $_.Type -eq 'SITE' } | % {
    [PSCustomObject]@{
        Site = $_.Name
        Status = $_.PID
    }
}

if (Test-Path -Path $ka) {

    '<<<iis_ka:sep(9)>>>'
    Import-Csv -Delimiter ' ' -Path $ka -ErrorAction Stop | % {

        $ka = [PSCustomObject]@{
            Site = $_.site
            Status = $null
            Active = $false
            Inactive = $false
        }

        # get site status
        foreach ($s in $site_status) {
            if ($ka.Site -eq $s.Site) {
                $ka.Status = $($s.Status)
            }
        }

        <# verfiy keep alive path
        $f = ls $_.ka -ErrorAction SilentlyContinue
        # verify is inactive file exists
        $inactive_path = Join-Path $f.Directory '..\inactive' -Resolve  -ErrorAction SilentlyContinue
        $inactive_file = Join-Path -Path $inactive_path $f.Name  -ErrorAction SilentlyContinue

        $f = "d:\"
        #>
        # verify if file is in active directory
        if (Test-Path (Join-Path -Path $active_dir $_.ka)) {
            $ka.Active = $true
        }

        if (Test-Path (Join-Path -Path $inactive_dir $_.ka)) {
            $ka.Inactive = $true
        }

        # out result
        "$($ka.Site)`t$($ka.Status)`t$($ka.Active)`t$($ka.Inactive)"
    }
}
