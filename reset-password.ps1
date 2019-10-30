Import-module ActiveDirectory

$sam = Read-Host 'введите учетку пользователя'

Add-Type -AssemblyName System.Web

$NewPasswd = [System.Web.Security.Membership]::GeneratePassword(8, 1)

Set-ADAccountPassword $sam -NewPassword (ConvertTo-SecureString $NewPasswd -AsPlainText -Force) -Reset -PassThru | Set-ADuser -ChangePasswordAtLogon $True

Write-Host $NewPasswd