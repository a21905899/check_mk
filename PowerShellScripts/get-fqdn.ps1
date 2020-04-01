 Get-Content -Path .\Documents\updateagent.txt | where-object {$_ -like "swsql*besq.dsq.gbes"} | foreach {
    
    $d = 'besq.dsq.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    New-PSSession -ComputerName  $_ -Credential $c #-ErrorAction SilentlyContinue

}
    
    Get-PSSession | foreach {
    
    $myFQDN = Invoke-Command -session $_ -ScriptBlock {

    (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain + "`t" +(Get-WmiObject -class Win32_OperatingSystem).Caption + "`t" + (ls -l "C:\Program Files (x86)\check_mk\plugins" )
   
   
    }
    $myFQDN >> C:\users\t02747\Documents\names_os.txt 
    
    }

    Get-PSSession | Remove-PSSession

    
