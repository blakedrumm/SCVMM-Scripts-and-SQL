# Modified by: Blake Drumm (blakedrumm@microsoft.com), Murat Coskun (coskunmurat@microsoft.com)
# -----------------------------------------------
# Edit the variables to be used for the script
# -----------------------------------------------
[bool]$Reassociate = $true # Reassociate the certificate if it is incorrect
[bool]$OverwritePreviousRuns = $true # Overwrite the output Text file: C:\temp\Each-ManagedHost-SelfSignedCertificate.txt
# -----------------------------------------------
# DO NOT EDIT BELOW THIS LINE
# -----------------------------------------------
$readhost = Read-Host "This will delete all the existing self-signed SCVMM certificates on your hosts.`n`n Are you sure you want to continue? (Y/N)"
if ($readhost -eq 'n')
{
	break
}
else
{
	if ($Reassociate)
	{
		$cred = Get-Credential
	}
	
	$FolderName = "C:\Temp\"
	if (Test-Path $FolderName)
	{
		Write-Verbose "C:\Temp folder exists skipping"
	}
	else
	{
		#PowerShell Create directory if not exists
		New-Item $FolderName -ItemType Directory
		Write-Host "Temp folder created on C:\ successfully" -BackgroundColor Green -ForegroundColor Black
	}
	if ($OverwritePreviousRuns)
	{
		Remove-Item 'C:\temp\Each-ManagedHost-SelfSignedCertificate.txt' -Force -Confirm:$false -ErrorAction SilentlyContinue
	}
	$ManagedHosts = Get-SCVMHost | Select-Object
	$servers = $Managedhosts.FQDN
	foreach ($server in $servers)
	{
		$Error.Clear()
		try
		{
			$invoke = Invoke-Command -ComputerName $server -ScriptBlock {
				$resolvedHost = $(([System.Net.Dns]::GetHostByName($env:computerName)).HostName)
				#$VerbosePreference = 'Continue'
				$text1 = "Deleting Self-Signed Certificates on $resolvedHost";
				Write-Host $text1 -BackgroundColor Green -ForegroundColor Black;
				Write-Output $text1;
				$gc = Get-ChildItem "Cert:\LocalMachine\my\" | Where-Object { $_.FriendlyName -eq "SCVMM_CERTIFICATE_KEY_CONTAINER$resolvedHost" }
				$gc | Remove-Item -Verbose;
				return $gc
			} -ErrorAction Stop
		}
		catch
		{
			$foundError = $error
		}
		if ($invoke)
		{
			$invoke | Out-File C:\temp\Each-ManagedHost-SelfSignedCertificate.txt -Append
			$text2 = "Recreating/Reassociating $($server) with SCVMM Server";
			Write-Host $text2 -BackgroundColor Green -ForegroundColor Black;
			Write-Output $text2 | Out-File C:\temp\Each-ManagedHost-SelfSignedCertificate.txt -Append;
			Get-ScvmmManagedcomputer -ComputerName $server | Register-SCVMMManagedComputer -Credential $cred | Format-List * | Out-String | Out-File C:\temp\Each-ManagedHost-SelfSignedCertificate.txt -Append;
			Write-Output "--------------------------------------------------------------------------" | Out-File C:\temp\Each-ManagedHost-SelfSignedCertificate.txt -Append;
		}
		else
		{
			Write-Host "Experienced error while connecting to '$server':`n$foundError"
			Write-Output "Experienced error while connecting to '$server':`n$foundError" | Out-File C:\temp\Each-ManagedHost-SelfSignedCertificate.txt -Append;
			Write-Output "--------------------------------------------------------------------------" | Out-File C:\temp\Each-ManagedHost-SelfSignedCertificate.txt -Append;
		}
	}
	write-host "The result has been copied to Each-ManagedHost-SelfSignedCertificate.txt" -BackgroundColor Green -ForegroundColor Black;
}
