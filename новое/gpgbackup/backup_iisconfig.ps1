#########################################
# V1.1
# 2015-02-03
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

# Подключение модуля администрирования IIS
Import-Module WebAdministration

# Определение переменных
$Date=$(Get-Date -Format yyyy-MM-dd)
$CompName=(Get-WMIObject -Class Win32_OperatingSystem).CSName
$BKName="IIS_$(Get-Date -Format yyyyMMdd)"
$BKDir="$env:windir\system32\inetsrv\backup"

If (!($args[0] -eq $null)){
	$PathScripts = $args[0]
}
Else{
	$PathScripts = "C:\Scripts\"
}
$PathLocation = $MyInvocation.MyCommand.Definition | split-path -parent

$ADir="$PathScripts\iis\backup"
$Attachment="$ADir\$BKName.7z"

# Проверка наличия архиватора
if (-not (test-path "$PathScripts\7zip\7z.exe")) 
	{throw "$PathScripts\7zip\7z.exe needed"}
Set-alias sz "$PathScripts\7zip\7z.exe"

# Создание резервной копии настроек IIS
Backup-WebConfiguration -Name $BKName

# Архивирование резервной копии настроек IIS
sz a -t7z -m1=LZMA2 -mmt=8 -mx3 -r $Attachment $BKDir\$BKName

# Удаление резервной копии настроек IIS
Remove-WebConfigurationBackup -Name $BKName

# Removing old backups
Write-Host 'Removing old backups...' -ForegroundColor Green
Get-Item $ADir\* | ? {$_.LastWriteTime.toString("ddMMyy") -ine $(Get-date).ToString("ddMMyy")} | Remove-Item

