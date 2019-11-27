#   удаляем все переменные, созданные в текущем сеансе
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue

<#      константы  #>

$EXCHANGE_SERVER = 'http://exchserver/PowerShell/'
$EXCHANGE_DATABASE = 'MDB2'
$ROOT_OU = 'OU=Пользователи,DC=domain,dc=local'
$DOMAIN = "domain.local"
$COMPANY = 'ООО "Пирожковая"'
#   если несколько компаний добавляем через запятую - (, 'ООО "Пирожок"')
#   генерируем пароль для первого входа в систему
$CHANGE_PASSWORD_AT_LOGON = $false

<#     Транслитерирует русские символы в латиницу в соотвествии с тех.политикой     @param String text - текст на русском     @return String оттранслитерованный текст #>

function TranslitRu2Lat ([String] $text) {

    $translitTable = @{ 
        [char]'а' = "a";
        [char]'б' = "b";
        [char]'в' = "v";
        [char]'г' = "g";
        [char]'д' = "d";
        [char]'е' = "e";
        [char]'ё' = "e";
        [char]'ж' = "zh";
        [char]'з' = "z";
        [char]'и' = "i";
        [char]'й' = "y";
        [char]'к' = "k";
        [char]'л' = "l";
        [char]'м' = "m";
        [char]'н' = "n";
        [char]'о' = "o";
        [char]'п' = "p";
        [char]'р' = "r";
        [char]'с' = "s";
        [char]'т' = "t";
        [char]'у' = "u";
        [char]'ф' = "f";
        [char]'х' = "h";
        [char]'ц' = "ts";
        [char]'ч' = "ch";
        [char]'ш' = "sh";
        [char]'щ' = "sch";
        [char]'ъ' = "";
        [char]'ы' = "y";
        [char]'ь' = "";
        [char]'э' = "e";
        [char]'ю' = "u";
        [char]'я' = "ya";
    }

    # текст в нижний регистр
    $text = $text.ToLower()

    $result = ""

    foreach ($c in $text.ToCharArray()) {
        if ($translitTable[$c] -cne $null ) {
            $result += $translitTable[$c]
        }
        else {
            $result += $c
        }
    }

    return [String] $result
}

<#     Преобразует из фамилии и имени в алиас почтового ящика familiya.imya     @param String surname - фамилия     @param String givenName - имя     @return String - email alias #>

function NameToEmailAlias ([String] $surname, [String] $givenName, [String] $company) {
    $surname = TranslitRu2Lat $surname
    $givenName = TranslitRu2Lat $givenName

    #   по умолчанию email-alias: surname.givenname@domain.ru
    $result = $surname + "." + $givenName

    #   если ООО "Пирожок", то email-alias: givenname_surname@pirozok.ru
    if ($company -eq 'ООО "Пирожок"') {
        $result = $givenName + "_" + $surname
    }

    return $result
}

<#     Преобразует из фамилии и имени в SamAccountName     @param String surname - фамилия     @param String givenName - имя     @return String - SamAccountName #>

function NameToSamAccountName ([String] $Surname, [String] $GivenName) {

    #   транслитерируем фамилию и имя
    $TranslitSurname = TranslitRu2Lat($Surname)
    $TranslitGivenName = TranslitRu2Lat($GivenName)

    #   обрезаем лишние символы в транслитерованной фамилии 
    if ($TranslitSurname.Length -gt 5) {
        $TranslitSurname = $TranslitSurname.Substring(0, 5)
    }

    #   обрезаем лишние символы в транслитерованном имени
    if ($TranslitGivenName.Length -gt 3) {
        $TranslitGivenName = $TranslitGivenName.Substring(0, 3)
    }

    return $TranslitSurname + $TranslitGivenName
}

<#     Преобразует массив компаний в строку #>

function CompanyArrayToString {
    $count = 0
    $result = ""
    $COMPANY | ForEach-Object { $result += if ($count -eq 0) { $count.ToString() + ": " + $_ } else { ", " + $count.ToString() + ": " + $_ }; $count++ }

    return $result
}

<#      Блок функций, запрашивающих ввести данные,      валидируют введенные значения и возвращают их,     если данные корректны #>

#   Фамилия

function InputSurname {

    do {
        #   очищяем переменную и запрашиваем фамилию у пользователя
        $Surname = "" 
        $Surname = Read-Host "Фамилия";

        #   выводим сообщение если ошибке ввода если слишком короткая строка
        if ($Surname.Length -lt 2) {
            Write-Host "Слишком короткое значение" -ForegroundColor Red
        }
    } while ($Surname.Length -lt 2)

    # удаляем все пробелы из строки и возвращаем
    return $Surname.Replace(" ", "")
}

#   Имя

function InputGivenName {
    do {
        #   очищяем переменную и запрашиваем имя нового пользователя
        $GivenName = "" 
        $GivenName = Read-Host "Имя";

        #   выводим сообщение если ошибке ввода если слишком короткая строка
        if ($GivenName.Length -lt 3) {
            Write-Host "Слишком короткое значение" -ForegroundColor Red
        }
    } while ($GivenName.Length -lt 3)

    #   удаляем все пробелы из строки и возвращаем
    return $GivenName.Replace(" ", "")
}

# Отчество

function InputMiddleName {
    #   очищяем переменную и запрашиваем отчество нового пользователя
    $MiddleName = ""
    $MiddleName = Read-Host "Отчество";

    #   удаляем все пробелы из строки и возвращаем
    return $MiddleName.Replace(" ", "")
}

# Мобильный телефон

function InputMobile {
    do {        
        $Mobile = "" 
        $Mobile = Read-Host "Мобильный в формате (+79191234567)";

        #   выводим сообщение если неправильный формат ввода
        if (($Mobile -match "^\+[0-9]{11}$|^$") -eq $false) {
            Write-Host "Не соблюдён формат ввода" -ForegroundColor Red
        }
    } while ( ($Mobile -match "^\+[0-9]{11}$|^$") -eq $false )

    return $Mobile
}

# ID компании

function InputCompanyID {

    #   преобразуем массив ID компаний в строку
    $CompanyString = CompanyArrayToString

    #   проверяем что введено число из предложенного диапазона
    do {
        $CompanyID = ""
        [int] $CompanyID = Read-Host ("Компания ($CompanyString)")

        if ((($CompanyID -match "^[0-9]+$") -eq $false) -or ($CompanyID -ge $COMPANY.Length) -or ($CompanyID -lt 0)) {
            Write-Host "Не соблюден формат ввода" -ForegroundColor Red
        }
    } while ( (($CompanyID -match "^[0-9]+$") -eq $false) -or ($CompanyID -ge $COMPANY.Length) -or ($CompanyID -lt 0) )

    return $CompanyID
}

# Отдел

function InputDepartment {

    do {
        $Department = ""
        $Department = Read-Host "Отдел"

        if ($Department.Length -lt 2) {
            Write-Host "Слишком короткое значение" -ForegroundColor Red
        }
    } while ( $Department.Length -lt 2 )

    return $Department

}

# Должность

function InputTitle {
    do {
        $Title = ""
        $Title = Read-Host "Должность"

        if ($Title.Length -lt 4) {
            Write-Host "Слишком короткое значение" -ForegroundColor Red
        }
    } while ($Title.Length -lt 4)

    return $Title
}

# Создавать почтовый ящик?

function InputEnableMailbox {
    do {
        $EnableMailbox = ""
        $EnableMailbox = Read-Host "Создавать почтовый ящик? (y/n)"
    } while ( ($EnableMailbox -match "^[yn]$") -eq $false )

    return $EnableMailbox
}

<#     Выводит на экран данные для проверки создания новой учётной записи #>

function WriteHostNewUserAttributes ($User) {
    Write-Host "" -ForegroundColor DarkCyan
    Write-Host "ФИО:" $User.Surname $User.GivenName $User.OtherName -ForegroundColor DarkCyan
    Write-Host "Мобильный:" $User.MobilePhone -ForegroundColor DarkCyan
    Write-Host "Компания:" $COMPANY[$user.CompanyID] -ForegroundColor DarkCyan
    Write-Host "Отдел:" $User.Department -ForegroundColor DarkCyan
    Write-Host "Должность:" $User.Title -ForegroundColor DarkCyan

    if ($User.EnableMailbox -eq "y") {
        Write-Host "Электронная почта: создавать" -ForegroundColor DarkCyan
    }
    else {
        Write-Host "Электронная почта: не создавать" -ForegroundColor DarkCyan
    }

    Write-Host "" -ForegroundColor DarkCyan
}

<#     Создаёт текстовый файл с данными нового пользователя #>

function CreateTxtFile($User) {
    "
    Логин: " + $User.UserPrincipalName + "
    Пароль: " + $User.Password | Out-File ($User.SamAccountName + ".txt")

    Write-Host ""
    Write-Host "Пользователь:" $User.UserPrincipalName -ForegroundColor DarkCyan
    Write-Host "Пароль для первого входа:" $User.Password -ForegroundColor DarkCyan
    Write-Host "Создан файл" ($User.SamAccountName + ".txt") "с данными аутенфтификации." -ForegroundColor DarkCyan
    Write-Host ""
}

# основная функция

function main {

    try {

        #   обнулили массив полученных данных
        $NewUser = @{ }

        #   получаем данные        
        [String] $NewUser.Surname = InputSurname
        [String] $NewUser.GivenName = InputGivenName
        [String] $NewUser.OtherName = InputMiddleName
        [String] $NewUser.MobilePhone = Inputmobile
        [String] $NewUser.CompanyID = InputCompanyID
        [String] $NewUser.Department = InputDepartment
        [String] $NewUser.Title = InputTitle
        [String] $NewUser.EnableMailbox = InputEnableMailbox

        #   генерим на основе полученных
        [String] $NewUser.Company = $COMPANY[$NewUser.CompanyID]
        [String] $NewUser.SamAccountName = NameToSamAccountName $NewUser.Surname $NewUser.GivenName
        [String] $NewUser.EmailAlias = NameToEmailAlias $NewUser.Surname $NewUser.GivenName $NewUser.Company
        [String] $NewUser.ObjName = $NewUser.Surname + " " + $NewUser.GivenName + " " + $NewUser.OtherName #название объекта в AD
        [String] $NewUser.DisplayName = $NewUser.Surname + " " + $NewUser.GivenName
        [String] $NewUser.UserPrincipalName = $NewUser.Surname + " " + $NewUser.GivenName + "@" + $DOMAIN

        # ООО "Пирожок" заменяем на ООО "Пирожок и чебурек" - полное наименование (в дальнейшем пригодится для подписи в почте)
        if ($NewUser.Company -eq 'ООО "Пирожок"') {
            $NewUser.Company = 'ООО "Пирожок и чебурек"'
        }

        #  TODO: Временно, изменить!
        #  [String] $NewUser.Password = Get-Random -Minimum 100000 -Maximum 999999
        [String] $NewUser.Password = "Qwerty123"

        #   генерируем OU в котором будет создан объект пользователя, из названия OU удаляем все кавычки

        #   TODO: Временно, изменить!
        #  [String] $NewUser.OU = "OU="+($COMPANY[$NewUser.CompanyID]).Replace('"', '')+",OU=Пользователи,DC=domain,DC=local"       
        [String] $NewUser.OU = "OU=" + ($COMPANY[$NewUser.CompanyID]).Replace('"', '') + ",OU=Пользователи,DC=domain,DC=local"

        #   выводим пользователю для проверки того, что он навводил и что сгенерировалось
        WriteHostNewUserAttributes $NewUser    

        #   спрашиваем пользователя, всё ли верно?
        if ( (Read-Host "Всё верно? (y/n)") -eq "y" ) {
            #   Если всё верно - создаём учётку
            Write-Host "Создание учётной записи, пожалуйста подождите..." -ForegroundColor DarkCyan

            #   подгружаем модуль AD и создаём нового пользователя, дожидаемся выполнения процесса
            Import-Module ActiveDirectory
            New-ADUser -Name $NewUser.ObjName -Surname $NewUser.Surname -GivenName $NewUser.GivenName -OtherName $NewUser.OtherName -MobilePhone $NewUser.MobilePhone -Company $NewUser.Company -Department $NewUser.Department -Title $NewUser.Title -SamAccountName $NewUser.SamAccountName -DisplayName $NewUser.DisplayName -UserPrincipalName $NewUser.UserPrincipalName -ChangePasswordAtLogon $CHANGE_PASSWORD_AT_LOGON -Path $NewUser.OU -AccountPassword (ConvertTo-SecureString -String $NewUser.Password -AsPlainText -Force) -Enabled $true | Out-Null
            Write-Host "Учётная запись успешно создана." -ForegroundColor Green

            #   Если требуется - создаём новую почту для сотрудника
            if ($NewUser.EnableMailbox -eq "y") {

                Write-Host "Создание электронной почты, пожалуйста подождите..." -ForegroundColor DarkCyan

                #   установили удаленную сессию с эксчендж, подавляем вывод команд чтобы не смущать техподдержку
                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $EXCHANGE_SERVER -Authentication Kerberos
                Import-PSSession $Session -DisableNameChecking | Out-Null

                #   создали мэйлбокс
                Enable-Mailbox -Alias $NewUser.EmailAlias -Identity $NewUser.UserPrincipalName -Database $EXCHANGE_DATABASE #| Out-Null

                #   закрыли сессию, подавляем 
                Remove-PSSession $Session | Out-Null

                Write-Host "Почтовый ящик успешно создан." -ForegroundColor Green

                #   отправляем пользователю первое письмо с инструкциями
                Write-Host "Отправка Email пользователю с инструкциями, пожалуйста подождите..." -ForegroundColor DarkCyan

                # send an email to notify
                $subject = "Информация от Cлужбы ИТ"
                $body = @"
                <р>Здравствуйте!
                Вас приветствует служба по ИТ ООО "Пирожок и чебурек"!<р>
                <р>В случае возникновения вопросов или затруднений, связанных с информационными технологиями, обращайтесь, пожалуйста, в службу технической поддержки:
                тел.  (351) 123-34-45 (вн. 1), эл. почта <а href='mailto:tehsupport@pirozok.ru'>tehsupport@pirozok.ru в будние дни с 9:00 до 17:30<р>
                C полным списком сервисов ИТ можно ознакомиться на корпоративном портале <а href='https://portal.pirozok.ru/index.php'>https://portal.pirozok.ru/index.php<р>

                <р>Желаем приятной работы!<р>
"@              

                #   ожидаем, чтобы прошла репликация  
                Start-Sleep -Seconds 20
                #   отправляем сообщение
                Send-Mailmessage -smtpServer 'mail.pirozok.ru' -from 'tehsupport@pirozok.ru' -to ((Get-ADUser $NewUser.SamAccountName -Properties mail).mail) -subject $subject -body $body -BodyAsHtml -Encoding UTF8

                Write-Host "Email отправлен успешно." -ForegroundColor Green

                #   создаём txt файл с данными нового пользователя
                #   TODO: Временно, раскомментировать!
                #   CreateTxtFile $NewUser
            }

        }
        else {
            #   Если что-то неправильно - заново запускаем диалог
            main
        }

        if ( (Read-Host "Создать ещё одну учётную запись? (y/n)") -eq "y" ) {
            main
        }

        return

    }
    catch {

        Write-Host "Произошла ошибка!" -ForegroundColor Red

        if ( (Read-Host "Создать ещё одну учётную запись? (y/n)") -eq "y" ) {
            main
        }

    }

}

main