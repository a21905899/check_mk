$d = 'besp.dsp.cd gbes'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force
$s = "sw000053.$d"

$c = New-Object System.Management.Automation.PSCredential($u,$p)

#s-esi01n007-01.marte.gbes swmfsip54rc.besp.dsp.gbes




New-PSSession -ComputerName $s -Credential $c | Enter-PSSession

#

#(Invoke-WebRequest -Uri http://swisuaq20.besq.dsq.gbes/tibcologqua/).RawContent

#Get-WMIObject win32_logicaldisk -ComputerName Server1 -Credential $c

