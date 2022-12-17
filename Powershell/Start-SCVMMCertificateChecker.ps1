#Modified by: Blake Drumm (blakedrumm@microsoft.com), Murat Coskun (coskunmurat@microsoft.com)
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
	foreach ($SCCert in $SCCerts)
	{
		Write-Host "Connecting to host $($SCCert.DnsNameList)" -ForegroundColor Gray
		if ($SCCert.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*')
		{
			Write-Host "Getting the Host Certificate" -ForegroundColor Gray
			$ClientCerts = Invoke-Command -ComputerName $SCCert.DNSNameList -ScriptBlock {
				Get-ChildItem "Cert:\LocalMachine\My" | Where-Object {$_.FriendlyName -eq  "SCVMM_CERTIFICATE_KEY_CONTAINER$($ENV:COMPUTERNAME).$($ENV:USERDNSDOMAIN)"};
			}
			Write-Host "Comparing Host and VMM Cerificates" -ForegroundColor Gray
			if ($ClientCerts.Thumbprint -ne $SCCert.Thumbprint)
			{
				Write-Host "The Thumbprint don't match" -ForegroundColor Red
				Write-Host "Host Cert Thumbprint: $($ClientCerts.Thumbprint)" -ForegroundColor DarkRed
				Write-Host "VMM Server Cert Thumbprint: $($SCCert.Thumbprint)" -ForegroundColor DarkRed
				if ($Reassociate)
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
	}
}
else
{
	Write-Host "Did not find any certificates for SCVMM!" -ForegroundColor Red
} 

