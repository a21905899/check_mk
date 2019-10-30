[string]$check_mk_path = (Get-ItemProperty -Path "$(if ($Env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { 'HKLM:\SOFTWARE\Wow6432Node\check_mk_agent' } else { 'HKLM:\SOFTWARE\check_mk_agent' })").Install_Dir
[string]$InventoryFilePath = Join-Path -Path $check_mk_path -ChildPath 'tasks\IIS-Inventory.log'

$Inventory = Import-Csv -Path $InventoryFilePath

$AppPoolPIDs = @{}
$Inventory | ? { @('APPPOOL', 'IIS') -contains $_.Type } | % { $AppPoolPIDs[$_.PID] = $_ }

Get-WmiObject -Namespace 'root/cimv2' -Class Win32_PerfFormattedData_PerfProc_Process -Filter 'Name like "w3wp%" OR Name like "svchost%"' -Property IDProcess, PercentProcessorTime, IODataOperationsPersec, PrivateBytes | % {
    $process_id = $_.IDProcess
    $process_cpu = $_.PercentProcessorTime
    $process_privatebytes = $_.PrivateBytes
    $process_iodata = $_.IODataOperationsPersec
    $AppPool = $AppPoolPIDs["$($_.IDProcess)"]

    if ($AppPool) {

        $Name = "$($AppPool.Type)__$($AppPool.Name)"
        Write-Output '<<<apppool_cpu>>>'
        Write-Output "$($Name)__CPU $process_cpu"

        Write-Output '<<<apppool_io>>>'
        Write-Output "$($Name)__IO $process_iodata"

        Write-Output '<<<apppool_pb>>>'
        Write-Output "$($Name)__PrivateBytes $process_privatebytes"
    }
}

Write-Output '<<<iis_state>>>'
$Inventory | ? { $_.Type -eq 'SITE' } | % {
    
    Write-Output "iissite_$($_.Name.Replace(' ','')) $($_.PID)"
}

Write-Output '<<<app_state>>>'
$Inventory | ? { $_.Type -eq 'APPSTATE' } | % {
    
    Write-Output "iisapp_$($_.Name.Replace(' ','')) $($_.PID)"
}
