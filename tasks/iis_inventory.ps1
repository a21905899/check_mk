#Requires -Version 2
# Requires -Version 3
# Requires -Modules WebAdministration
# Requires -RunAsAdministrator

<#

    Alerta: o script necessita de privilégios para poder aceder à propriedade CommandLine dos processos!

#>

[string]$check_mk_path = (Get-ItemProperty -Path "$(if ($Env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { 'HKLM:\SOFTWARE\Wow6432Node\check_mk_agent' } else { 'HKLM:\SOFTWARE\check_mk_agent' })").Install_Dir
[string]$InventoryFilePath = Join-Path -Path $check_mk_path -ChildPath 'tasks\IIS-Inventory.log'

#if (Test-Path -Path $InventoryFilePath) {

    Remove-Item -Path $InventoryFilePath -ErrorAction SilentlyContinue
#}

[PSObject[]]$inventory = Get-WmiObject Win32_Process -Filter 'Name="w3wp.exe"' | % {
    $W3WP = 1
    $AppPoolPID = $_.ProcessId
    $_.CommandLine | select-string -Pattern '[-/]ap\s+"(?<ap>[^"]+)"' | % { $_.Matches } | ? { $_.Success } | % {
        $AppPoolName = $_.Groups['ap'].Value 
        
        $AppPool = New-Object -TypeName PSObject
        Add-Member -InputObject $AppPool -Name Type -Value 'APPPOOL' -MemberType NoteProperty
        Add-Member -InputObject $AppPool -Name Name -Value $AppPoolName -MemberType NoteProperty
        Add-Member -InputObject $AppPool -Name PID -Value $AppPoolPID -MemberType NoteProperty
        $AppPool
    }
}
    
$inventory += Get-WmiObject Win32_Process -Filter 'Name="svchost.exe" AND CommandLine LIKE "%iis%"' | % {
    $AppPoolPID = $_.ProcessId
    $AppPoolName = $_.CommandLine.split()[-1]
    if ($AppPoolName -eq 'iissvcs') { $Type = 'IIS' } else { $Type = 'APPPOOL' }
    $AppPool = New-Object -TypeName PSObject
    Add-Member -InputObject $AppPool -Name Type -Value $Type -MemberType NoteProperty
    Add-Member -InputObject $AppPool -Name Name -Value $AppPoolName -MemberType NoteProperty
    Add-Member -InputObject $AppPool -Name PID -Value $AppPoolPID -MemberType NoteProperty
    $AppPool
}

Import-Module WebAdministration

$inventory += Get-ChildItem -Path IIS:\Sites | Select-Object Name, State | % {
        $site = New-Object -TypeName PSObject
        Add-Member -InputObject $site -Name Type -Value 'SITE' -MemberType NoteProperty
        Add-Member -InputObject $site -Name Name -Value $_.Name -MemberType NoteProperty
        Add-Member -InputObject $site -Name PID -Value $_.state -MemberType NoteProperty
        $site
}

$inventory += Get-ChildItem -Path IIS:\AppPools | Select-Object Name, State | % {

        $apppool = New-Object -TypeName PSObject
        Add-Member -InputObject $apppool -Name Type -Value 'APPSTATE' -MemberType NoteProperty
        Add-Member -InputObject $apppool -Name Name -Value $_.Name -MemberType NoteProperty
        Add-Member -InputObject $apppool -Name PID -Value $_.state -MemberType NoteProperty
        $apppool
}

$inventory | Export-Csv -NoTypeInformation -Path $InventoryFilePath
