Start-Transcript -Path .\Documents\logsqlupdate.txt -Append 

# init error file with nothing
Out-File -InputObject '' -FilePath ".\Documents\hostnames.error.$pid.log"

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


# copy files to existing connections
Get-PSSession | foreach {
    # backup file
    $copy_file = Invoke-Command -Session $_ -ScriptBlock {
        # if exists do nothing
        if (Test-Path -Path "C:\Program Files (x86)\check_mk\plugins\MSSQL_24072019.ps1") {
                ls "C:\Program Files (x86)\check_mk\plugins\MSSQL*.ps1*" -Exclude 'mssql-*','*24072019.ps1' | %  {rm $_  -ErrorAction Stop }
                 Write-Host " cleanup made in $($env:computername) "
            $false
        } else {
            # backup old files
            if(Test-Path -Path "C:\Program Files (x86)\check_mk\plugins\MSSQL*.ps1") {
                ls "C:\Program Files (x86)\check_mk\plugins\MSSQL*.ps1" -Exclude 'mssql-*' | %  {mv $_ "$_.old" -ErrorAction Stop}
                Write-Host  "files backed up in  $($env:computername) "
                
            }
            $true
        
        }
        }

    $agent_host = $_.ComputerName
    
    

    try {
        if ($copy_file) {
            Copy-Item -ToSession $_ -Path .\Documents\MSSQL_24072019.ps1 -Destination "C:\Program Files (x86)\check_mk\plugins\MSSQL_24072019.ps1" -ErrorAction SilentlyContinue
            echo "O plugin foi instalado no host $($_.ComputerName)"     
        }
    }
    catch { 
        Out-File -InputObject $agent_host -FilePath ".\Documents\hostnames.error.$pid.log" -Append
    }

}


# clean up
Get-PSSession | Disconnect-PSSession -ErrorAction SilentlyContinue
Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue

Stop-Transcript 