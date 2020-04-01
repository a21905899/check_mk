    Get-Content -Path .\Documents\firewall.txt | where-object {$_ -like "*besp.dsp.gbes"} | foreach {
  
  
    $d = 'besp.dsp.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    New-PSSession -ComputerName $_  -Credential $c #-ErrorAction SilentlyContinue

    }

    Get-PSSession | foreach {
        
    Invoke-Command -session (Get-PSSession) -ScriptBlock {

    Get-NetFirewallRule | Where-Object -FilterScript {$_.DisplayName -eq "check_mk_agent.exe"} | Remove-NetFirewallRule
    
    New-NetFirewallRule -DisplayName "New Check MK" -Direction Inbound -LocalPort 6556 -Protocol TCP -Action Allow
    }
    }
    Get-PSSession | Remove-PSSession

