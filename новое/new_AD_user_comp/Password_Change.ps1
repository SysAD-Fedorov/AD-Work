$Dir = 'C:\Scripts\new_AD_user_comp'
$TmpFile = $Dir + '\query_ID4738.xml'
$Sndr = 'dchetznera@fix.ru'
#$Rcpt = 'lnigmatullin@fix.ru'
$Rcpt = 'it@fix.ru'

$MyToken = "1063608544:AAHwbfcFt5dyQd87xmTdQK6IHTij46qTXe8"
$MyChatID = "-1001464241736"

del $TmpFile
wevtutil qe ForwardedEvents /q:"*[System[(EventID=4738)]]" /uni:true /f:xml /rd:true /c:1 > $TmpFile

[xml]$xmlfile = get-content $TmpFile

$TargetUserName =  $xmlfile.Event.EventData.Data[1].'#text'

$SubjectUserName = $xmlfile.Event.EventData.Data[5].'#text'

$PasswordLastSet = $xmlfile.Event.EventData.Data[17].'#text'

$Resault = $xmlfile.Event.RenderingInfo.Keywords.Keyword

$Computer = $xmlfile.Event.System.Computer



if ($Resault -eq '����� ������')
	{$Resault = '�������'}
else 
	{$Resault = '���������'}

if ($SubjectUserName -eq '��������� ����')
	{$body = "
$PasswordLastSet ������������ $TargetUserName $Resault ������� ������ �� ��������� ������ 
"}

if ($SubjectUserName -eq 'PassCore370')
	{$body = "
$PasswordLastSet ������������ $TargetUserName $Resault ������� ������ ��������� http:\\cup.fix.ru
"}

if (!($SubjectUserName -eq 'PassCore370') -and !($SubjectUserName -eq '��������� ����'))
	{$body = "
$PasswordLastSet ������������� $SubjectUserName $Resault ������� ������ ������������ $TargetUserName �� $Computer
"}

<#function sendMail{

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
     $msg.subject = "������������ $TargetUserName $Resault ������� ������"


     $msg.body = $Body

     #Sending email
     $smtp.Send($msg)
 
}

#Calling function
sendMail
#>
$URL4SEND = "https://api.telegram.org/bot$MyToken/sendMessage?chat_id=$MyChatID&text=$Body"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -Uri $URL4SEND