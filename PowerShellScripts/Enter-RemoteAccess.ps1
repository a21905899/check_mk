param (
    $domain = 'besp.dsp.gbes',
    $server = "swgomfp01.$domain"
)

 

#credentials
$u = "UNAGIOSOF@$domain"
$p = 'fRAr6dAsuHadRathERAgup' | ConvertTo-SecureString -asPlainText -Force
$c = New-Object System.Management.Automation.PSCredential($u,$p)

 

New-PSSession -ComputerName $server -Credential $c | Enter-PSSession

 

