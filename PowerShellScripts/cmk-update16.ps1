 Get-Content -Path .\Documents\testhost.txt | where-object {$_ -like "*besq.dsq.gbes"} | foreach {
    
    $d = 'besq.dsq.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    $session= New-PSSession -ComputerName $_ -Credential $c -ErrorAction SilentlyContinue

    }

   get-pssession | foreach {
    
    Invoke-Command -session (Get-PSSession) -ScriptBlock {

    

    start-process -FilePath "C:\programdata\checkmk\agent\plugins\cmk-update-agent.exe" -argumentlist '-v' -ErrorAction SilentlyContinue -Wait

   }
   }
   Get-PSSession | Remove-PSSession