    
   # Get-Content -Path .\Documents\updateagent.txt | where-object {$_ -like "*besp.dsp.gbes"} | foreach {
    
    $d = 'besp.dsp.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    $session = New-PSSession -ComputerName swsqltp24.besp.dsp.gbes -Credential $c -ErrorAction SilentlyContinue

    

 #   Get-PSSession | foreach {
        
    Invoke-Command -session (Get-PSSession) -ScriptBlock {

    $app = (Get-WmiObject win32_product | Where-Object {$_.Name -like "check_mk_agent.exe"})
    
    $app.Uninstall()
    rmdir -Recurse 'C:\program files(x86)\check_mk\plugins\'   
    }

    Get-PSSession | Remove-PSSession