Start-Transcript -Path .\Documents\logsqlupdate.txt -Append 

# init error file with nothing
#Out-File -InputObject '' -FilePath ".\Documents\hostnames.error.$pid.log"

# create all connections
Get-Content -Path .\Documents\hostnames.txt | where-object {$_ -like "*besp.dsp.gbes"} | foreach {
    $d = 'besp.dsp.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $agent_host = $_

    try {
        $c = New-Object System.Management.Automation.PSCredential($u,$p)

        New-PSSession -ComputerName $_ -Credential $c -ErrorAction Stop
    }
    catch { 
        Out-File -InputObject $agent_host -FilePath ".\Documents\hostnames.error.$pid.log" -Append
    }
}



Get-PSSession | % {
    # backup file
    $copy_file = Invoke-Command -Session $_ -ScriptBlock {
        # Check if exists
        if (Test-Path -Path 'C:\Program Files (x86)\check_mk\plugins\mssql-auditfiles.ps1.old') {
                Rename-Item -Path 'C:\Program Files (x86)\check_mk\plugins\mssql-auditfiles.ps1.old' -NewName "mssql-auditfiles.ps1" 
                
            }
            
        }
}







# clean up
Get-PSSession | Disconnect-PSSession -ErrorAction SilentlyContinue
Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue

Stop-Transcript 