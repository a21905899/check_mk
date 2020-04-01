

Start-Transcript -Path C:\users\t02747\Documents\logging\updatesqldzsplocal.txt 
Get-Content -Path c:\Users\t02747\Documents\scripts\others\hostnames.txt | where-object {$_ -like "*dzsp.local"} | foreach {

$_

$d = 'dzsp.local'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force
$h = $_

$c = New-Object System.Management.Automation.PSCredential($u,$p)



try {


New-PSSession -ComputerName $_ -Credential $c -ErrorAction stop}
catch  
    { 
        $errormsg = Write-Output $ErrorMessage
          } 
    if ($errormsg -like '*WinRM cannot process the request*')
        { 
        net use  \\$h\c$ /user:UNAGIOSOF@$d fRAr6dAsuHadRathERAgup
        }

    if(Test-Path -Path "\\$h\c$\Program Files (x86)\check_mk\plugins\MSSQL*.ps1")
    {
    echo "$h contém o ficheiro"
    Copy-Item C:\Users\t02747\Documents\scripts\PluginsCMK\MSSQL_20190411.ps1 -Destination "\\$_\c$\Program Files (x86)\check_mk\plugins\MSSQL_20190411.ps1"
    Remove-Item "\\$h\c$\Program Files (x86)\check_mk\plugins\MSSQL.ps1" -force
    if (Test-Path -Path "\\$h\c$\Program Files (x86)\check_mk\plugins\MSSQL_20190411.ps1")
        { 
        echo " O Host $h foi actualizado"
        }
    else {
    echo "Houve um problema com a cópia do ficheiro para o host $h"     
         }
   }
    
    }
    net use * /delete /y
    get-pssession | Disconnect-PSSession
    Get-PSSession | Remove-PSSession
Stop-Transcript 







 