#Modified by: Blake Drumm (blakedrumm@microsoft.com)
#Collecting Host certificates from the VMM server's trusted people store
$SCCerts = Get-ChildItem "Cert:\LocalMachine\TrustedPeople"
[bool]$Reassociate = $false

#Request VMM administrator credentials for Invoke-Command against Hosts
if ($Reassociate)
{
	$cred = Get-Credential
}

if ($SCCerts.count -gt 0)
{
	$OverallCertCount = $SCCerts.Count
	$i = 0
	foreach ($SCCert in $SCCerts)
	{
		$i++
		$i = $i
		Write-Host "($i/$OverallCertCount) Connecting to host $($SCCert.DnsNameList)" -ForegroundColor Gray
		if ($SCCert.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*')
		{
			Write-Host "`t`tGetting the Host Certificate" -ForegroundColor Gray
			try
			{
				$ClientCerts = Invoke-Command -ComputerName $SCCert.DNSNameList -ErrorAction Stop -ScriptBlock {
					Get-ChildItem "Cert:\LocalMachine\My" | Where-Object { $_.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*' };
				}
			}
			catch
			{
				Write-Warning "`t`tUnable to connect to $($SCCert.DNSNameList), skipping"
				Write-Host ' '
				continue
			}
			Write-Host "`t`tComparing Host and VMM Cerificates" -ForegroundColor Gray
			if ($($ClientCerts.Thumbprint | Select-Object -First 1) -notmatch $($SCCert.Thumbprint | Select-Object -First 1))
			{
				Write-Host "`t`tThe Thumbprint doesn't match" -ForegroundColor Red
				Write-Host "`t`tHost Cert Thumbprint:       $($ClientCerts.Thumbprint | Select-Object -First 1)" -ForegroundColor Red
				Write-Host "`t`tVMM Server Cert Thumbprint: $($SCCert.Thumbprint)" -ForegroundColor Red
				if ($Reassociate)
				{
					Write-Host "`t`tReassociating the host with VMM to sync the cert" -ForegroundColor Yellow
					Get-ScvmmManagedcomputer -ComputerName $ClientCerts.PSComputerName | Register-SCVMMManagedComputer -Credential $cred
				}
			}
			else
			{
				Write-Host "`t`tCertificates Match" -ForegroundColor Green
			}
			if ($ClientCerts.NotAfter -gt $(Date))
			{
				Write-Host "`t`tExpiration: $($ClientCerts.NotAfter | Select-Object -First 1)" -ForegroundColor Green
			}
			else
			{
				Write-Host "`t`Expired: $($ClientCerts.NotAfter | Select-Object -First 1)" -ForegroundColor Red
			}
			
		}
		Write-Host ' '
	}
}
else
{
	Write-Host "Did not find any certificates for SCVMM!" -ForegroundColor Red
}
