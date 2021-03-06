#########################################
# V2.0
# 2014-12-02
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
$CompName=(Get-WMIObject -Class Win32_OperatingSystem).CSName
$PathLocation = $MyInvocation.MyCommand.Definition | split-path -parent
$PathLogs = "$PathLocation\Logs"
$Date = $(Get-Date -Format yyyyMMdd)
$FilesLogs = @()
$include=@('*_logs.txt', 'report.txt', '*.7z')

#---------------- XML config load --------------------
$ConfigFile = New-Object System.Xml.XmlDocument
$ConfigFile.Load("$PathLocation\config.xml")
$PathScripts = $ConfigFile.Root.PathScript
$URL = $ConfigFile.Root.WebURL
$URL += "/config.xml"
$UpdateURL = $ConfigFile.Root.WebURL
#-----------------------------------------------------

# Проверка наличия архиватора
if (-not (test-path "$PathScripts\7zip\7z.exe"))
	{throw "$PathScripts\7zip\7z.exe needed"}
Set-alias sz "$PathScripts\7zip\7z.exe"

# Определение переменных настроек почты из config.xml
$emailSmtpServer = $ConfigFile.root.MailConfig.SMTPServer
$emailFrom = $ConfigFile.root.MailConfig.FromEmail
$emailTo = $ConfigFile.root.MailConfig.ToEmail
$encoding = [System.Text.Encoding]::UTF8

# Формирование письма
## Формирование заголовка письма
$emailSubject = "Event Log monitor result on server $CompName $(Get-Date -Format dd.MM.yyyy)"
## Формирование Тела письма
$emailBody = @"
$(Get-Date -Format dd.MM.yyyy)
Log monitor $CompName result. See attachment file
"@
$Attachment = @()
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

################################# Begin ###################################
Write-Host '-----------------------------------'
$FilesLogs += Get-ChildItem -Path $PathLogs -Include *_Logs.txt -Name

If (($FilesLogs.Length -gt 0) -and ("$FilesLogs" -ne "")) {
	Write-Host "Archiving"$FilesLogs.Length"Log Files"
	Write-Host '-----------------'
	# Архивирование Logs
	sz a -t7z -m1=LZMA2 -mmt=8 -mx3 -r "$PathLogs\Logs_$Date.7z" "$PathLogs\*_Logs.txt"
	$Attachment += "$PathLogs\Logs_$Date.7z"
	Write-Host '-----------------------------------'
}
Write-Host "Sending email..."
Write-Host '-----------------------------------'
If (($Attachment.Length -eq 0) -or ("$FilesLogs" -eq "")){
	Write-Host "Log Files not found. All Right..."
	$emailSubject="Event Log monitor. Error not found on server $CompName $(Get-Date -Format dd.MM.yyyy)"
	$emailBody = @"
$(Get-Date -Format dd.MM.yyyy)
Log monitor $CompName result.
Error not found
"@
	# Отправка письма
	Send-MailMessage -To $emailTo -From $emailFrom -Subject $emailSubject -Body $emailBody -SmtpServer $emailSmtpServer -Encoding $encoding
}
Else {
	If (Test-Path "$PathLogs\report.txt"){
		$Attachment += "$PathLogs\report.txt"
		$emailBody += @"
.
-----------------------------------
Report
-----------------------------------
$(Get-Content $PathLogs\report.txt | out-string)
"@
	}
	# Отправка письма
	Send-MailMessage -To $emailTo -From $emailFrom -Subject $emailSubject -Body $emailBody -SmtpServer $emailSmtpServer -attachments $Attachment -Encoding $encoding
}
Write-Host '-----------------------------------'
Write-Host "Clear $PathLogs folder"
Get-ChildItem $PathLogs -Recurse -Include $include | Remove-Item
Write-Host '-----------------------------------'
Write-Host 'Done'
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
Sleep 2
################################## End ####################################
