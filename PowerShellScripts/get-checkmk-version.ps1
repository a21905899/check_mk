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


$hostversion = Invoke-Command -session $_ -ScriptBlock {



#Verifica se SO é superor a Windows 2K3
$OS = [Version](Get-ItemProperty -Path "$($Env:Windir)\System32\hal.dll" -ErrorAction SilentlyContinue).VersionInfo.FileVersion.Split()[0]

if ($OS.Major -gt 5) {



(Get-WmiObject win32_product | Where-Object {$_.Name -like "check*"}) | foreach {(Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain + "`t" + (Get-WmiObject -class Win32_OperatingSystem).Caption + "`t" + ($_.Name) + "`t" +($_.Version)}

}

else {
(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain+ "`t" + (Get-WmiObject -class Win32_OperatingSystem).Caption + "`t" + "Versão incompativel com update automático"
}

}

$hostversion >> C:\users\t02747\Documents\cmkversion.csv
}


Get-PSSession | Remove-PSSession












