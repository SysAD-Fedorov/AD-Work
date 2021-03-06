#########################################
# V2.2
# 2015-02-27
# Author Artyom Nijazov aka Th0mson
#########################################
cls
# ---------------------------------------------------------------------
# Checking Execution Policy
# ---------------------------------------------------------------------
#$Policy = "Unrestricted"
$Policy = "RemoteSigned"
If ((get-ExecutionPolicy) -ne $Policy) {
  Write-Host "Script Execution is disabled. Enabling it now"
  Set-ExecutionPolicy $Policy -Force
  Write-Host "Please Re-Run this script in a new powershell enviroment"
  Exit
}
############################# Global Settings #############################
# --------------------------------------------------------------------
# Define the variables.
# --------------------------------------------------------------------
$CompName = (Get-WMIObject -Class Win32_OperatingSystem).CSName
$PathLocation = $MyInvocation.MyCommand.Definition | split-path -parent
$OSMajor = $([System.Environment]::OSVersion.Version).Major
$OSMinor = $([System.Environment]::OSVersion.Version).Minor

#---------------- XML config load --------------------
$ConfigFile = New-Object System.Xml.XmlDocument
$ConfigFile.Load("$PathLocation\config.xml")
$PathScripts = $ConfigFile.Root.PathScript
$URL = $ConfigFile.Root.WebURL
$URL += "/config.xml"
$UpdateURL = $ConfigFile.Root.WebURL
#-----------------------------------------------------

$PathLogs = "$PathLocation\Logs"

$Date = $(Get-Date -Format dd-MM-yyyy)
$Counts=0
$Mess = @"
$CompName
-------------------
$Date
-------------------

"@
############################# End Settings ################################

########################## Update Procedure ###############################
#--------------------------- Check Update ---------------------------------
$SetupConfig = New-Object System.Xml.XmlDocument
$SetupConfig.Load("$URL")
$StatusUpdater = [int]($SetupConfig.Root.StatusUpdater)
If ($StatusUpdater -eq 1) {
	$Scriptname = $MyInvocation.MyCommand.Name
	foreach ($arg in $PathLocation) {            
        $FN = $arg.split("\")
    }            
	$PrName = ($FN[$FN.Count-1]).ToLower()
	$VerLoc = $ConfigFile.Root.Version
	$VerWeb = ($SetupConfig.Root.Scripts_List.SelectNodes("*") | 
				where {$_.title -ieq "$PrName"}).Version
	If ($([float]$VerLoc) -lt $([float]$VerWeb)) {
		Write-Host "Find new version of script"
		Write-Host "Updating..."
		If (!(test-path "$PathScripts\updater\updater.ps1")){
			Write-Host "Updater in $PathScripts\updater\ not found."
			Write-Host "Update not possible"
			Sleep 2
		}
		Else {
			Start-Process powershell.exe `
				"-ExecutionPolicy RemoteSigned `
				$PathScripts\updater\updater.ps1 $PrName $UpdateURL $Scriptname"
			sleep 2
			exit
		}
	}
}
# -------------------------------------------------------------------------
########################### End Update Procedure ##########################

##################### Function parser for Windows < 7 #####################
Function LogParseLTWin7{
	get-eventlog -list | ? {$_.Log -ne 'Security' -and $_.Entries.Count -gt 0} | 
	%{
		$NameLogs = $CompName
		$Count = (Get-EventLog -LogName $_.Log -after (get-date).AddHours(-24) |
				Where {$_.EntryType -Match "Error" -or $_.EntryType -Match "Critical"} |
				Measure-Object).Count

		IF ($Count -gt 0) {
			$Mess += $_.Log
			$Mess += " Error: "
			$Mess += $Count
			$Mess += " Count`n"
			$Mess += "-------------------`n"
			$Mess >> $PathLogs\report.txt

			$NameLogs += "_" + $_.Log + "_Logs.txt"
			$Mess | Out-File $PathLogs\$NameLogs
			#------------------------ Small report -------------------------
			Get-EventLog -LogName $_.Log -after (get-date).AddHours(-24) |
			Where {$_.EntryType -Match "Error" -or $_.EntryType -Match "Critical"} | 
			Sort Date | Sort time |
			Format-Table -GroupBy Source TimeWritten, EventID, Message -auto >> $PathLogs\report.txt
			#------------------------- Full report -------------------------
		
			Get-EventLog -after (get-date).AddHours(-24) -LogName $_.Log |
			Where {$_.EntryType -Match "Error" -or $_.EntryType -Match "Critical"} | 
			Sort Date | Sort time |
			Format-Table -GroupBy Source TimeWritten, EventID, Message -auto -Wrap >> $PathLogs\$NameLogs
		}

		$Mess = @"
$CompName
-------------------
$Date
-------------------

"@
	}
}
###########################################################################

#################### Function parser for Windows >= 7 #####################
Function LogParseGTWin7{
	 Get-WinEvent -listlog *  | ? {$_.RecordCount -gt 0} |
	%{
		$NameLogs = $CompName
		try{ 
			$Count = (Get-WinEvent -FilterHashtable @{logname=$_.LogName; Level=1..2; StartTime=(get-date).AddHours(-24)} -ErrorAction Stop).Count 
		}
		catch [System.Management.Automation.InvocationInfo] {
			$Count=0
		}
		catch [System.Exception] {
			$Count=0
		}
		
		IF ($Count -gt 0) {
			$Mess += $_.LogName
			$Mess += " Error: "
			$Mess += $Count
			$Mess += " Count`n"
			$Mess += "-------------------`n"
			$Mess >> $PathLogs\report.txt
			$regex =  $_.LogName -replace "\/", "_"
			$NameLogs += "_" + $regex + "_Logs.txt"
			$Mess | Out-File "$PathLogs\$NameLogs"
			#------------------------ Small report -------------------------
			Get-WinEvent -FilterHashtable @{logname=$_.LogName; Level=1..2; StartTime=(get-date).AddHours(-24)} | 
			Sort Date | Sort time |
			Format-Table -GroupBy ProviderName TimeCreated, ID, Message -auto >> $PathLogs\report.txt
			#------------------------- Full report -------------------------
		
			Get-WinEvent -FilterHashtable @{logname=$_.LogName; Level=1..2; StartTime=(get-date).AddHours(-24)} | 
			Sort Date | Sort time |
			Format-Table -GroupBy ProviderName TimeCreated, ID, Message -auto -Wrap >> "$PathLogs\$NameLogs"
		}

		$Mess = @"
$CompName
-------------------
$Date
-------------------

"@
	}
}
###########################################################################

################################ Begin ####################################
If ([int]$OSMajor -gt 5) { 
	LogParseGTWin7
}
Else {
	LogParseLTWin7
}

PowerShell -NoProfile -ExecutionPolicy RemoteSigned $PathLocation\SendLog.ps1
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
Sleep 2
################################## End ####################################
