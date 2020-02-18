$EmailFrom = “1C@fix.ru”
$EmailTo = “officelog@fix.ru”
$Subject = “1C server problem”
$Body = “backup 1C not created BP base”
$SmtpServer = “www.fix.ru”
$smtp = New-Object net.mail.smtpclient($SmtpServer)
$smtp.Send($EmailFrom, $EmailTo, $Subject, $Body)