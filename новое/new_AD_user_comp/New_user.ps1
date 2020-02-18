$Dir = 'C:\Scripts\new_AD_user_comp'
$TmpFile = $Dir + '\query_ID4720.txt'
$Sndr = 'dchetznera@fix.ru'
#$Rcpt = 'lnigmatullin@fix.ru'
$Rcpt = 'it@fix.ru'

del $TmpFile
wevtutil qe ForwardedEvents /q:"*[System[(EventID=4720)]]" /uni:true /f:text /rd:true /c:1 > $TmpFile

$Logins = cat $TmpFile | Select-String -Pattern 'Имя учетной записи'
$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$AdminLogin = $Logins[0].Line.split('	',$SplitOptions)
$tmp,$UserLogin = $Logins[1].Line.split('	',$SplitOptions)

$Logins = cat $TmpFile | Select-String -Pattern 'Отображаемое имя'
$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$DisplayName = $Logins.Line.split('	',$SplitOptions)

$Logins = cat $TmpFile | Select-String -Pattern 'Computer'
$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$Computer = $Logins.Line.split(' ',$SplitOptions)

$OU = (Get-ADUser $UserLogin).DistinguishedName|foreach{($_ -split ',')[-5..-1] -join ','  }

function sendMail{

     Write-Host "Sending Email"

     #SMTP server name
     $smtpServer = "mail.fix.ru"

     #Creating a Mail object
     $msg = new-object Net.Mail.MailMessage

     #Creating SMTP server object
     $smtp = new-object Net.Mail.SmtpClient($smtpServer)

     #Email structure
     $msg.From = "$Sndr"
     $msg.ReplyTo = "$Sndr"
     $msg.To.Add("$Rcpt")
     $msg.subject = "New user - - $DisplayName"
#     $msg.body = (Get-Content $TmpFile1 | out-string)
#     $msg.BodyEncoding =  Encoding.GetEncoding(utf8);

     $msg.body = @"
Новый пользователь!

Пользователь:	$DisplayName
Логин:		$UserLogin
Подразделение:	$OU

Создатель:	$AdminLogin

DC: $Computer
"@

     #Sending email
     $smtp.Send($msg)
 
}

#Calling function
sendMail

#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
