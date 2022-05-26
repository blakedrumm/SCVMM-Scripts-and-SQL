## Modify the below variables prior to running
[string[]]$Names = 'SCVMMHost1.contoso.com'
[bool]$Reassociate = $True
[bool]$GetInfo = $true
## DO NOT MODIFY BELOW THIS LINE

# Collecting Host certificates from the VMM server's trusted people store
[array]$SCCertsRaw = Get-ChildItem "Cert:\LocalMachine\TrustedPeople"
[array]$SCCerts = @()
if ($names)
{
	foreach ($name in $names)
	{
		
		$SCCerts += $SCCertsRaw | where { $_.Subject -like "*$name*" }
	}
}
else
{
	$SCCerts = $SCCertsRaw
}

if ($SCCerts.count -gt 0)
{
	foreach ($SCCert in $SCCerts)
	{
		Write-Host "Connecting to host $($SCCert.DnsNameList)" -ForegroundColor Gray
		if ($SCCert.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*')
		{
			Write-Host "Getting the Host Certificate" -ForegroundColor Gray
			$ClientCerts = invoke-command -ComputerName $SCCert.DNSNameList -ScriptBlock {
				Get-ChildItem "Cert:\LocalMachine\My" | where { $_.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*' };
			}
			Write-Host "Comparing Host and VMM Cerificates"
			if ($ClientCerts.SerialNumber -ne $SCCert.SerialNumber)
			{
				if ($GetInfo)
				{
					Write-Host "The Serial numbers don't match" -ForegroundColor Red
					Write-Host "Host Cert Serial Number: $($ClientCerts.SerialNumber)" -ForegroundColor DarkRed
					Write-Host "VMM Server Cert Serial Number: $($SCCert.SerialNumber)" -ForegroundColor DarkRed
				}
				if ($reassociate)
				{
					Write-Host "Reassociating the host with VMM to sync the cert" -ForegroundColor Yellow
					Get-ScvmmManagedcomputer -ComputerName $ClientCerts.PSComputerName | Register-SCVMMManagedComputer -Credential $cred
				}
			}
			else
			{
				Write-Host "Certificates Match" -ForegroundColor Green
			}
			Write-Host ""
		}
		else
		{
			$certfr = $SCCert.FriendlyName
			Write-Host "$certfr is not a SCVMM_CERTIFICATE_KEY_CONTAINER" -ForegroundColor Magenta
			Write-Host ""
		}
	}
}
else
{
	Write-Host "Did not find any certificates for SCVMM!" -ForegroundColor Red
}
