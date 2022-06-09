#Modified by: Blake Drumm (blakedrumm@microsoft.com)
#Collecting Host certificates from the VMM server's trusted people store
$SCCerts = Get-ChildItem "Cert:\LocalMachine\TrustedPeople" | Sort-Object
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
				Write-Warning "Unable to connect to $($SCCert.DNSNameList), skipping"
				Write-Host ' '
				continue
			}
			Write-Host "`t`tComparing Host and VMM Cerificates" -ForegroundColor Gray
			if ($($ClientCerts.Thumbprint | Select-Object -First 1) -notmatch $($SCCert.Thumbprint | Select-Object -First 1))
			{
				Write-Host "`t`tThe Thumbprint doesn't match" -ForegroundColor Red
				Write-Host "`t`t   Host Cert Thumbprint:       $($ClientCerts.Thumbprint | Select-Object -First 1)" -ForegroundColor Red
				Write-Host "`t`t   VMM Server Cert Thumbprint: $($SCCert.Thumbprint)" -ForegroundColor Red
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
			if ($ClientCerts.NotAfter)
			{
				if ($($ClientCerts.NotAfter | Select-Object -First 1) -ge $(Date))
				{
					Write-Host "`t`tExpiration: $($ClientCerts.NotAfter | Select-Object -First 1)" -ForegroundColor Green
				}
				elseif ($($ClientCerts.NotAfter | Select-Object -First 1) -lt $(Date))
				{
					Write-Host "`t`tExpired: $($ClientCerts.NotAfter | Select-Object -First 1)" -ForegroundColor Red
				}
				else
				{
					Write-Host "`t`tUnable to detect Expiration" -ForegroundColor DarkMagenta
				}
			}
			else
			{
				Write-Host "`t`tUnable to detect Expiration" -ForegroundColor DarkMagenta
			}
			
			
		}
		Write-Host ' '
	}
}
else
{
	Write-Host "Did not find any certificates for SCVMM!" -ForegroundColor Red
}
