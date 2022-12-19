# Modified by: Blake Drumm (blakedrumm@microsoft.com), Murat Coskun (coskunmurat@microsoft.com)
# Collecting Host certificates from the VMM server's trusted people store
$SCCerts = Get-ChildItem "Cert:\LocalMachine\TrustedPeople" | Sort-Object
[bool]$Reassociate = $false

#Request VMM administrator credentials for Invoke-Command against Hosts
if ($Reassociate)
{
	$cred = Get-Credential
}

function Write-Console
{
	param
	(
		[string]$Text,
		$ForegroundColor,
		[switch]$NoNewLine
	)
	
	if ([Environment]::UserInteractive)
	{
		if ($ForegroundColor)
		{
			Write-Host $Text -ForegroundColor $ForegroundColor -NoNewLine:$NoNewLine
		}
		else
		{
			Write-Host $Text -NoNewLine:$NoNewLine
		}
	}
	else
	{
		Write-Output $Text
	}
	$Text | Out-File C:\Temp\SCVMM-CertChecker-Output.txt
}

if ($SCCerts.count -gt 0)
{
	$OverallCertCount = $SCCerts.Count
	$i = 0
	foreach ($SCCert in $SCCerts)
	{
		$i++
		$i = $i
		Write-Console "($i/$OverallCertCount) Connecting to host $($SCCert.DnsNameList)" -ForegroundColor Gray
		if ($SCCert.FriendlyName -like 'SCVMM_CERTIFICATE_KEY_CONTAINER*')
		{
			Write-Console "`t`tGetting the Host Certificate" -ForegroundColor Gray
			try
			{
				$ClientCerts = Invoke-Command -ComputerName $SCCert.DNSNameList -ErrorAction Stop -ScriptBlock {
					Get-ChildItem "Cert:\LocalMachine\My" | Where-Object { $_.FriendlyName -eq "SCVMM_CERTIFICATE_KEY_CONTAINER$(([System.Net.Dns]::GetHostByName($env:computerName)).HostName)" };
				}
			}
			catch
			{
				Write-Warning "Unable to connect to $($SCCert.DNSNameList), skipping"
				Write-Console ' '
				continue
			}
			Write-Console "`t`tComparing Host and VMM Cerificates" -ForegroundColor Gray
			if ($($ClientCerts.Thumbprint | Select-Object -First 1) -notmatch $($SCCert.Thumbprint | Select-Object -First 1))
			{
				Write-Console "`t`tThe Thumbprint doesn't match" -ForegroundColor Red
				Write-Console "`t`t   Host Cert Thumbprint:       $($ClientCerts.Thumbprint | Select-Object -First 1)" -ForegroundColor Red
				Write-Console "`t`t   VMM Server Cert Thumbprint: $($SCCert.Thumbprint)" -ForegroundColor Red
				if ($Reassociate)
				{
					Write-Console "`t`tReassociating the host with VMM to sync the cert" -ForegroundColor Yellow
					Get-ScvmmManagedcomputer -ComputerName $ClientCerts.PSComputerName | Register-SCVMMManagedComputer -Credential $cred
				}
			}
			else
			{
				Write-Console "`t`tCertificates Match" -ForegroundColor Green
			}
			if ($ClientCerts.NotAfter)
			{
				if ($($ClientCerts.NotAfter | Select-Object -First 1) -ge $(Date))
				{
					Write-Console "`t`tExpiration: $($ClientCerts.NotAfter | Select-Object -First 1)" -ForegroundColor Green
				}
				elseif ($($ClientCerts.NotAfter | Select-Object -First 1) -lt $(Date))
				{
					Write-Console "`t`tExpired: $($ClientCerts.NotAfter | Select-Object -First 1)" -ForegroundColor Red
				}
				else
				{
					Write-Console "`t`tUnknown issue, cannot detect Expiration" -ForegroundColor Yellow
				}
			}
			else
			{
				Write-Console "`t`tUnable to detect Expiration" -ForegroundColor Yellow
			}
			
			
		}
		Write-Console ' '
	}
}
else
{
	Write-Console "Did not find any certificates for SCVMM!" -ForegroundColor Red
}
