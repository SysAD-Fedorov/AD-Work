
Import-Module ActiveDirectory

$DomainController = 'dchetznera.hq.fix.ru'

$LastName = Read-Host 'Ведите Фамилию пользователя'

$FirstName = Read-Host 'Ведите Имя пользователя'

$Description = Read-Host 'Ведите Должность пользователя'

$DisplayName = $FirstName + ' ' + $LastName

Write-Host '1.  City Hall'
Write-Host '2.  ICM'
Write-Host '3.  Mobile Commerce'
Write-Host '4.  SocialCentrum'
Write-Host '5.  Special Project'
Write-Host '6.  131'
Write-Host '7.  Accounting'
Write-Host '8.  Advertising Agency'
Write-Host '9.  Epayments'
Write-Host '10. EPN'
Write-Host '11. EWD'
Write-Host '12. Financial Department'
Write-Host '13. HR'
Write-Host '14. Lawyer'
Write-Host '15. Leadership'
Write-Host '16. NeuralNet'
Write-Host '17. OpenCity'
Write-Host '18. PR'
Write-Host '19. Product Partnership'
Write-Host '20. SAD'
Write-Host '21. Secretariat'
Write-Host '22. InformPartner'
Write-Host '23. InformPartner - Call-center'
Write-Host '24. InformPartner - Collaboration'
Write-Host '25. InformPartner - Fraud'
Write-Host '26. InformPartner - Mobile Subscriptions'
Write-Host '27. InformPartner - Moscow'
Write-Host '28. InformPartner - Team Development'
Write-Host '29. InformPartner - Technical Team'
Write-Host '30. InformPartner - Testing Team'
Write-Host '31. VASP'
Write-Host '32. Отдел развития'
Write-Host '33. MegaFon'

$choice = Read-Host 'В какой проект пришел?'
Switch ($choice) {
    1 { $OU = 'OU=City Hall,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    2 { $OU = 'OU=ICM,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    3 { $OU = 'OU=Mobile Commerce,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    4 { $OU = 'OU=SocialCentrum,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    5 { $OU = 'OU=Special Project,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    6 { $OU = 'OU=Users,OU=131,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    7 { $OU = 'OU=Users,OU=Accounting,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    8 { $OU = 'OU=Users,OU=Advertising Agency,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    9 { $OU = 'OU=Users,OU=Epayments,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    10 { $OU = 'OU=Users,OU=EPN,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    11 { $OU = 'OU=Users,OU=EWD,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    12 { $OU = 'OU=Users,OU=Financial Department,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    13 { $OU = 'OU=Users,OU=HR,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    14 { $OU = 'OU=Users,OU=Lawyer,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    15 { $OU = 'OU=Users,OU=Leadership,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    16 { $OU = 'OU=Users,OU=NeuralNet,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    17 { $OU = 'OU=Users,OU=OpenCity,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    18 { $OU = 'OU=Users,OU=PR,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    19 { $OU = 'OU=Users,OU=Product Partnership,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    20 { $OU = 'OU=Users,OU=SAD,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    21 { $OU = 'OU=Users,OU=Secretariat,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    22 { $OU = 'OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    23 { $OU = 'OU=Users,OU=Call-center,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    24 { $OU = 'OU=Users,OU=Collaboration,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    25 { $OU = 'OU=Users,OU=Fraud,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    26 { $OU = 'OU=Users,OU=Mobile Subscriptions,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    27 { $OU = 'OU=Users,OU=Moscow,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    28 { $OU = 'OU=Users,OU=Team Development,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    29 { $OU = 'OU=Users,OU=Technical Team,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    30 { $OU = 'OU=Users,OU=Testing Team,OU=InformPartner,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    31 { $OU = 'OU=Users,OU=VASP,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    32 { $OU = 'OU=Users,OU=ORSE,OU=CG FIX,DC=hq,DC=fix,DC=ru' }
    33 { $OU = 'OU=Users,OU=MegaFon,DC=hq,DC=fix,DC=ru' }
    
}

if ($OU -notmatch '.*megafon') {
    $DefaultGroups = 'DisableScripts', 'ConfluenceUsersGroup', 'JiraUsersGroup'
    $SAM = $FirstName[0].ToString().ToLower() + $LastName.ToLower()
    $mail = $SAM + '@fix.ru'
    $CHANGE_PASSWORD_AT_LOGON = $true
    if ( (Read-Host "Програмист? (y/n)") -eq "y" ) {
        $DefaultGroups = $DefaultGroups + 'GitLabUsersGroup'
    }
    
}
else {
    $DefaultGroups = 'ConfluenceUsersGroup', 'JiraUsersGroup'
    $SAM = $FirstName.ToLower() + '.' + $LastName.ToLower()
    $mail = $SAM + '@Megafon.ru'
    $company = 'External'
    $CHANGE_PASSWORD_AT_LOGON = $false
}

if ((Get-ADUser -filter *).SamAccountName -eq $SAM) {
    $NextName = Read-Host 'Пользователь с такой учетной записью уже существует. Пожалуйства введите отчество'
    $x = 0
    do {
        $x
        $SAM = $SAM + $NextName[$x].ToString().ToLower()
        $x = $x + 1
        $SAM
    }
    while ((Get-ADUser -filter *).SamAccountName -eq $SAM)
}

$userPrincipalName = $SAM + '@hq.fix.ru'

Add-Type -AssemblyName System.Web
$Password = [System.Web.Security.Membership]::GeneratePassword(8, 1)

<# С помощью командлета New-ADUser добавл?ем в AD пользователей. Здесь используются строго определенные параметры для задания нужных опций учетной запи?и пользовател?, #>
<# полный перечень которых можно по?мотреть по ??ылке http://technet.microsoft.com/en-us/library/ee617253.aspx. Так, например, дл? задани? отче?тва необходимо и?пользовать параметр -OtherName. #>
New-ADUser -Name $DisplayName -SamAccountName $SAM -UserPrincipalName $userPrincipalName -DisplayName $DisplayName -GivenName $firstname -Surname $lastname -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $CHANGE_PASSWORD_AT_LOGON -Path $OU -Description $Description -EmailAddress $mail -Server $DomainController -Company $company

Write-Host "Создание учётной записи, пожалуйста подождите..." -ForegroundColor DarkCyan

ForEach ($Group in $DefaultGroups) {
    Add-ADGroupMember -Identity $Group -Members $SAM -Server $DomainController
    }
Write-Host $Password
$Sndr = 'dchetznera@fix.ru'
$Rcpt = 'afedorov@fix.ru'

function sendMail {
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
    Логин:          $SAM
    Подразделение:	$OU
    Пароль:         $Password
"@
    $smtp.Send($msg)
}
sendMail