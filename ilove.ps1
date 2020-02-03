$MyToken = "754087227:AAGpqp0DZBZR5-wTzg8_-77BndsBoxxvkJs"
$MyChatID = "-1001477791851"

$file = Get-Content 'C:\Users\afedorov.HQ\Documents\GitHub\AD-Work\love2.txt'
$body = $file[0]

$file[0] = $null

$file | Set-Content 'C:\Users\afedorov.HQ\Documents\GitHub\AD-Work\love2.txt'

$URL4SEND = "https://api.telegram.org/bot$MyToken/sendMessage?chat_id=$MyChatID&text=$Body"

Invoke-WebRequest -Uri $URL4SEND
