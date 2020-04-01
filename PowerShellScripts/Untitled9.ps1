#Start-Transcript -Path C:\users\t02747\Documents\logging\updatesqltranscriptstatus.txt 
Get-Content -Path c:\Users\t02747\Documents\scripts\others\hostnames.txt | where-object {$_ -like "*besseguros.pt"} | foreach {

$_

$d = 'besseguros.pt'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force
$h = $_

$c = New-Object System.Management.Automation.PSCredential($u,$p)

try 
    {
    New-PSSession -ComputerName $h -Credential $c -ErrorAction stop
    }
catch  
    {
    $errormsg = Write-Output $ErrorMessage
    } 
    
if ($errormsg -like '*'  )
         {
net use  \\$h\c$ /user:UNAGIOSOF@$d fRAr6dAsuHadRathERAgup 
         }
        
if (Test-Path -Path "\\$h\c$\Program Files (x86)\check_mk\plugins\MSSQL_20190411.ps1")
        {}
else {
    echo "$h " >> C:\users\t02747\Documents\logging\missinghosts.txt  
         }
   }
   

    
    
    net use * /delete /y
    get-pssession | Disconnect-PSSession
    Get-PSSession | Remove-PSSession
#Stop-Transcript 