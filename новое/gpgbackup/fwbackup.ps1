#########################################
# V1.0
# 2014-12-23
# Author Artyom Nijazov aka Th0mson
#########################################
# ---------------------------------------------------------------------
# Setting console configuration
# ---------------------------------------------------------------------
$console = $host.UI.RawUI
$console.BackgroundColor = "DarkMagenta"
$console.ForegroundColor = "White"
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
$BackpDate = Get-Date -Format dd.MM.yyyy

#----------------------- Parsing XML Config --------------------------
$ConfigFile = New-Object System.Xml.XmlDocument
$ConfigFile.Load("$PathLocation/config.xml")
$PathScripts = $ConfigFile.Root.PathScript
$BackupPath = $PathScripts + '\Firewall'
If (!(test-path "$BackupPath")){
		Write-Host '-----------------------------------'
		Write-Host "Create $BackupPath Folder..." -ForegroundColor Green
		Write-Host '-----------------------------------'
		New-Item -ItemType directory -Path "$BackupPath"
		Write-Host
}
$BackupFile = $BackupPath + '\FWBackup_' + $CompName + '_' + $(Get-Date -Format yyyyMMdd) + '.ps1'
$URL = $ConfigFile.Root.WebURL
$URL += "/config.xml"
$UpdateURL = $ConfigFile.Root.WebURL
# Определение переменных настроек почты из config.xml
$emailSmtpServer = $ConfigFile.root.MailConfig.SMTPServer
$emailFrom = $ConfigFile.root.MailConfig.FromEmail
$emailTo = $ConfigFile.root.MailConfig.ToEmail
$encoding = [System.Text.Encoding]::UTF8
# Формирование письма
## Формирование заголовка письма
$emailSubject = "Backup firewall config from $CompName $BackpDate"
## Формирование Тела письма
$emailBody = @"
$BackpDate
Script for recovery Backup firewall config from $CompName. See attachment file
"@

$SetupConfig = New-Object System.Xml.XmlDocument
$SetupConfig.Load("$URL")
$StatusUpdater = [int]($SetupConfig.Root.StatusUpdater)
#---------------------------------------------------------------------
$Count = 0
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

############################# Generate script #############################
$Fncns =  '########################################################' + "`r`n"
$Fncns += "# Script generated $BackpDate" + "`r`n"
$Fncns += "# Script recovery firewall rules for $CompName" + "`r`n"
$Fncns += '########################################################
# ------------------------------------------------------
# Setting console configuration
# ------------------------------------------------------
$console = $host.UI.RawUI
$console.BackgroundColor = "DarkMagenta"
$console.ForegroundColor = "White"
cls
function existsFirewallRule {
    param( [string] $name )
    $fw = New-Object -ComObject hnetcfg.fwpolicy2 
    if ($fw.Rules | Where { $_.Name -eq "$name" }) {
        return [bool]$true
    } else {
        return [bool]$false
    }
}

function clearFirewallRules {
    $fw = New-Object -ComObject hnetcfg.fwpolicy2 
	$fw.Rules | 
		ForEach-Object { 
			$fw.Rules.Remove($_.Name)
		}
}

function addFirewallRule {
    param(
        [string] $name,
		[boolean] $status,
		[int] $InOut,
		[int] $protocol,
		[string] $applname,
        [string] $localport,
		[string] $remoteport,
		[string] $RemoteIP,
		[int] $Profiles,
		[int] $Action,
		[boolean] $EDGEstatus
    )
    $fw = New-Object -ComObject hnetcfg.fwpolicy2 
	Write-Host "-------------------------------------------"
    if (existsFirewallRule $name) {
        Write-Host "Updating $name rule..." -ForegroundColor Green
		Write-Host "-------------------------------------------"
		Invoke-Command -ScriptBlock {netsh advfirewall firewall set rule name="$Name" new action=allow enable=yes remoteip="$RemoteIP"}
    } else {
		Write-Host "Create $name rule..." -ForegroundColor Green
		Write-Host "-------------------------------------------"
        $rule = New-Object -ComObject HNetCfg.FWRule
        $rule.Name = "$name"
		$rule.Enabled = $status
		$rule.Direction = $InOut
		$rule.Protocol = $protocol # 6=NET_FW_IP_PROTOCOL_TCP and 17=NET_FW_IP_PROTOCOL_UDP
		IF (("$applname" -ne "$null") -and ("$applname" -ne "*")){
			$rule.ApplicationName = $applname
		}
        IF (("$localport" -ne "$null") -and ("$localport" -ne "*")){
			$rule.LocalPorts = "$localport"
		}
		IF (("$remoteport" -ne "$null") -and ("$remoteport" -ne "*")){
			$rule.RemotePorts = "$remoteport"
		}
		IF (("$RemoteIP" -ne "$null") -and ("$RemoteIP" -ne "*")){
			$rule.RemoteAddresses = "$RemoteIP"
		}
        $rule.Profiles = $Profiles
        $rule.Action = $Action # NET_FW_ACTION_ALLOW
        $rule.EdgeTraversal = $EDGEstatus
        $fw.Rules.Add($rule)
        Write-Host "A rule named $name has been added to Windows Firewall" -ForegroundColor Cyan
    }
}
# Если нужно удаление стандартных правил, то раскоменьте след. 3 строки:
# Write-Host "-------------------------------------------"
# Write-Host "Removing standart rules..." -ForegroundColor Green
# clearFirewallRules
'
###########################################################################

################################# Begin ###################################
Write-Host '-------------------------------------------'
Write-Host 'Generating recovery script...' -ForegroundColor Green
Write-Host '-------------------------------------------'
$Fncns | Out-File $BackupFile
Write-Host 'Backup Firewall rules...' -ForegroundColor Green
Write-Host '-------------------------------------------'
$fw = New-Object -ComObject hnetcfg.fwpolicy2 
$fw.Rules | 
# Если нужна выборка только активных то раскоменьте эту строку:
 Where-Object {($_.Enabled -EQ $True)} | 
	ForEach-Object {
		IF ($_.ApplicationName -eq $null) {
			$ApplName = '$Null'
		}
		Else {
			$ApplName = $_.ApplicationName
		}
		IF ($_.LocalPorts -eq $null) {
			$LocalPorts = '$Null'
		}
		Else {
			$LocalPorts = $_.LocalPorts
		}
		IF ($_.RemotePorts -eq $null) {
			$RemotePorts = '$Null'
		}
		Else {
			$RemotePorts = $_.RemotePorts
		}
		$rule  = 'addFirewallRule' + ' '
		$rule += '-name:"' + $_.Name + '" '
		$rule += '-status:' + [int]($_.Enabled) + ' '
		$rule += '-InOut:' + $_.Direction + ' '
		$rule += '-protocol:' + $_.Protocol + ' '
		$rule += '-applname:"' + "$ApplName"  + '" '
		$rule += '-localport:"' + "$LocalPorts" + '" '
		$rule += '-remoteport:"' + "$RemotePorts" + '" '
		$rule += '-RemoteIP:"' + $_.RemoteAddresses + '" '
		$rule += '-Profiles:' + $_.Profiles + ' '
		$rule += '-Action:' + $_.Action + ' '
		$rule += '-EDGEstatus:' + [int]($_.EdgeTraversal)
		$rule >> $BackupFile
		$Count++
	}
Write-Host 'Backuped' $Count 'IN|OUT Rules' -ForegroundColor Green
Write-Host '-------------------------------------------'
# Removing old backups
Write-Host 'Removing old backups...' -ForegroundColor Green
Get-Item $BackupPath\* | ? {$_.LastWriteTime.toString("ddMMyy") -ine $(Get-date).ToString("ddMMyy")} | Remove-Item
Write-Host '-------------------------------------------'
Write-Host 'Done.' -ForegroundColor Green
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
Sleep 2
################################## End ####################################