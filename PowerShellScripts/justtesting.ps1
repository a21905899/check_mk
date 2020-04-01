#Start-Transcript -Path C:\users\t02747\Documents\logging\updatesqltranscriptstatus.txt 
Get-Content -Path c:\Users\t02747\Documents\scripts\others\hostnames.txt | where-object {$_ -like "*besq.dsq.gbes"} | foreach {

$_

$d = 'besq.dsq.gbes'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force


$c = New-Object System.Management.Automation.PSCredential($u,$p)



try 
    {
    New-PSSession -ComputerName $_ -Credential $c -ErrorAction stop
    }
catch  
    {  
    $errormsg = Write-Output $ErrorMessage 
    } 
    
if ($errormsg -like '*WinRM cannot process the request*')
         {
#try      
{
net use  \\$_\c$ /user:UNAGIOSOF@$d fRAr6dAsuHadRathERAgup -ErrorAction stop
     }
     }
catch 
    { 
    $errormsg = Write-Output $ErrorMessage 
    }
if ($errormsg -like '*SMB1 protocol*' )
        {   
 echo "O host $_ funciona com o Protocolo SMB1" <#>>  C:\users\t02747\Documents\logging\statusupdatesql.txt #>
        }
        }
        }
   

<#Start-Transcript -Path c:\users\t02747\Documents\logging\testpathbesq.txt -Append 
#Get-Content -Path c:\Users\t02747\Documents\scripts\others\hostnames.txt | where-object {$_ -like "*besq.dsq.gbes"} | foreach {

$_

$d = 'besq.dsq.gbes'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force
$_ = 'ISU-FES1Q.besq.dsq.gbes'

$c = New-Object System.Management.Automation.PSCredential($u,$p)



try {


New-PSSession -ComputerName $_ -Credential $c -ErrorAction stop}
catch  
{ 
        $errormsg = Write-Output $ErrorMessage
          } 
    if ($errormsg -like '*WinRM cannot process the request*')
        { 
        net use  \\$_\c$ /user:UNAGIOSOF@$d fRAr6dAsuHadRathERAgup
        }
    
        #  if ($o -like '*WinRM cannot process the request*') 
         # { echo "IT fucking worked" }

         # $o
<#    if(Test-Path -Path "\\$_\c$\Program Files (x86)\check_mk\plugins\MSSQL_20190411.ps1")
    {}
    else {
    Copy-Item C:\Users\t02747\Documents\scripts\PluginsCMK\MSSQL_20190411.ps1 -Destination "\\$_\c$\Program Files (x86)\check_mk\plugins\MSSQL_20190411.ps1"
    echo "O plugin foi instalado no host $_"     
         }
    
  #>   
 #  } #>
    
    net use * /delete /y 
    get-pssession | Disconnect-PSSession
    Get-PSSession | Remove-PSSession
Stop-Transcript 