#########################################
# 1c Backup script
# V1.0
# 2016-03-10
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
$DumpPath = $PathLocation + '\tmp'
$BKDate = Get-Date -Format yyyyMMdd
$UnderDate = (get-date).AddDays(-14)
$UnderDateNetwork = (get-date).AddDays(-30)
IF($(Get-Date -Format dd) -eq '01') {
	$Monthly = $true
} 
else {
	$Monthly = $false
}
$include=@('*_logs.txt', 'report.txt', '*.7z', '*.log')
#---------------- XML config load --------------------
$ConfigFile = New-Object System.Xml.XmlDocument
$ConfigFile.Load("$PathLocation/config.xml")
$PathScripts = $ConfigFile.Root.PathScript
$URL = $ConfigFile.Root.WebURL
$URL += "/config.xml"
$UpdateURL = $ConfigFile.Root.WebURL
#-----------------------------------------------------
$TypeBackup = $ConfigFile.Root.TypeBackup
$PathBackup = $ConfigFile.Root.PathBackup
$PathNetwork = $ConfigFile.Root.PathNetwork
$ServerNetwork = $ConfigFile.Root.ServerNetwork

$LOGIN1C = $ConfigFile.Root.LOGIN1C
$PASSWD1C = $ConfigFile.Root.PASSWD1C

# Получаем наименование открытого ключа из config.xml
$PubKey = $ConfigFile.Root.PubKey

$LOG = $PathLocation + '\1cbackup_' + $BKDate + '.log'

# Определение переменных настроек почты из config.xml
$encoding = [System.Text.Encoding]::UTF8

#SMTP param.:
$smtpServer = $ConfigFile.root.MailConfig.SMTPServer
$FromAddr = $ConfigFile.root.MailConfig.FromEmail
$ToAddr = $ConfigFile.root.MailConfig.ToEmail

$smtpUser = $ConfigFile.root.MailConfig.smtpUser
$smtpPassw = $ConfigFile.root.MailConfig.smtpPassw

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient($smtpServer,587)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassw);

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage

# Формирование письма
$msg.IsBodyHtml = $true
$msg.From = $FromAddr
$msg.Subject = "Backup of DB $CompName $(Get-Date -Format dd.MM.yyyy)"
$msg.BodyEncoding = [System.Text.Encoding]::UTF8
$msg.To.Clear()
$ConfigFile.root.MailConfig.EmailList | 
	Select-Object -ExpandProperty ToEmail |
		foreach {
			$msg.To.Add($_.ADDR)
		}

## Формирование Тела письма
$emailBody = @"
$(Get-Date -Format dd.MM.yyyy) <br>
Backup DB from $CompName. <br>
--------------------------------------------- <br>

"@

#---------------------------------------------------------------------
Set-Alias gpgexe "$PathScripts\gpg\pub\gpg.exe"
Set-Alias sz "$PathScripts\7zip\7z.exe"
Set-Alias c1v8 $ConfigFile.Root.Path1c
$exclude = @('gpg','7zip','7z')
############################# End Settings ################################

<########################## Update Procedure ###############################
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
########################### End Update Procedure ##########################>

################################# Begin ###################################
$ConfigFile.Root.DBList | 
	Select-Object -ExpandProperty DB | 
		foreach {
			$Status = $True
			Write-Host "Start backup" $_.name "..." -ForegroundColor Green
			Write-Output $("Start backup " + $_.name + "...") >> $LOG
			Write-Output '--------------------------------------------' >> $LOG 
			Write-Host '-------------------------------------------' -ForegroundColor Green
			$PathBackupDaily = $PathBackup + '\Daily\' + $_.name
			$PathNetworkBackupDaily = $PathNetwork + 'Daily\' + $_.name + '\'
			$BackupTo = $PathBackupDaily + '\' + $_.name + '_' + $BKDate + '.7z'
			$DBPATH = $_.dbpath
			If (!(test-path "$PathNetwork")){
				New-PSDrive -Name $PathNetwork[0] -PSProvider FileSystem -Root $ServerNetwork -Persist
			}
			If (!(test-path "$PathBackupDaily")){
				Write-Host "Create backup folder for DB" $_.name "..." -ForegroundColor Cyan
				Write-Host '-------------------------------------------' -ForegroundColor Green
				New-Item -ItemType directory -Path "$PathBackupDaily"
				Write-Host
				Write-Host '-------------------------------------------' -ForegroundColor Green
			}
			If (!(test-path "$PathNetworkBackupDaily")){
				Write-Host "Create backup folder for DB" $_.name "..." -ForegroundColor Cyan
				Write-Host '-------------------------------------------' -ForegroundColor Green
				New-Item -ItemType directory -Path "$PathNetworkBackupDaily"
				Write-Host
				Write-Host '-------------------------------------------' -ForegroundColor Green
			}

			Switch ($TypeBackup)
			{
				'1' {
					If (!(test-path "$DumpPath")){
						Write-Host 'Create dump folder ...' -ForegroundColor Cyan
						Write-Host '-------------------------------------------' -ForegroundColor Green
						New-Item -ItemType directory -Path "$DumpPath"
						Write-Host
						Write-Host '-------------------------------------------' -ForegroundColor Green
					}
					Write-Host 'Stoping 1C proccess...' -ForegroundColor Green
					Write-Host '-------------------------------------------' -ForegroundColor Green
					try{
					# 	Logof all users from DB
						c1v8 ENTERPRISE /F $DBPATH /N $LOGIN1C /P $PASSWD1C /WA- /AU- /DisableStartupMessages /C ЗавершитьРаботуПользователей
						sleep 30
						Stop-Process -processname "1cv8" -force -ErrorAction Stop
						Write-Host 'Process stoped' -ForegroundColor Cyan
					}
					catch {
						Write-Host 'Process not running' -ForegroundColor Cyan
					}
					Write-Host '-------------------------------------------' -ForegroundColor Green			
				#	Here 1c Dump created
					$DumpFile =	$DumpPath + '\' + $_.name + '_' + $BKDate + '.dt'
					$LogFile = $DumpPath + '\' + '1c8_' + $_.name + '_Log.txt'
					try{
						c1v8 DESIGNER /F $DBPATH /N $LOGIN1C /P $PASSWD1C /DisableStartupMessages /DumpIB $DumpFile /Out $LogFile -NoTruncate
						$backupFrom = $DumpPath + '\*'
						Write-Host 'Dump created' -ForegroundColor Cyan
					}
					catch {
						$Status = $False
						$emailBody += $_.name + " Error. Dump NOT created. " + "`r`n" + " <br>"
						Write-Host 'Error. Dump NOT created' -ForegroundColor Red
					}
					Write-Host '-------------------------------------------' -ForegroundColor Green
				}
				'2' {
					Write-Host 'Stoping 1C proccess...' -ForegroundColor Green
					Write-Host '-------------------------------------------' -ForegroundColor Green
					try{
						Stop-Process -processname "1cv8" -force -ErrorAction Stop
						Write-Host 'Process stoped' -ForegroundColor Cyan
					}
					catch {
						Write-Host 'Process not running' -ForegroundColor Cyan
					}
					Write-Host '-------------------------------------------' -ForegroundColor Green			
					$backupFrom = $DBPATH + '\*'
				}
			}
			
			If ($Status) {
			    Write-Host 'Archiving DB directory...' -ForegroundColor Green
				Write-Host '-------------------------------------------' -ForegroundColor Green
				sz a -t7z -m1=LZMA2 -mmt=8 -mx3 -r $BackupTo $backupFrom | findstr /P /I /V "Compressing  " >> $LOG
				Write-Output '----------------------' >> $LOG 
			}

			If (test-path "$BackupTo"){
			    Write-Host 'Archive created' -ForegroundColor Cyan
				Write-Host '-------------------------------------------' -ForegroundColor Green
				# Шимфрование 7z архива открытым ключем
				Write-Host 'Encrypting archive file...' -ForegroundColor Green
				Write-Host '-------------------------------------------' -ForegroundColor Green
				gpgexe --trust-model always -e -r $PubKey $BackupTo
			
				if (test-path "$BackupTo.gpg"){
					Write-Host 'Archive encrypted' -ForegroundColor Cyan
					Write-Host '-------------------------------------------' -ForegroundColor Green
					$BackupGPG="$BackupTo.gpg"
					$FileSizeLocal="{0:N2}" -f ((Get-Item $BackupGPG).length /1MB)
					$emailBody += $_.name + " daily backup created. Size: "+ $FileSizeLocal + " MB" + "`r`n" + " <br>"
					Write-Host "Copy backup DB" $_.name "to remote storage..." -ForegroundColor Green
					Write-Host '-------------------------------------------' -ForegroundColor Green
					Write-Output "Copy backup DB to remote storage..."  >> $LOG 
					
					If($PSVersionTable.PSVersion.Major -lt 3) {
						Copy-Item -Path $BackupGPG -Destination $PathNetworkBackupDaily >> $LOG 2>&1
					} 
					Else {
						Copy-Item -Path $BackupGPG -Destination $PathNetworkBackupDaily *>> $LOG
					}
					
					$backupNetworkDaily = $PathNetworkBackupDaily + '\' + $_.name + '_' + $BKDate + '.7z.gpg'
					
					If (test-path "$backupNetworkDaily"){
					    Write-Host 'Copying complete. File exist' -ForegroundColor Cyan
					    Write-Host '-------------------------------------------' -ForegroundColor Green
					    $FileSizeNetworkDaily  = "{0:N2}" -f ((Get-Item $backupNetworkDaily).length /1MB)
						$emailBody += $_.name + " in the remote storage exist. Size: " + $FileSizeNetworkDaily  + " MB" + "`r`n" + " <br>"
						Write-Output 'Done'  >> $LOG 
						Write-Output '--------------------------------------------' >> $LOG 
					}
					Else {
					    Write-Host 'File not copied. Check it!' -ForegroundColor Red
					    Write-Host '-------------------------------------------' -ForegroundColor Green
						$emailBody += $_.name + " in the remote storage NOT exist. Check it!" + "`r`n" + " <br>"
						Write-Output 'Error copy'  >> $LOG 
					}
					
					If ($Monthly) {
						$PathNetworkBackupMonthly = $PathNetwork + '\Monthly\' + $_.name + '\'
						If (!(test-path "$PathNetworkBackupMonthly")){
							Write-Host "Create backup folder for DB" $_.name "..." -ForegroundColor Cyan
							Write-Host '-------------------------------------------' -ForegroundColor Green
							New-Item -ItemType directory -Path "$PathNetworkBackupMonthly"
							Write-Host
							Write-Host '-------------------------------------------' -ForegroundColor Green
			            }
						If($PSVersionTable.PSVersion.Major -lt 3) {
							Copy-Item -Path $BackupGPG -Destination $PathNetworkBackupMonthly >> $LOG 2>&1
						} 
						Else {
							Copy-Item -Path $BackupGPG -Destination $PathNetworkBackupMonthly  *>> $LOG
						}
						$BackupNetworkMonthly = $PathNetworkBackupMonthly + $_.name + "_" + $BKDate + ".7z.gpg"
						if (test-path $BackupNetworkMonthly) {
						   $FileSizeNetworkMonthly = "{0:N2}" -f ((Get-Item $BackupNetworkMonthly).length /1MB)
						   $emailBody += $_.name + " monthly backup to the remote storage copied. Size: " + $FileSizeNetworkMonthly + " MB" + "`r`n" + " <br>"
						}
						Else {
						   $emailBody += $_.name + " monthly backup to the remote storage NOT copied. Check it!" + "`r`n" + " <br>"
						}
					}
					
					# Удаление 7z архива
					Write-Host 'Removing zip file...' -ForegroundColor Green
					Remove-Item -Recurse $BackupTo
				}
                Else {
				    Write-Host 'Archive NOT encrypted. Check it!' -ForegroundColor Red
					Write-Host '-------------------------------------------' -ForegroundColor Green
					$emailBody += $_.name + " backup created ERROR. Archive Not Encrypted. Check it!" + "`r`n" + " <br>"
				}
			}
			Else {
			    Write-Host 'Archive NOT created. Check it!' -ForegroundColor Red
				Write-Host '-------------------------------------------' -ForegroundColor Green
				$emailBody += $_.name + " backup created ERROR. Archive Not created. Check it!" + "`r`n" + " <br>"
			}
			$emailBody += '------------------------------------' + "`r`n" + " <br>"
			Write-Host '-------------------------------------------' -ForegroundColor Green
			Write-Host 'Clearing old bvackup under then 2 weeks...' -ForegroundColor Green
			Write-Host '-------------------------------------------' -ForegroundColor Green
			Get-ChildItem $PathBackupDaily -Include "*.7z","*.gpg" -Recurse |  
				Where {$_.LastWriteTime -le "$UnderDate"} | 
					Remove-Item
			Get-ChildItem $PathNetworkBackupDaily -Include "*.7z","*.gpg" -Recurse |  
				Where {$_.LastWriteTime -le "$UnderDateNetwork"} | 
					Remove-Item
		}

# Отправка письма
Write-Host "Sending report to email..." -ForegroundColor Green
$ATT = new-object Net.Mail.Attachment($LOG)
$msg.Body = $emailBody
$msg.Attachments.Add($ATT)
$smtp.Send($msg)
$ATT.Dispose()
Write-Host '-------------------------------------------' -ForegroundColor Green
Write-Host 'Done.' -ForegroundColor Green
Get-ChildItem $PathLocation -Recurse -Include $include | Remove-Item
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
Sleep 2
################################## End ####################################
