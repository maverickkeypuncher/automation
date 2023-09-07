$host_ip = '${netxIpAddress}'
$password = ConvertTo-SecureString '${windows_password}' -AsPlainText -Force 
$cred = New-Object System.Management.Automation.PSCredential ("${windows_user}", $password) 
$session = New-PSSession -cn $host_ip -Credential $cred 
Invoke-command -Session $session -Scriptblock {
												$pass = ConvertTo-SecureString '${AD_password}' -AsPlainText -Force
												$credad = New-Object System.Management.Automation.PSCredential ("${AD_username}",$pass) 
												Add-Computer -DomainName ${Domain} -OUPath "${ad_path}" -Credential $credad -restart –force}
												
Remove-PSSession -Session $session
