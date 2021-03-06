#########################################
# V1.0
# 2016-05-16
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
Import-Module ActiveDirectory

#System globalization
#$ci = New-Object System.Globalization.CultureInfo("ru-RU")

#Set the target OU that will be searched for user accounts
$DC = "hq"
$Domain = "hq.fix.ru"
$OU = "OU=CG FIX,DC=hq,DC=fix,DC=ru"

## Serach in OU
#$ADAccounts = Get-ADUser -LDAPFilter "(objectClass=user)" -SearchBase $OU -properties Name, PasswordExpired, Mail, PasswordNeverExpires, PasswordLastSet, LastLogonTimeStamp, Mail, PostalCode, Enabled | 
#				Where-object {$_.Enabled -eq $true -and $_.PasswordNeverExpires -eq $false -and $_.SamAccountName -ne "FIX$"}

## Global search
$ADAccounts = Get-ADUser -LDAPFilter "(objectClass=user)" -properties Name, PasswordExpired, Mail, PasswordNeverExpires, PasswordLastSet, LastLogonTimeStamp, Mail, PostalCode, Enabled | 
				Where-object {$_.Enabled -eq $true -and $_.PasswordNeverExpires -eq $false -and $_.SamAccountName -ne "FIX$"}

## Params for inactive users
## Filter: Days Inactive
[int]$NotActiveDays = 90
## Filter: Execute users
$ExecuteAccount = ("service", "linux", "nondomain")
## If need locking user set to param 
## $LockUser = $true
$LockUser = $false

$NotificationCounter = 0
$ListOfAccounts = ""

## URL for change User password:
#$URLPassChange = "<a href=""https://cup.fix.ru/rdweb/Pages/ru-RU/password.aspx"">https://cup.fix.ru/rdweb/Pages/ru-RU/password.aspx</a>"
$URLPassChange = "<a href=""https://cup.fix.ru"">https://cup.fix.ru</a>"

#SMTP param.:
$smtpServer = "mail.fix.ru"
$FromAddr = "expirespasslog@fix.ru"
$ToAdminAddr = "it@fix.ru"

$smtpUser = "expirespasslog"
$smtpPassw = "27t19vqb))"

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage
#Creating a Mail object for report
$msgr = new-object Net.Mail.MailMessage

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient($smtpServer,587)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassw);
############################## End Settings ###############################

###################### Function E-mail structure ##########################
Function EmailStructureExpire($ToAddr,$expiryDate,$upn){
	$msg.IsBodyHtml = $true
	$msg.From = $FromAddr
	$msg.To.Clear()
	$msg.To.Add($ToAddr)
	$msg.Subject = "Password expiration notice. Заканчивается срок действия пароля"
	$msg.BodyEncoding = [System.Text.Encoding]::UTF8
	$msg.Body = " Это автоматически сгенерированое сообщение. Не надо на него отвечать <br><br>
Пожалуйста, обратите внимание на то, что срок действия пароля для вашей доменной учетной записи $upn истекает $expiryDate, осталось: $DaysToExpireDD дней/часов.<br><br>
Пожалуйста, смените пароль перейдя по ссылке $URLPassChange
<br><br><br><br>
This is an automatically generated message. <br><br>
Please note that the password for your Domain account $upn will expire on $expiryDate, left: $DaysToExpireDD days/hours.<br><br>
Please change your password $URLPassChange"
}
###########################################################################

###################### Function E-mail structure ##########################
Function EmailStructureInactive($ToAddr,$inactiveDays,$UserName,$upn){
	$msg.IsBodyHtml = $true
	$msg.From = $FromAddr
	$msg.To.Clear()
	$msg.To.Add($ToAddr)
	$msg.Subject = "User Account Locked"
	$msg.Body = "This is an automatically generated message. <br><br>
Dear $UserName<br><br>
Your Domain account $upn has locked. He was inactive $inactiveDays days.<br><br>
Please contact to your system administrator.<br>
HelpDesk: <a href=""mailto:helpdesk@fix.ru"">helpdesk@fix.ru</a>"
}

###########################################################################

################### Function E-mail structure Report ######################
Function EmailStructureReport($ToAddr){
	$msgr.IsBodyHtml = $true
	$msgr.From = $FromAddr
	$msgr.To.Add($ToAddr)
	$msgr.Subject = "Password expiration report in $Domain"
	$msgr.Body = "This is a daily report.<br><br>
Script has successfully completed its work. <br><br>
$NotificationCounter users have recieved notifications: <br><br>
$ListOfAccounts"
}
###########################################################################

################################# Begin ###################################
Foreach ($ADAccount in $ADAccounts)
{
	$accountFGPP = Get-ADUserResultantPasswordPolicy $ADAccount
	if ($accountFGPP -ne $null){
		$maxPasswordAgeTimeSpan = $accountFGPP.MaxPasswordAge
	}
	else {
		$maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
	}
	
	$UserName = $ADAccount.Name
	#Fill in the user variables
	$samAccountName = $ADAccount.samAccountName
	## for test use this param:
	#$userEmailAddress = $ToAdminAddr
	## for live use this param:
	$userEmailAddress = $ADAccount.Mail
	$userPrincipalName = $ADAccount.UserPrincipalName

	if ($ADAccount.PasswordExpired){
		Write-host "The password for account $samAccountName has expired!"
		$ListOfAccounts = $ListOfAccounts + $samAccountName + " has expired! <br>" 
	}
	else {
		$ExpiryDate = $ADAccount.PasswordLastSet + $maxPasswordAgeTimeSpan
		$TodaysDate = Get-Date
		$DaysToExpire = $ExpiryDate - $TodaysDate
		#Calculating DaysToExpireDD to DD format (w/o fractional part and dot)
		$DaysToExpireDD = $DaysToExpire.ToString() -Split ("\S{17}$")
		Write-host "The password for account $samAccountName expires on: $ExpiryDate. Days left: $DaysToExpireDD"
		if (($DaysToExpire.Days -eq 15) -or ($DaysToExpire.Days -eq 7) -or ($DaysToExpire.Days -le 3)){
			$expiryDate = $expiryDate.ToString("d",$ci)
			#Generate e-mail structure and send message
			if ($userEmailAddress){
				EmailStructureExpire $userEmailAddress $expiryDate $samAccountName
				$smtp.Send($msg)
				Write-Host "NOTIFICATION - $samAccountName :: e-mail was sent to $userEmailAddress"
				$NotificationCounter = $NotificationCounter + 1
				$ListOfAccounts = $ListOfAccounts + $samAccountName + " - $DaysToExpireDD days left. Sent to $userEmailAddress <br>"
			}
		}
	}
	$ZipCode = $ADAccount.PostalCode
	If ($ZipCode -eq $null) {
		$ZipCode = ""
	}
	$ZipCode = $ZipCode.ToString()
	if (([DateTime]::FromFileTime($ADAccount.LastLogonTimeStamp) –lt [DateTime]::Today.AddDays(-$NotActiveDays)) -and ($ExecuteAccount -notcontains  $ZipCode)){
		$inactiveDays = ([DateTime]::Today - [DateTime]::FromFileTime($ADAccount.LastLogonTimeStamp)).Days
		Write-Host $samAccountName '|' $([DateTime]::FromFileTime($ADAccount.LastLogonTimeStamp)) '| inactive' $inactiveDays 'days'
		if ($LockUser) {
			 Disable-ADAccount -Identity $samAccountName
		}
		if ($userEmailAddress){
				$inactiveDays = $inactiveDays.ToString()
				EmailStructureInactive $userEmailAddress $inactiveDays $UserName $samAccountName
				$smtp.Send($msg)
				Write-Host "NOTIFICATION - $samAccountName :: e-mail was sent to $userEmailAddress"
				$NotificationCounter = $NotificationCounter + 1
				$ListOfAccounts = $ListOfAccounts + $samAccountName + " - inactive $inactiveDays days. Sent to $userEmailAddress <br>"
		}
	}
}

Write-Host "SENDING REPORT TO IT DEPARTMENT"
EmailStructureReport $ToAdminAddr
$smtp.Send($msgr)

Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
Sleep 2
################################## End ####################################