$Dir = 'C:\Scripts\new_AD_user_comp'
$TmpFile = $Dir + '\query_ID4720.txt'
$Sndr = 'dchetznera@fix.ru'
#$Rcpt = 'lnigmatullin@fix.ru'
$Rcpt = 'it@fix.ru'

del $TmpFile
wevtutil qe Security /q:"*[System[(EventID=4720)]]" /uni:true /f:text /rd:true /c:1 > $TmpFile
$Logins = cat $TmpFile | Select-String -Pattern '��� ������� ������'

$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$AdminLogin = $Logins[0].Line.split('	',$SplitOptions)
$tmp,$UserLogin = $Logins[1].Line.split('	',$SplitOptions)

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
     $msg.subject = "New user - - $UserLogin - - $AdminLogin"
     $msg.body = (Get-Content $TmpFile | out-string)
     $msg.BodyEncoding =  Encoding.GetEncoding(utf8);
     #Sending email
     $smtp.Send($msg)
 
}

#Calling function
sendMail

#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
