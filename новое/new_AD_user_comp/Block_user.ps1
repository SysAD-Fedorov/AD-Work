$Dir = 'C:\Scripts\new_AD_user_comp'
$TmpFile = $Dir + '\query_ID4740.xml'
$Sndr = 'dchetznera@fix.ru'
$Rcpt = 'it@fix.ru'

$MyToken = "1063608544:AAHwbfcFt5dyQd87xmTdQK6IHTij46qTXe8"
$MyChatID = "-1001464241736"

del $TmpFile
wevtutil qe ForwardedEvents /q:"*[System[(EventID=4740)]]" /uni:true /f:xml /rd:true /c:1 > $TmpFile

[xml]$xmlfile = get-content $TmpFile

$TargetUserName =  $xmlfile.Event.EventData.Data[0].'#text'

$SubjectUserName = $xmlfile.Event.EventData.Data[4].'#text'

$TimeCreated  = $xmlfile.Event.System.TimeCreated.SystemTime

$Body = "
$TimeCreated учетная запись пользователя $TargetUserName была заблокирована на $SubjectUserName 
"

$URL4SEND = "https://api.telegram.org/bot$MyToken/sendMessage?chat_id=$MyChatID&text=$Body"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -Uri $URL4SEND
