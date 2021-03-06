#########################################
# V1.2
# 2014-12-22
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
Import-Module servermanager
$CompName=(Get-WMIObject -Class Win32_OperatingSystem).CSName
$PathLocation = $MyInvocation.MyCommand.Definition | split-path -parent
$Scriptname = $MyInvocation.MyCommand.Name
$PathScripts4backup = @()
$BKDate = Get-Date -Format yyyyMMdd
#----------------------- Parsing XML Config --------------------------
$ConfigFile = New-Object System.Xml.XmlDocument
$ConfigFile.Load("$PathLocation/config.xml")
$PathScripts = $ConfigFile.Root.PathScript
$URL = $ConfigFile.Root.WebURL
$URL += "/config.xml"
$UpdateURL = $ConfigFile.Root.WebURL
# Получаем наименование открытого ключа из config.xml
$PubKey = $ConfigFile.Root.PubKey
# Получаем список директорий со скиптами которые будем бэкапить из config.xml
$PathScripts4backup += $ConfigFile.Root.ListPathScripts | 
						Select-Object -ExpandProperty ListPath | 
						foreach {$_.title}
# Определение переменных настроек почты из config.xml
$emailSmtpServer = $ConfigFile.root.MailConfig.SMTPServer
$emailFrom = $ConfigFile.root.MailConfig.FromEmail
$emailTo = $ConfigFile.root.MailConfig.ToEmail
$encoding = [System.Text.Encoding]::UTF8
# Формирование письма
## Формирование заголовка письма
$emailSubject = "Backup of scripts $CompName $(Get-Date -Format dd.MM.yyyy)"
## Формирование Тела письма
$emailBody = @"
$(Get-Date -Format dd.MM.yyyy)
Encrypted Backup of scripts from $CompName. See attachment file
"@

$SetupConfig = New-Object System.Xml.XmlDocument
$SetupConfig.Load("$URL")
$StatusUpdater = [int]($SetupConfig.Root.StatusUpdater)
#---------------------------------------------------------------------
$BackupName = $env:windir + '\temp\' + $CompName + '_Scripts_' + $BKDate + '.7z'
Set-Alias gpgexe "$PathScripts\gpg\pub\gpg.exe"
Set-Alias sz "$PathScripts\7zip\7z.exe"
$exclude = @('gpg','7zip','7z')
############################# End Settings ################################

########################## Update Procedure ###############################
#--------------------------- Check Update ---------------------------------
If ($StatusUpdater -eq 1) {
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
Write-Host '-------------------------------------------' -ForegroundColor Green
Write-Host 'Testing for IIS avaliable...' -ForegroundColor Green
Write-Host '-------------------------------------------' -ForegroundColor Green
$IISFutureStatus = $False
try{
	$tryError = $null
	$IISFutureStatus = $(Get-WindowsFeature | ? { $_.Name -match "WebServer"} | % { $_.Installed })
}
catch [System.Exception]{
	$tryError = $_.Exception
	Write-Host 'IIS not avaliable' -ForegroundColor Cyan	
}

IF (($IISFutureStatus) -and ($tryError -eq $null)) {
	Write-Host 'IIS avaliable' -ForegroundColor Cyan	
	Write-Host '-------------------------------------------' -ForegroundColor Green
	Write-Host 'Start backup IIS config...' -ForegroundColor Green
	Write-Host '-------------------------------------------' -ForegroundColor Green
	Start-Process powershell.exe "-ExecutionPolicy RemoteSigned $PathLocation\Backup_IISConfig.ps1" -Wait
	Write-Host 'Done' -ForegroundColor Cyan
}

Write-Host '-------------------------------------------' -ForegroundColor Green
Write-Host 'Start backup Firewall config...' -ForegroundColor Green
Write-Host '-------------------------------------------' -ForegroundColor Green
Start-Process powershell.exe "-ExecutionPolicy RemoteSigned $PathLocation\fwbackup.ps1" -Wait
Write-Host 'Done' -ForegroundColor Cyan
Write-Host '-------------------------------------------' -ForegroundColor Green
Write-Host 'Start backup of scripts...' -ForegroundColor Green
Write-Host '-------------------------------------------' -ForegroundColor Green

$ArhPath = @()
Foreach ($arg in $PathScripts4backup){
	$regex = $arg -replace "[:]", "" -replace "[\\]", "_"
	IF ($arg[0] -ine 'C'){
		$TempPath = $arg[0] + ':\tmp\' + $regex
	}
	Else {
		$TempPath = $env:windir + '\temp\' + $regex
	}
	# Создание временной директории
	If (!(test-path "$TempPath")){
		Write-Host "Create temp folder for Scripts from $arg..." -ForegroundColor Cyan
		Write-Host '-------------------------------------------' -ForegroundColor Green
		New-Item -ItemType directory -Path "$TempPath"
		Write-Host
		Write-Host '-------------------------------------------' -ForegroundColor Green
	}
	$exclude += $regex
	# Копирование скриптов во временную директорию
	Write-Host "Copying Scripts from $arg to temp folder..." -ForegroundColor Cyan
	Copy-Item -Path "$arg\*" -Destination $TempPath -Recurse -Exclude $exclude -Force
	Write-Host '-------------------------------------------' -ForegroundColor Green
	# Архивирование скриптов
	Write-Host 'Ziping Scripts...' -ForegroundColor Green
	Write-Host '-------------------------------------------' -ForegroundColor Green
	sz a -t7z -m1=LZMA2 -mmt=8 -mx3 -r $BackupName $TempPath
	Write-Host
	Write-Host '-------------------------------------------' -ForegroundColor Green
	# Удаление временных копий скриптов
	Write-Host 'Removing Scripts from temp folder' -ForegroundColor Green
	Remove-Item -Recurse $TempPath
	Write-Host '-------------------------------------------' -ForegroundColor Green
} 
# Шимфрование 7z архива открытым ключем
Write-Host 'Encrypting zip file...' -ForegroundColor Green
Write-Host '-------------------------------------------' -ForegroundColor Green
gpgexe --trust-model always -e -r $PubKey $BackupName
# Удаление 7z архива
Write-Host 'Removing zip file...' -ForegroundColor Green
Remove-Item -Recurse $BackupName
Write-Host '-------------------------------------------' -ForegroundColor Green
# Отправка письма
Write-Host "Sending encrypted file to email..." -ForegroundColor Green
Send-MailMessage -To $emailTo -From $emailFrom -Subject $emailSubject -Body $emailBody -SmtpServer $emailSmtpServer -attachments "$BackupName.gpg" -Encoding $encoding
Write-Host '-------------------------------------------' -ForegroundColor Green
# Удаление gpg архива
Write-Host 'Removing gpg file...' -ForegroundColor Green
Remove-Item "$BackupName.gpg"
Write-Host '-------------------------------------------' -ForegroundColor Green
Write-Host 'Done.' -ForegroundColor Green
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
Sleep 2
################################## End ####################################
