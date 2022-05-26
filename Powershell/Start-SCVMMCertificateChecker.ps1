#collecting Host certificates from the VMM server's trusted people store

Set-location Cert:\LocalMachine\TrustedPeople
$SCCerts = GCI

#Provide VMM administrator credentials
$cred = get-credential

if ($SCCerts.count -gt 0)
{
	foreach ($SCCert in $SCCerts)
	{
		Write-Host "Connecting to host $($SCCert.DnsNameList)" -ForegroundColor Gray
		if ($SCCert.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*')
		{
			Write-Host "Getting the Host Certificate" -ForegroundColor Gray
			$ClientCerts = invoke-command -ComputerName $SCCert.DNSNameList -ScriptBlock { Set-Location Cert:\LocalMachine\My; $Certs = Get-ChildItem | where { $_.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*' }; $Certs }
			Write-Host "Comparing Host and VMM Cerificates" -ForegroundColor Gray
			if ($ClientCerts.SerialNumber -ne $SCCert.SerialNumber)
			{
				Write-Host "The Serial numbers don't match" -ForegroundColor Red
				Write-Host "Host Cert Serial Number: $($ClientCerts.SerialNumber)" -ForegroundColor DarkRed
				Write-Host "VMM Server Cert Serial Number: $($SCCert.SerialNumber)" -ForegroundColor DarkRed
				#Write-Host "Reassociating the host with VMM to sync the cert" -ForegroundColor Yellow                    
				#Get-ScvmmManagedcomputer -ComputerName $ClientCerts.PSComputerName  | Register-SCVMMManagedComputer -Credential $cred   
			}
			else
			{
				Write-Host "Certificates Match" -ForegroundColor Green
			}
			Write-Host ""
		}
	}
}  
