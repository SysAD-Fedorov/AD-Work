#SMTP param.:
$smtpServer = "mail.fix.ru"
$FromAddr = "expirespasslog@fix.ru"
$ToAdminAddr = "it@fix.ru"

$smtpUser = "expirespasslog"
$smtpPassw = "27t19vqb))"

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient($smtpServer,587)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassw);

$msg.IsBodyHtml = $true
$msg.From = $FromAddr
$msg.To.Clear()
$msg.To.Add($ToAdminAddr)
$msg.Subject = "test"
$msg.BodyEncoding = [System.Text.Encoding]::UTF8
$msg.Body="test"

$smtp.Send($msg)
