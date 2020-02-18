$DIR = 'C:\Scripts\new_AD_user_comp'
$TmpFile = $Dir + '\query_ID4720.txt'

del $TmpFile
wevtutil qe Security /q:"*[System[(EventID=4720)]]" /uni:true /f:text /rd:true /c:1 > $TmpFile

$Logins = cat $TmpFile | Select-String -Pattern 'Имя учетной записи'
$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$AdminLogin = $Logins[0].Line.split('	',$SplitOptions)
$tmp,$UserLogin = $Logins[1].Line.split('	',$SplitOptions)

$Logins = cat $TmpFile | Select-String -Pattern 'Отображаемое имя'
$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$tmp,$DisplayName = $Logins.Line.split('	',$SplitOptions)

#Получаем атрибуты пользователя, берем из них его OU.
$User = Get-ADUser $UserLogin -properties *
$DN = $User.DistinguishedName|foreach{($_ -split ',')[1..6] -join ','}
$DNFolder = @{'OU=131,OU=CG FIX,DC=hq,DC=fix,DC=ru' = $Dir + '\131' ; 'OU=Affiliate Programs,OU=CG FIX,DC=hq,DC=fix,DC=ru' = $Dir + '\Affiliate Programs';'OU=Users,OU=SAD,OU=CG FIX,DC=hq,DC=fix,DC=ru'=$Dir + '\SAD' ; 'OU=Users,OU=VASP,OU=CG FIX,DC=hq,DC=fix,DC=ru'=$Dir + '\VASP'}



#Указываем параметры письма
$Rcpt = 'afedorov' + "@fix.ru"
$Sndr = 'dchetznera@fix.ru'
$smtpServer = "mail.fix.ru"



if ($User.Mail -ne $null){
	function sendMail{
        $msg = new-object Net.Mail.MailMessage
        $smtp = new-object Net.Mail.SmtpClient($smtpServer)
        $msg.From = "$Sndr"
	    $msg.ReplyTo = "$Sndr"
	    $msg.To.Add("$Rcpt")
	    $msg.IsBodyHTML = $true
	    $msg.subject = "New user - - $DisplayName"
        $msg.body = $DNFolder.$DN + '\htm.html'
        
    $files = Get-ChildItem $DNFolder.$DN
                    {
                    Write-Host “Attaching File :- ” $file
                    $att = New-Object System.Net.Mail.Attachment –ArgumentList $files
                    $msg.Attachments.Add($attachment)
                    }
	
	
	}
}