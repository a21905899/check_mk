<#
 #
 #>

$s=Get-Service MSMQ -ErrorAction Stop

Write-Output '<<<MSMQ:sep(9)>>>'
Get-WmiObject -class Win32_PerfRawData_MSMQ_MSMQQueue | ForEach-Object {
    "$($_.MessagesinQueue)`t$($_.Name)"
}
