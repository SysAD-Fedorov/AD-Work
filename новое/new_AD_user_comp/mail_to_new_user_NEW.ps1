Start-Transcript -Path C:\Scripts\new_AD_user_comp\send_mail_log.txt -Append -Force
$DIR = '\\192.168.130.9\hr\Mail'
#$TmpFile = 'C:\Scripts\new_AD_user_comp\query_ID4720_mail.txt'
$TmpFile = 'C:\Scripts\new_AD_user_comp\query_ID4720.txt'

#del $TmpFile
#wevtutil qe ForwardedEvents /q:"*[System[(EventID=4720)]]" /uni:true /f:text /rd:true /c:1 > $TmpFile

$Logins = cat $TmpFile | Select-String -Pattern 'Имя учетной записи'
$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$AdminLogin = $Logins[0].Line.split('	',$SplitOptions)
$tmp,$UserLogin = $Logins[1].Line.split('	',$SplitOptions)

$Logins = cat $TmpFile | Select-String -Pattern 'Отображаемое имя'
$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$DisplayName = $Logins.Line.split('	',$SplitOptions)

#Получаем атрибуты пользователя, берем из них его OU.

$User = Get-ADUser $UserLogin -properties *
$User.DistinguishedName
$user.mail
#$DN = $User.DistinguishedName|foreach{($_ -split ',')[-5] -join ','  }
$DN = $User.DistinguishedName|foreach{$_ -replace 'CN=.*,OU=Users,' -replace ',OU=CG FIX,DC=hq,DC=fix,DC=ru'}
#Составляем словарь

$DNFolder = @{`
#'OU=131' = $Dir + '\131' ;`
#'OU=Affiliate Programs' = $Dir + '\EPN';`
'OU=EPN' = $Dir + '\EPN';`
'OU=SAD'=$Dir + '\FIX';`
'OU=VASP'=$Dir + '\FIX';`
'OU=InformPartner'=$Dir + '\FIX';`
'OU=Accounting' = $Dir + '\FIX' ;`
'OU=Advertising Agency' = $Dir + '\FIX' ;`
'OU=City Hall' = $Dir + '\FIX' ;`
'OU=CSN West' = $Dir + '\FIX' ;`
#'OU=Epayments' = $Dir + '\Epayments' ;`
'OU=EWD' = $Dir + '\FIX' ;`
'OU=Financial Department' = $Dir + '\FIX' ;`
'OU=HR' = $Dir + '\FIX' ;`
'OU=ICM' = $Dir + '\FIX' ;`
'OU=Lawyer' = $Dir + '\FIX' ;`
'OU=Leadership' = $Dir + '\FIX' ;`
'OU=Mobile Commerce' = $Dir + '\FIX' ;`
'OU=NeuralNet' = $Dir + '\FIX' ;`
'OU=OpenCity' = $Dir + '\FIX' ;`
'OU=PR' = $Dir + '\FIX' ;`
'OU=Product Partnership' = $Dir + '\FIX' ;`
'OU=Secretariat' = $Dir + '\FIX' ;`
'OU=SEO' = $Dir + '\FIX' ;`
'OU=SocialCentrum' = $Dir + '\FIX' ;`
'OU=Special Project' = $Dir + '\FIX' ;
}



#Указываем параметры письма
$Rcpt = $UserLogin + "@fix.ru"
#$Rcpt = 'afedorov' + "@fix.ru"
$Sndr = 'welcome@fix.ru'
$smtpServer = "mail.fix.ru"


#Проверяем наличие почты. При наличии готовим и отправляем письмо
if ($User.Mail -ne $null){
write-host "Пользователь имеет почту" $User.Mail
	if ($DNFolder.Keys -match $DN){
	Write-Host "OU пользователя соответствует словарю"
		function sendmail{
	#Creating a Mail object
			$body = Get-Content ($DNFolder.$DN + '\message.html') -Encoding UTF8
			$msg = new-object Net.Mail.MailMessage
	#Creating SMTP server object
			$smtp = new-object Net.Mail.SmtpClient($smtpServer)
			$AttachmentFolder = $DNFolder.$DN + "\Attachments"
			$files = Get-ChildItem $AttachmentFolder
			Foreach($file in $files)
						{
						Write-Host “Attaching File :- ” $file
						$att = New-Object System.Net.Mail.Attachment –ArgumentList $file.FullName
						$msg.Attachments.Add($att)
						}

	#Email structure
			$msg.From = "$Sndr"
			$msg.ReplyTo = "$Sndr"
			$msg.To.Add("$Rcpt")
			$msg.IsBodyHTML = $true
			$msg.subject = "Hello, $DisplayName!"
			$msg.IsBodyHTML = $true
			$msg.body = $body
			
		   
	#Sending email
		$smtp.Send($msg)
		$att.Dispose()	
		
		}
}
	else {write-host "OU пользователя не соответствует словарю"}
#Calling function
sendmail
}
else {write-host "У пользоваетля нет почты"}
Stop-Transcript