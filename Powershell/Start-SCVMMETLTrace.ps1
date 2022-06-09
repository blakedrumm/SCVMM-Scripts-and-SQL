<#
	.SYNOPSIS
		Start-SCVMMETLTrace
	
	.DESCRIPTION
		This script will allow you to collect an SCVMM ETL Trace from System Center Virtual Machine Manager. aka. CARMINE Tracing.
	
	.PARAMETER OutputDirectory
		The Directory you want to export the SCVMM ETL Trace.
	
	.PARAMETER OutputZipName
		Change the default file name that the script uses to save the zipped output.
		
		Example: C:\VMMLogs\SCVMM-ETLTrace.zip
	
	.PARAMETER Sleep
		Optional: Seconds to sleep after starting an ETL Trace
	
	.EXAMPLE
		PS C:\> .\
	
	.NOTES
		Additional information about the file.
#>
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false,
			   Position = 0,
			   HelpMessage = 'The Directory you want to export the SCVMM ETL Trace.')]
	[string]$OutputDirectory,
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = 'Change the default file name that the script uses to save the zipped output. Example: SCVMM-ETLTrace.zip')]
	[string]$OutputZipName,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = 'Optional: Seconds to sleep after starting an ETL Trace')]
	[int64]$Sleep
)
BEGIN
{
	Function Get-TimeStamp
	{
		$TimeStamp = Get-Date -UFormat "%x %l:%M:%S %p"
		return "$TimeStamp - "
	}
	if (!$OutputDirectory)
	{
		$OutputDirectory = "$env:SystemDrive\VMMLogs"
	}
	Write-Output "$(Get-TimeStamp)Attempting to resolve: '$OutputDirectory'"
	$Path = try { Resolve-Path $OutputDirectory -ErrorAction Stop }
	catch { }
	$RunningPath = try { Resolve-Path "$OutputDirectory\Output" -ErrorAction Stop }
	catch { }
	
	if (!$Path)
	{
		try
		{
			Write-Output "$(Get-TimeStamp)Creating new folder for script output: '$OutputDirectory'"
			New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
		}
		catch
		{
			Write-Warning "Unable to create directory: '$OutputDirectory'. Attempt to create the folder manually and run the script again."
			break
		}
		
	}
	else
	{
		Write-Output "$(Get-TimeStamp)Found folder: '$OutputDirectory'"
	}
	if (!$RunningPath)
	{
		try
		{
			Write-Output "$(Get-TimeStamp)Creating new folder for ETL Trace Output: '$OutputDirectory\Output'"
			New-Item -ItemType Directory -Path $OutputDirectory\Output | Out-Null
		}
		catch
		{
			Write-Warning "Unable to create directory: '$OutputDirectory\Output'. Attempt to create the folder manually and run the script again."
		}
		$RunningPath = try { Resolve-Path "$OutputDirectory\Output" -ErrorAction Stop }
		catch { }
	}
	else
	{
		Get-ChildItem $RunningPath | Remove-Item -Force | Out-Null
	}
}
PROCESS
{
	Write-Output "$(Get-TimeStamp)Deleting any existing definition of the 'VMM' trace"
	logman delete VMM
	$ETLTraceFileNameTime = Get-Date -UFormat "%m_%d_%Y_%l-%M-%p"
	Write-Output "$(Get-TimeStamp)Creating a new definition of the 'VMM' trace"
	logman create trace VMM -v mmddhhmm -o $RunningPath\VMMLog_$env:computername-$ETLTraceFileNameTime.ETL -cnf 01:00:00 -p Microsoft-VirtualMachineManager-Debug -nb 10 250 -bs 16 -max 512
	
	Write-Output "$(Get-TimeStamp)Starting 'VMM' trace"
	logman start vmm
	
	if ($Sleep)
	{
		Write-Output "$(Get-TimeStamp)Sleeping for $Sleep seconds"
		Start-Sleep -Seconds $Sleep
	}
	else
	{
		Write-Output "$(Get-TimeStamp)Reproduce the issue and press ENTER once issue has been reproduced"
		Pause
	}
	Write-Output "$(Get-TimeStamp)Stopping 'VMM' trace"
	logman stop vmm
	Write-Output "$(Get-TimeStamp)Converting 'VMM' trace"
	$ETLFile = Resolve-Path "$RunningPath\VMMLog_$env:computername-$ETLTraceFileNameTime_*.ETL"
	Netsh trace convert "$ETLFile"
	#Zip output
	$Error.Clear()
	Write-Output "$(Get-TimeStamp)Creating zip file of all output data."
	[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
	[System.AppDomain]::CurrentDomain.GetAssemblies() | Out-Null
	if (!$OutputZipName)
	{
		[string]$destfilename = "$Path\VMM-ETLTrace_$env:computername-$ETLTraceFileNameTime.zip"
	}
	else
	{
		[string]$destfilename = $OutputZipName
	}
	
	IF (Test-Path $destfilename)
	{
		#File exists from a previous run on the same day - delete it
		Write-Output "$(Get-TimeStamp)Found existing zip file: $destfilename. Deleting existing file."
		Remove-Item $destfilename -Force
	}
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	$includebasedir = $false
	[System.IO.Compression.ZipFile]::CreateFromDirectory($RunningPath, $destfilename, $compressionLevel, $includebasedir) | Out-Null
	IF ($Error)
	{
		Write-Error "Error creating zip file."
	}
}
END
{
  start C:\Windows\explorer.exe -ArgumentList "/select, $destfilename"
	Write-Output "$(Get-TimeStamp)Script has completed!"
}
