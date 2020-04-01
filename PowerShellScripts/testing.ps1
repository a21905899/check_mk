$Service = (get-service | Where-Object {$_.Status -eq "Running" -and $_.name -like "checkmk*"})

(Get-WmiObject win32_product | Where-Object {$_.Name -like "check*"}) | foreach {(Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain + "`t" + (Get-WmiObject -class Win32_OperatingSystem).Caption + "`t" + ($_.Version) + "`t" + (echo "$Service")}