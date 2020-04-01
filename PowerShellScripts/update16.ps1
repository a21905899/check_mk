    
  #lê hostnames e inicia ciclo de pssessions
    Get-Content -Path .\Documents\testhost.txt | where-object {$_ -like "*besq.dsq.gbes"} | foreach {
    
    $d = 'besq.dsq.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    New-PSSession -ComputerName  $_ -Credential $c -ErrorAction SilentlyContinue
    }
    

#entra nas PSSessions previamente criadas 
Get-PSSession | foreach {


Copy-Item -ToSession $_ -Path .\Documents\Agents\check_mk_agent16.msi -Destination "C:\Program Files (x86)\check_mk\" -ErrorAction SilentlyContinue 


Invoke-Command -session $_ -ScriptBlock {

#Verifica se SO é superor a Windows 2K3
$OS = [Version](Get-ItemProperty -Path "$($Env:Windir)\System32\hal.dll" -ErrorAction SilentlyContinue).VersionInfo.FileVersion.Split()[0]

if ($OS.Major -gt 5) {





# Instala nova versão. 
start-process 'C:\Program Files (x86)\check_mk\check_mk_agent16.msi'-ArgumentList '-passive' -wait


$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain


Get-NetFirewallRule | Where-Object -FilterScript {$_.DisplayName -eq "check_mk_agent.exe"} | Remove-NetFirewallRule
    
New-NetFirewallRule -DisplayName "New Check MK" -Direction Inbound -LocalPort 6556 -Protocol TCP -Action Allow

#testa se nova versão existe e remove ficheiros da versão anterior

if (Test-Path -path 'C:\Program Files (x86)\checkmk\') {
$app = (Get-WmiObject win32_product | Where-Object {$_.Name -like "Check_MK Agent"})
$app.Uninstall()

rmdir -Recurse 'C:\Program Files (x86)\check_mk\'   
}   

#Regista o host no Updater e força um update
#start-process -FilePath "C:\programdata\checkmk\agent\plugins\cmk-update-agent.exe" -argumentlist "register -s 10.221.168.13 -i monq -H $myFQDN -p http -U cmkadmin -P M0n1toriz@cao -v" -ErrorAction SilentlyContinue -Wait

#start-process -FilePath "C:\programdata\checkmk\agent\plugins\cmk-update-agent.exe" -argumentlist '-v' -ErrorAction SilentlyContinue -Wait

#restart ao serviço 
#restart-service "Check Mk Service"

}
}
}

 Get-PSSession | Remove-PSSession

