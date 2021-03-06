#   ������� ��� ����������, ��������� � ������� ������
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue

<#      ���������  #>

$EXCHANGE_SERVER = 'http://exchserver/PowerShell/'
$EXCHANGE_DATABASE = 'MDB2'
$ROOT_OU = 'OU=������������,DC=domain,dc=local'
$DOMAIN = "domain.local"
$COMPANY = '��� "����������"'
#   ���� ��������� �������� ��������� ����� ������� - (, '��� "�������"')
#   ���������� ������ ��� ������� ����� � �������
$CHANGE_PASSWORD_AT_LOGON = $false

<#     ��������������� ������� ������� � �������� � ����������� � ���.���������     @param String text - ����� �� �������     @return String ������������������� ����� #>

function TranslitRu2Lat ([String] $text) {

    $translitTable = @{ 
        [char]'�' = "a";
        [char]'�' = "b";
        [char]'�' = "v";
        [char]'�' = "g";
        [char]'�' = "d";
        [char]'�' = "e";
        [char]'�' = "e";
        [char]'�' = "zh";
        [char]'�' = "z";
        [char]'�' = "i";
        [char]'�' = "y";
        [char]'�' = "k";
        [char]'�' = "l";
        [char]'�' = "m";
        [char]'�' = "n";
        [char]'�' = "o";
        [char]'�' = "p";
        [char]'�' = "r";
        [char]'�' = "s";
        [char]'�' = "t";
        [char]'�' = "u";
        [char]'�' = "f";
        [char]'�' = "h";
        [char]'�' = "ts";
        [char]'�' = "ch";
        [char]'�' = "sh";
        [char]'�' = "sch";
        [char]'�' = "";
        [char]'�' = "y";
        [char]'�' = "";
        [char]'�' = "e";
        [char]'�' = "u";
        [char]'�' = "ya";
    }

    # ����� � ������ �������
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

<#     ����������� �� ������� � ����� � ����� ��������� ����� familiya.imya     @param String surname - �������     @param String givenName - ���     @return String - email alias #>

function NameToEmailAlias ([String] $surname, [String] $givenName, [String] $company) {
    $surname = TranslitRu2Lat $surname
    $givenName = TranslitRu2Lat $givenName

    #   �� ��������� email-alias: surname.givenname@domain.ru
    $result = $surname + "." + $givenName

    #   ���� ��� "�������", �� email-alias: givenname_surname@pirozok.ru
    if ($company -eq '��� "�������"') {
        $result = $givenName + "_" + $surname
    }

    return $result
}

<#     ����������� �� ������� � ����� � SamAccountName     @param String surname - �������     @param String givenName - ���     @return String - SamAccountName #>

function NameToSamAccountName ([String] $Surname, [String] $GivenName) {

    #   ��������������� ������� � ���
    $TranslitSurname = TranslitRu2Lat($Surname)
    $TranslitGivenName = TranslitRu2Lat($GivenName)

    #   �������� ������ ������� � ����������������� ������� 
    if ($TranslitSurname.Length -gt 5) {
        $TranslitSurname = $TranslitSurname.Substring(0, 5)
    }

    #   �������� ������ ������� � ����������������� �����
    if ($TranslitGivenName.Length -gt 3) {
        $TranslitGivenName = $TranslitGivenName.Substring(0, 3)
    }

    return $TranslitSurname + $TranslitGivenName
}

<#     ����������� ������ �������� � ������ #>

function CompanyArrayToString {
    $count = 0
    $result = ""
    $COMPANY | ForEach-Object { $result += if ($count -eq 0) { $count.ToString() + ": " + $_ } else { ", " + $count.ToString() + ": " + $_ }; $count++ }

    return $result
}

<#      ���� �������, ������������� ������ ������,      ���������� ��������� �������� � ���������� ��,     ���� ������ ��������� #>

#   �������

function InputSurname {

    do {
        #   ������� ���������� � ����������� ������� � ������������
        $Surname = "" 
        $Surname = Read-Host "�������";

        #   ������� ��������� ���� ������ ����� ���� ������� �������� ������
        if ($Surname.Length -lt 2) {
            Write-Host "������� �������� ��������" -ForegroundColor Red
        }
    } while ($Surname.Length -lt 2)

    # ������� ��� ������� �� ������ � ����������
    return $Surname.Replace(" ", "")
}

#   ���

function InputGivenName {
    do {
        #   ������� ���������� � ����������� ��� ������ ������������
        $GivenName = "" 
        $GivenName = Read-Host "���";

        #   ������� ��������� ���� ������ ����� ���� ������� �������� ������
        if ($GivenName.Length -lt 3) {
            Write-Host "������� �������� ��������" -ForegroundColor Red
        }
    } while ($GivenName.Length -lt 3)

    #   ������� ��� ������� �� ������ � ����������
    return $GivenName.Replace(" ", "")
}

# ��������

function InputMiddleName {
    #   ������� ���������� � ����������� �������� ������ ������������
    $MiddleName = ""
    $MiddleName = Read-Host "��������";

    #   ������� ��� ������� �� ������ � ����������
    return $MiddleName.Replace(" ", "")
}

# ��������� �������

function InputMobile {
    do {        
        $Mobile = "" 
        $Mobile = Read-Host "��������� � ������� (+79191234567)";

        #   ������� ��������� ���� ������������ ������ �����
        if (($Mobile -match "^\+[0-9]{11}$|^$") -eq $false) {
            Write-Host "�� ������� ������ �����" -ForegroundColor Red
        }
    } while ( ($Mobile -match "^\+[0-9]{11}$|^$") -eq $false )

    return $Mobile
}

# ID ��������

function InputCompanyID {

    #   ����������� ������ ID �������� � ������
    $CompanyString = CompanyArrayToString

    #   ��������� ��� ������� ����� �� ������������� ���������
    do {
        $CompanyID = ""
        [int] $CompanyID = Read-Host ("�������� ($CompanyString)")

        if ((($CompanyID -match "^[0-9]+$") -eq $false) -or ($CompanyID -ge $COMPANY.Length) -or ($CompanyID -lt 0)) {
            Write-Host "�� �������� ������ �����" -ForegroundColor Red
        }
    } while ( (($CompanyID -match "^[0-9]+$") -eq $false) -or ($CompanyID -ge $COMPANY.Length) -or ($CompanyID -lt 0) )

    return $CompanyID
}

# �����

function InputDepartment {

    do {
        $Department = ""
        $Department = Read-Host "�����"

        if ($Department.Length -lt 2) {
            Write-Host "������� �������� ��������" -ForegroundColor Red
        }
    } while ( $Department.Length -lt 2 )

    return $Department

}

# ���������

function InputTitle {
    do {
        $Title = ""
        $Title = Read-Host "���������"

        if ($Title.Length -lt 4) {
            Write-Host "������� �������� ��������" -ForegroundColor Red
        }
    } while ($Title.Length -lt 4)

    return $Title
}

# ��������� �������� ����?

function InputEnableMailbox {
    do {
        $EnableMailbox = ""
        $EnableMailbox = Read-Host "��������� �������� ����? (y/n)"
    } while ( ($EnableMailbox -match "^[yn]$") -eq $false )

    return $EnableMailbox
}

<#     ������� �� ����� ������ ��� �������� �������� ����� ������� ������ #>

function WriteHostNewUserAttributes ($User) {
    Write-Host "" -ForegroundColor DarkCyan
    Write-Host "���:" $User.Surname $User.GivenName $User.OtherName -ForegroundColor DarkCyan
    Write-Host "���������:" $User.MobilePhone -ForegroundColor DarkCyan
    Write-Host "��������:" $COMPANY[$user.CompanyID] -ForegroundColor DarkCyan
    Write-Host "�����:" $User.Department -ForegroundColor DarkCyan
    Write-Host "���������:" $User.Title -ForegroundColor DarkCyan

    if ($User.EnableMailbox -eq "y") {
        Write-Host "����������� �����: ���������" -ForegroundColor DarkCyan
    }
    else {
        Write-Host "����������� �����: �� ���������" -ForegroundColor DarkCyan
    }

    Write-Host "" -ForegroundColor DarkCyan
}

<#     ������ ��������� ���� � ������� ������ ������������ #>

function CreateTxtFile($User) {
    "
    �����: " + $User.UserPrincipalName + "
    ������: " + $User.Password | Out-File ($User.SamAccountName + ".txt")

    Write-Host ""
    Write-Host "������������:" $User.UserPrincipalName -ForegroundColor DarkCyan
    Write-Host "������ ��� ������� �����:" $User.Password -ForegroundColor DarkCyan
    Write-Host "������ ����" ($User.SamAccountName + ".txt") "� ������� ���������������." -ForegroundColor DarkCyan
    Write-Host ""
}

# �������� �������

function main {

    try {

        #   �������� ������ ���������� ������
        $NewUser = @{ }

        #   �������� ������        
        [String] $NewUser.Surname = InputSurname
        [String] $NewUser.GivenName = InputGivenName
        [String] $NewUser.OtherName = InputMiddleName
        [String] $NewUser.MobilePhone = Inputmobile
        [String] $NewUser.CompanyID = InputCompanyID
        [String] $NewUser.Department = InputDepartment
        [String] $NewUser.Title = InputTitle
        [String] $NewUser.EnableMailbox = InputEnableMailbox

        #   ������� �� ������ ����������
        [String] $NewUser.Company = $COMPANY[$NewUser.CompanyID]
        [String] $NewUser.SamAccountName = NameToSamAccountName $NewUser.Surname $NewUser.GivenName
        [String] $NewUser.EmailAlias = NameToEmailAlias $NewUser.Surname $NewUser.GivenName $NewUser.Company
        [String] $NewUser.ObjName = $NewUser.Surname + " " + $NewUser.GivenName + " " + $NewUser.OtherName #�������� ������� � AD
        [String] $NewUser.DisplayName = $NewUser.Surname + " " + $NewUser.GivenName
        [String] $NewUser.UserPrincipalName = $NewUser.Surname + " " + $NewUser.GivenName + "@" + $DOMAIN

        # ��� "�������" �������� �� ��� "������� � �������" - ������ ������������ (� ���������� ���������� ��� ������� � �����)
        if ($NewUser.Company -eq '��� "�������"') {
            $NewUser.Company = '��� "������� � �������"'
        }

        #  TODO: ��������, ��������!
        #  [String] $NewUser.Password = Get-Random -Minimum 100000 -Maximum 999999
        [String] $NewUser.Password = "Qwerty123"

        #   ���������� OU � ������� ����� ������ ������ ������������, �� �������� OU ������� ��� �������

        #   TODO: ��������, ��������!
        #  [String] $NewUser.OU = "OU="+($COMPANY[$NewUser.CompanyID]).Replace('"', '')+",OU=������������,DC=domain,DC=local"       
        [String] $NewUser.OU = "OU=" + ($COMPANY[$NewUser.CompanyID]).Replace('"', '') + ",OU=������������,DC=domain,DC=local"

        #   ������� ������������ ��� �������� ����, ��� �� �������� � ��� ���������������
        WriteHostNewUserAttributes $NewUser    

        #   ���������� ������������, �� �� �����?
        if ( (Read-Host "�� �����? (y/n)") -eq "y" ) {
            #   ���� �� ����� - ������ ������
            Write-Host "�������� ������� ������, ���������� ���������..." -ForegroundColor DarkCyan

            #   ���������� ������ AD � ������ ������ ������������, ���������� ���������� ��������
            Import-Module ActiveDirectory
            New-ADUser -Name $NewUser.ObjName -Surname $NewUser.Surname -GivenName $NewUser.GivenName -OtherName $NewUser.OtherName -MobilePhone $NewUser.MobilePhone -Company $NewUser.Company -Department $NewUser.Department -Title $NewUser.Title -SamAccountName $NewUser.SamAccountName -DisplayName $NewUser.DisplayName -UserPrincipalName $NewUser.UserPrincipalName -ChangePasswordAtLogon $CHANGE_PASSWORD_AT_LOGON -Path $NewUser.OU -AccountPassword (ConvertTo-SecureString -String $NewUser.Password -AsPlainText -Force) -Enabled $true | Out-Null
            Write-Host "������� ������ ������� �������." -ForegroundColor Green

            #   ���� ��������� - ������ ����� ����� ��� ����������
            if ($NewUser.EnableMailbox -eq "y") {

                Write-Host "�������� ����������� �����, ���������� ���������..." -ForegroundColor DarkCyan

                #   ���������� ��������� ������ � ��������, ��������� ����� ������ ����� �� ������� ������������
                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $EXCHANGE_SERVER -Authentication Kerberos
                Import-PSSession $Session -DisableNameChecking | Out-Null

                #   ������� ��������
                Enable-Mailbox -Alias $NewUser.EmailAlias -Identity $NewUser.UserPrincipalName -Database $EXCHANGE_DATABASE #| Out-Null

                #   ������� ������, ��������� 
                Remove-PSSession $Session | Out-Null

                Write-Host "�������� ���� ������� ������." -ForegroundColor Green

                #   ���������� ������������ ������ ������ � ������������
                Write-Host "�������� Email ������������ � ������������, ���������� ���������..." -ForegroundColor DarkCyan

                # send an email to notify
                $subject = "���������� �� C����� ��"
                $body = @"
                <�>������������!
                ��� ������������ ������ �� �� ��� "������� � �������"!<�>
                <�>� ������ ������������� �������� ��� �����������, ��������� � ��������������� ������������, �����������, ����������, � ������ ����������� ���������:
                ���.  (351) 123-34-45 (��. 1), ��. ����� <� href='mailto:tehsupport@pirozok.ru'>tehsupport@pirozok.ru � ������ ��� � 9:00 �� 17:30<�>
                C ������ ������� �������� �� ����� ������������ �� ������������� ������� <� href='https://portal.pirozok.ru/index.php'>https://portal.pirozok.ru/index.php<�>

                <�>������ �������� ������!<�>
"@              

                #   �������, ����� ������ ����������  
                Start-Sleep -Seconds 20
                #   ���������� ���������
                Send-Mailmessage -smtpServer 'mail.pirozok.ru' -from 'tehsupport@pirozok.ru' -to ((Get-ADUser $NewUser.SamAccountName -Properties mail).mail) -subject $subject -body $body -BodyAsHtml -Encoding UTF8

                Write-Host "Email ��������� �������." -ForegroundColor Green

                #   ������ txt ���� � ������� ������ ������������
                #   TODO: ��������, �����������������!
                #   CreateTxtFile $NewUser
            }

        }
        else {
            #   ���� ���-�� ����������� - ������ ��������� ������
            main
        }

        if ( (Read-Host "������� ��� ���� ������� ������? (y/n)") -eq "y" ) {
            main
        }

        return

    }
    catch {

        Write-Host "��������� ������!" -ForegroundColor Red

        if ( (Read-Host "������� ��� ���� ������� ������? (y/n)") -eq "y" ) {
            main
        }

    }

}

main