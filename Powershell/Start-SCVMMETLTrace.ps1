<#
	.SYNOPSIS
		Start-SCVMMETLTrace
	
	.DESCRIPTION
		This script will allow you to collect an SCVMM ETL Trace from System Center Virtual Machine Manager. aka. CARMINE Tracing.
	
	.PARAMETER CircularLogging
		Turn on Circular Logging for SCVMM ETL Trace, use this for long captures that may take a long time to gather.
	
	.PARAMETER OutputDirectory
		The Directory you want to export the SCVMM ETL Trace.
	
	.PARAMETER OutputZipName
		Change the default file name that the script uses to save the zipped output.
		
		Example: C:\VMMLogs\SCVMM-ETLTrace.zip
	
	.PARAMETER Servers
		List of servers (local or remote) that you would like to gather an SCVMM ETL Trace from.
	
	.PARAMETER Sleep
		Optional: Seconds to sleep after starting an ETL Trace
	
	.EXAMPLE
		Example:
		Start an SCVMM ETL Trace for 120 seconds that saves to the output 
		directory: C:\temp\VMM-ETLTrace, that has circular logging turned on 
		so you do not fill the drive with ETL Trace Logging for VMM.

		PS C:\> .\Start-SCVMMETLTrace -Servers VMMHost1.contoso.com, VMMHost2.contoso.com -Sleep 120 -OutputDirectory C:\temp\VMM-ETLTrace -CircularLogging
	
	.NOTES
		AUTHOR: Blake Drumm (blakedrumm@microsoft.com)
		WEBSITE: https://blakedrumm.com/
		CREATED: June 9th, 2022
		MODIFIED: June 14th, 2022
#>
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false,
			   Position = 0,
			   HelpMessage = 'Turn on Circular Logging for SCVMM ETL Trace, use this for long captures that may take a long time to gather.')]
	[switch]$CircularLogging,
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = 'The Directory you want to export the SCVMM ETL Trace.')]
	[string]$OutputDirectory,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = 'Change the default file name that the script uses to save the zipped output. Example: SCVMM-ETLTrace.zip',
			   DontShow = $true)]
	[string]$OutputZipName,
	[Parameter(Position = 3,
			   HelpMessage = 'List of servers (local or remote) that you would like to gather an SCVMM ETL Trace from.')]
	[array]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 4,
			   HelpMessage = 'Optional: Seconds to sleep after starting an ETL Trace')]
	[int64]$Sleep
)
Function Get-TimeStamp
{
	$TimeStamp = Get-Date -UFormat "%x %l:%M:%S %p"
	return "$TimeStamp - "
}
function Start-SCVMMETLTrace
{
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 0,
				   HelpMessage = 'Turn on Circular Logging for SCVMM ETL Trace, use this for long captures that may take a long time to gather.')]
		[switch]$CircularLogging,
		[Parameter(Mandatory = $false,
				   Position = 1,
				   HelpMessage = 'The Directory you want to export the SCVMM ETL Trace.')]
		[string]$OutputDirectory,
		[Parameter(Mandatory = $false,
				   Position = 2,
				   HelpMessage = 'Change the default file name that the script uses to save the zipped output. Example: SCVMM-ETLTrace.zip',
				   DontShow = $true)]
		[string]$OutputZipName,
		[Parameter(Position = 3,
				   HelpMessage = 'List of servers (local or remote) that you would like to gather an SCVMM ETL Trace from.')]
		[array]$Servers,
		[Parameter(Mandatory = $false,
				   Position = 4,
				   HelpMessage = 'Optional: Seconds to sleep after starting an ETL Trace')]
		[int64]$Sleep
	)
	
	if (!$OutputDirectory)
	{
		$OutputDirectory = "$env:SystemDrive\VMMLogs"
	}
	<#
	.SYNOPSIS
		A brief description of the Inner-ETLTraceFunction function.
	
	.DESCRIPTION
		A detailed description of the Inner-ETLTraceFunction function.
	
	.PARAMETER CircularLogging
		Turn on Circular Logging for SCVMM ETL Trace, use this for long captures that may take a long time to gather.
	
	.PARAMETER OutputDirectory
		The Directory you want to export the SCVMM ETL Trace.
	
	.PARAMETER OutputZipName
		Change the default file name that the script uses to save the zipped output. Example: SCVMM-ETLTrace.zip
	
	.PARAMETER Remote
		Internal script switch.
	
	.PARAMETER Servers
		List of servers (local or remote) that you would like to gather an SCVMM ETL Trace from.
	
	.PARAMETER Sleep
		Optional: Seconds to sleep after starting an ETL Trace
	
	.EXAMPLE
				PS C:\> Inner-ETLTraceFunction
	
	.NOTES
		Additional information about the function.
#>
	function Inner-ETLTraceFunction
	{
		param
		(
			[Parameter(Mandatory = $false,
					   Position = 0,
					   HelpMessage = 'Turn on Circular Logging for SCVMM ETL Trace, use this for long captures that may take a long time to gather.')]
			[switch]$CircularLogging,
			[Parameter(Mandatory = $false,
					   Position = 1,
					   HelpMessage = 'The Directory you want to export the SCVMM ETL Trace.')]
			[string]$OutputDirectory,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = 'Change the default file name that the script uses to save the zipped output. Example: SCVMM-ETLTrace.zip')]
			[string]$OutputZipName,
			[Parameter(Position = 3,
					   HelpMessage = 'Internal script switch.')]
			[switch]$Remote,
			[Parameter(Position = 4,
					   HelpMessage = 'List of servers (local or remote) that you would like to gather an SCVMM ETL Trace from.')]
			[array]$Servers,
			[Parameter(Mandatory = $false,
					   Position = 5,
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
		}
		PROCESS
		{
			if (!$OutputDirectory)
			{
				$OutputDirectory = "$env:SystemDrive\VMMLogs"
			}
			Write-Host "$(Get-TimeStamp)Currently running against: $env:COMPUTERNAME"
			Write-Host "$(Get-TimeStamp)Attempting to resolve: '$OutputDirectory'"
			$Path = try { Resolve-Path $OutputDirectory -ErrorAction Stop }
			catch { }
			$RunningPath = try { Resolve-Path "$OutputDirectory\Output" -ErrorAction Stop }
			catch { }
			
			if (!$Path)
			{
				try
				{
					Write-Host "$(Get-TimeStamp)Creating new folder for script output: '$OutputDirectory'"
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
				Write-Host "$(Get-TimeStamp)Found folder: '$OutputDirectory'"
			}
			if (!$RunningPath)
			{
				try
				{
					Write-Host "$(Get-TimeStamp)Creating new folder for ETL Trace Output: '$OutputDirectory\Output'"
					New-Item -ItemType Directory -Path "$OutputDirectory\Output" | Out-Null
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
				Write-Host "$(Get-TimeStamp)Clearing items in path: '$RunningPath\*'"
				Get-ChildItem $RunningPath | Remove-Item -Force | Out-Null
			}
			Write-Host "$(Get-TimeStamp)Deleting any existing definition of the 'VMM' trace"
			logman delete VMM
			$ETLTraceFileNameTime = Get-Date -UFormat "%m_%d_%Y_%l-%M-%p"
			Write-Host "$(Get-TimeStamp)Creating a new definition of the 'VMM' trace"
			Write-Host "$(Get-TimeStamp)Trace is being exported to this location temporarily: $RunningPath\VMMLog_$env:computername-$ETLTraceFileNameTime.ETL"
			if ($CircularLogging)
			{
				Write-Host "$(Get-TimeStamp)- Circular Logging"
				logman create trace VMM -v mmddhhmm -o "$RunningPath\VMMLog_$env:computername-$ETLTraceFileNameTime.ETL" -f bincirc -ow -p Microsoft-VirtualMachineManager-Debug -max 512
			}
			else
			{
				Write-Host "$(Get-TimeStamp)- Standard Logging"
				logman create trace VMM -v mmddhhmm -o "$RunningPath\VMMLog_$env:computername-$ETLTraceFileNameTime.ETL" -cnf 01:00:00 -p Microsoft-VirtualMachineManager-Debug -nb 10 250 -bs 16 -max 512
			}
			
			Write-Host "$(Get-TimeStamp)Starting 'VMM' trace"
			logman start vmm
			
			if ($Sleep)
			{
				Write-Host "$(Get-TimeStamp)Sleeping for $Sleep seconds"
				Start-Sleep -Seconds $Sleep
			}
			else
			{
				Write-Host "$(Get-TimeStamp)Reproduce the issue and press ENTER once issue has been reproduced"
				Pause
			}
			Write-Host "$(Get-TimeStamp)Stopping 'VMM' trace"
			logman stop vmm
			Write-Host "$(Get-TimeStamp)Converting 'VMM' trace"
			$ETLFile = Resolve-Path "$RunningPath\VMMLog_$env:computername-$ETLTraceFileNameTime*.ETL"
			Netsh trace convert "$ETLFile"
			#Zip output
			$Error.Clear()
			Write-Host "$(Get-TimeStamp)Creating zip file of all output data."
			[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
			[System.AppDomain]::CurrentDomain.GetAssemblies() | Out-Null
			if (!$OutputZipName)
			{
				$OutputZipName = "VMM-ETLTrace_$env:computername-$ETLTraceFileNameTime.zip"
			}
			[string]$destfilename = "$OutputDirectory\$OutputZipName"
			IF (Test-Path $destfilename)
			{
				#File exists from a previous run on the same day - delete it
				Write-Host "$(Get-TimeStamp)Found existing zip file: $destfilename. Deleting existing file."
				Remove-Item $destfilename -Force -Confirm:$false
			}
			$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
			$includebasedir = $false
			[System.IO.Compression.ZipFile]::CreateFromDirectory($RunningPath, $destfilename, $compressionLevel, $includebasedir) | Out-Null
			IF ($Error)
			{
				Write-Error "Error creating zip file."
			}
			Write-Host "$(Get-TimeStamp)Cleaning up items in path: '$RunningPath\*'"
			Get-ChildItem $RunningPath | Remove-Item -Force | Out-Null
		}
		END
		{
			return
		}
	}
	$InnerSCVMMETLTraceFunction = "function Inner-ETLTraceFunction { ${function:Inner-ETLTraceFunction} }"
	$ETLTraceFileNameTime = Get-Date -UFormat "%m_%d_%Y_%l-%M-%p"
	$OutputDirectory
	if ($Servers)
	{
		foreach ($Server in $Servers)
		{
			if (!$OutputZipName)
			{
				$OutputZipNameFinal = "VMM-ETLTrace_$Server-$ETLTraceFileNameTime.zip"
				[string]$destfilename = "$OutputDirectory\$OutputZipNameFinal"
			}
			else
			{
				[string]$destfilename = "$OutputDirectory\$OutputZipName"
			}
			if (!(Test-Path -Path $OutputDirectory))
			{
				New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
			}
			if ($server -notmatch "^$env:COMPUTERNAME")
			{
				$MainScriptOutput += Invoke-Command -ComputerName $Server -ArgumentList $InnerSCVMMETLTraceFunction, $Sleep, $OutputDirectory, $OutputZipNameFinal, $CircularLogging -ScriptBlock {
					Param ($script,
						$Sleep,
						$OutputDirectory,
						$OutputZipNameFinal,
						$CircularLogging)
					. ([ScriptBlock]::Create($script))
					Inner-ETLTraceFunction -Sleep $Sleep -OutputDirectory $OutputDirectory -OutputZipName $OutputZipNameFinal -CircularLogging:$CircularLogging -Remote
				} -ErrorAction SilentlyContinue
				
				try
				{
					Write-Host "$(Get-TimeStamp)Transferring using Move-Item: FROM: \\$Server\$($destfilename.Replace(":", "$")) TO: $OutputDirectory"
					Move-Item "\\$Server\$($destfilename.Replace(":", "$"))" $OutputDirectory -force -ErrorAction Stop;
					Write-Host "$(Get-TimeStamp)Transfer Completed!"
					Write-Host " "
					continue
				}
				catch
				{
					Write-Warning $_
				}
			}
			else
			{
				Inner-ETLTraceFunction -Sleep $Sleep -OutputDirectory $OutputDirectory -OutputZipName $OutputZipNameFinal -CircularLogging:$CircularLogging
			}
		}
		
	}
	else
	{
		Inner-ETLTraceFunction -Sleep $Sleep -OutputDirectory $OutputDirectory -OutputZipName $OutputZipName
	}
	
	if ($(try { Get-Command 'explorer.exe' -ErrorAction Stop }
			catch { return $null }))
	{
		Start-Process -FilePath 'C:\Windows\explorer.exe' -ArgumentList "/select, $destfilename"
	}
	Write-Host "$(Get-TimeStamp)Script has completed!"
}
if ($OutputDirectory -or $OutputZipName -or $Servers -or $Sleep -or $CircularLogging)
{
	Start-SCVMMETLTrace -OutputDirectory $OutputDirectory -OutputZipName $OutputZipName -Servers $Servers -Sleep $Sleep -CircularLogging:$CircularLogging
}
else
{
	<#
		Example:
		Start an SCVMM ETL Trace for 120 seconds that saves to the output 
		directory: C:\temp\VMM-ETLTrace, that has circular logging turned on 
		so you do not fill the drive with ETL Trace Logging for VMM.
			Start-SCVMMETLTrace -Servers VMMHost1.contoso.com, VMMHost2.contoso.com -Sleep 120 -OutputDirectory C:\temp\VMM-ETLTrace -CircularLogging
	#>
	Start-SCVMMETLTrace -Servers AINSLEBL-H1.northamerica.corp.microsoft.com, JOCARVA-H2.northamerica.corp.microsoft.com -Sleep 1 -CircularLogging
}
