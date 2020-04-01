$d = 'besq.dsq.gbes'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force
$s = "swiiswq22.$d"

$c = New-Object System.Management.Automation.PSCredential($u,$p)

New-PSSession -ComputerName $s -Credential $c | Enter-PSSession

#&net use  \\swiiswq22.besq.dsq.gbes\c$ /user:UNAGIOSOF@besq.dsq.gbes fRAr6dAsuHadRathERAgup

#(Invoke-WebRequest -Uri http://swisuaq20.besq.dsq.gbes/tibcologqua/).RawContent

#Get-WMIObject win32_logicaldisk -ComputerName Server1 -Credential $c