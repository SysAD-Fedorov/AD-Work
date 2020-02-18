function mail ($message)
{
Send-MailMessage `
-to "<officelog@fix.ru>" `
-from "<1C@fix.ru>" `
-subject "reapir_1C_test_BP" `
-body $message `
-smtpserver "www.fix.ru" `
-Encoding ([System.Text.Encoding]::UTF8)
}

$n=Get-Content "C:\scripts\1cBackup\BAK\Через_выгрузку\Reapir_1C_backup_test\mail_send_script\1c8_BP_test_Log.txt"  # | % {$_ -join "`r`n"}
mail "$($n | out-string)";