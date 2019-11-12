
Import-Module ActiveDirectory


$DomainController = 'dchetznera.hq.fix.ru'

$DefaultGroups = 'ConfluenceUsersGroup', 'JiraUsersGroup'

#$SAM = Read-Host '??????? ??????'

$LastName = Read-Host 'Ведите Фамилию пользователя'

#$LastName =$LastName.ToLower()

$FirstName = Read-Host 'Ведите Имя пользователя'

#$FirstName =$FirstName.ToLower()

$DisplayName = $FirstName + ' ' + $LastName

$SAM = $FirstName.ToLower() + '.' + $LastName.ToLower()

$userPrincipalName = $SAM + '@hq.fix.ru'

$mail = $SAM + '@megafon.ru'

# (Get-ADUser -filter *).SamAccountName -eq $SAM

$OU = 'OU=Users,OU=MegaFon,DC=hq,DC=fix,DC=ru'




Add-Type -AssemblyName System.Web
$Password = [System.Web.Security.Membership]::GeneratePassword(8,0)

 
<# С помощью командлета New-ADUser добавл?ем в AD пользователей. Здесь используются строго определенные параметры для задания нужных опций учетной запи?и пользовател?, #>
<# полный перечень которых можно по?мотреть по ??ылке http://technet.microsoft.com/en-us/library/ee617253.aspx. Так, например, дл? задани? отче?тва необходимо и?пользовать параметр -OtherName. #>

New-ADUser -Name $DisplayName -SamAccountName $SAM -UserPrincipalName $userPrincipalName -DisplayName $DisplayName -GivenName $firstname -Surname $lastname -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true -Path $OU -Description $Description -EmailAddress $mail -Server $DomainController -Company External

ForEach ($Group in $DefaultGroups)
    {
    Add-ADGroupMember -Identity $Group -Members $SAM -Server $DomainController
    }
    
Write-Host $Password

$Sndr = 'dchetznera@fix.ru'

$Rcpt = 'afedorov@fix.ru'

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

Пользователь:   $DisplayName
Логин:          $userPrincipalName
Подразделение:	$OU
Пароль:         $Password
"@

    #Sending email
    $smtp.Send($msg)

}

#Calling function
sendMail