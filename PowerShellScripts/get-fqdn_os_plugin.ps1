 Get-Content -Path .\Documents\testaccess.txt | where-object {$_ -like "*marte.gbes"} | foreach {
    
    $d = 'marte.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    New-PSSession -ComputerName  $_ -Credential $c #-ErrorAction SilentlyContinue

}
    
    Get-PSSession | foreach {

    
    
    $myFQDN = Invoke-Command -session $_ -ScriptBlock {
    
    
   
    
    $o=""
    $plugin= Get-ChildItem -path  "C:\Program Files (x86)\check_mk\plugins\" -Recurse | foreach {$o+= "$_`t"}
    (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain+ "`t" + (Get-WmiObject -class Win32_OperatingSystem).Caption + "`t" + (echo $o) | Sort-Object
    }
   
    

    
    $myFQDN >> C:\users\t02747\Documents\names_os_swasip.csv
    
    }
    

    Get-PSSession | Remove-PSSession

    
