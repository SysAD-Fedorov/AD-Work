function mail ($message)
{
Send-MailMessage `
-to "<officelog@fix.ru>" `
-from "<1C@fix.ru>" `
-subject "reapir_1C_test_UP" `
-body $message `
-smtpserver "www.fix.ru" `
-Encoding ([System.Text.Encoding]::UTF8)
}

$n=Get-Content "C:\scripts\Reapir_1C_backup_test\1c8_UT_test_Log.txt"  # | % {$_ -join "`r`n"}
mail "$($n | out-string)";