Start-Transcript -Path c:\users\t02747\Documents\logging\testpathbesq.txt -Append 
Get-Content -Path c:\Users\t02747\Documents\scripts\others\hostnames.txt | where-object {$_ -like "*besq.dsq.gbes"} | foreach {

$_

$d = 'besq.dsq.gbes'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force


try {
$c = New-Object System.Management.Automation.PSCredential($u,$p)



New-PSSession -ComputerName $_ -Credential $c 


    if(Test-Path -Path "\\$_\c$\Program Files (x86)\check_mk\plugins\MSSQL_20190411.ps1")
    {}
    else {
    Copy-Item C:\Users\t02747\Documents\scripts\PluginsCMK\MSSQL_20190411.ps1 -Destination "\\$_\c$\Program Files (x86)\check_mk\plugins\MSSQL_20190411.ps1"
    echo "O plugin foi instalado no host $_"     
         }
    }
    catch { 
    echo "Erro na cópida do ficheiro no Servidor $_"
          } 
   }
    
    
    get-pssession | Disconnect-PSSession
    Get-PSSession | Remove-PSSession
Stop-Transcript 