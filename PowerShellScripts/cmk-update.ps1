 Get-Content -Path .\Documents\testhost.txt | where-object {$_ -like "*besq.dsq.gbes"} | foreach {
    
    $d = 'besq.dsq.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    New-PSSession -ComputerName $_ -Credential $c -ErrorAction SilentlyContinue

    }

   get-pssession | foreach {
    
    Invoke-Command -session $_ -ScriptBlock {

    $myFQDN = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

    start-process -FilePath "C:\Program Files (x86)\check_mk\plugins\cmk-update-agent.exe" -argumentlist "register -s 10.221.168.13 -i monq -H $myFQDN -p http -U cmkadmin -P M0n1toriz@cao -v" -ErrorAction SilentlyContinue -Wait

    start-process -FilePath "C:\Program Files (x86)\check_mk\plugins\cmk-update-agent.exe" -argumentlist '-v' -ErrorAction SilentlyContinue -Wait

    }
    }

    Get-PSSession | Disconnect-PSSession
