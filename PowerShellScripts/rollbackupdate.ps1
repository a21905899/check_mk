    
    Get-Content -Path .\Documents\updateagent.txt | where-object {$_ -like "besq.dsq.gbes"} | foreach {
    
    $d = 'besq.dsq.gbes'
    $u = "UNAGIOSOF@$d"
    $p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force

    $c = New-Object System.Management.Automation.PSCredential($u,$p)

    $session = New-PSSession -ComputerName $_ -Credential $c -ErrorAction SilentlyContinue

    }

Get-PSSession | foreach {


Copy-Item -ToSession $_ -Path .\Documents\Agents\check-mk-agent_old.msi -Destination "C:\Program Files (x86)\check_mk\" -ErrorAction SilentlyContinue

Invoke-Command -session $_ -ScriptBlock {

Rename-Item -Path 'C:\Program Files (x86)\check_mk\plugins' 'C:\Program Files (x86)\check_mk\plugins_old'

start-process 'C:\Program Files (x86)\check_mk\check-mk-agent_old.msi' -ArgumentList '-passive' -wait

#copy-item 'C:\Program Files (x86)\check_mk\plugins_old\*.*' 'C:\Program Files (x86)\check_mk\plugins\' 

#rmdir -Recurse 'C:\Program Files (x86)\check_mk\plugins_old' 

#cd  'C:\Program Files (x86)\check_mk\plugins'

#Get-ChildItem MSSQL*.ps1| Rename-Item -NewName { $_.Name.Replace('.ps1','.ps1_old')  } 

#cd  'C:\Program Files (x86)\check_mk\'

#$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain


#start-process -FilePath "C:\Program Files (x86)\check_mk\plugins\cmk-update-agent.exe" -argumentlist "register -s 10.221.168.13 -i monq -H $myFQDN -p http -U cmkadmin -P M0n1toriz@cao -v" -ErrorAction SilentlyContinue -Wait

#start-process -FilePath "C:\Program Files (x86)\check_mk\plugins\cmk-update-agent.exe" -argumentlist '-v' -ErrorAction SilentlyContinue -Wait

restart-service check_mk_agent


}
}

 Get-PSSession | Remove-PSSession

    #C:\Program Files (x86)\check_mk\plugins\cmk-update-agent.exe register -s 10.221.168.13 -i monq -H SWGOMFP01.besp.dsp.gbes -p http -U cmkadmin -P 'M0n1toriz@cao' -v
    
    #<Invoke-Command -session $session -ScriptBlock {

    #$app = (Get-WmiObject win32_product | Where-Object {$_.Name -match "Check_MK Agent"})
    
    ##$app.Uninstall() } 

    #Invoke-Command -session $session -ScriptBlock { 
    #(rmdir -path "C:\Program Files (x86)\check_mk" )
    #} -ErrorAction SilentlyContinue
