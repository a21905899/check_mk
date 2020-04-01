$d = 'marte.gbes'
$u = "UNAGIOSOF@$d"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force
$s = "S-OBLDSQL-01.$d"

$c = New-Object System.Management.Automation.PSCredential($u,$p)

New-PSSession -ComputerName $s -Credential $c | Enter-PSSession 
