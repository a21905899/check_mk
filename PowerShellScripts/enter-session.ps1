 #Get-Content -Path .\Documents\updateagent.txt | where-object {$_ -like "*marte.gbes"} | foreach {
    
    $d = 'besq.dsq.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    New-PSSession -ComputerName swmiswq01.besq.dsq.gbes  -Credential $c #-ErrorAction SilentlyContinue

    get-pssession | Enter-PSSession
     
   # Invoke-Command -session $session -ScriptBlock {

   # start-process -FilePath "C:\Program Files (x86)\check_mk\plugins\cmk-update-agent.exe" -argumentlist '-v' -ErrorAction SilentlyContinue -Wait

#    }



