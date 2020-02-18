@echo off

@set datetemp=%date:~-10%


"C:\Program Files (x86)\1cv8\8.3.5.1248\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\BP_test_backup" /N backup /P y9GNUL51GSry /DisableStartupMessages /RestoreIB C:\backup\BP\BP_%datetemp%.dt /Out "C:\scripts\Reapir_1C_backup_test\1c8_BP_test_Log.txt"  
"C:\Program Files (x86)\1cv8\8.3.5.1248\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\BP_test_backup" /N backup /P y9GNUL51GSry /DisableStartupMessages /IBCheckAndRepair -LogAndRefsIntegrity /Out "C:\scripts\Reapir_1C_backup_test\1c8_BP_test_Log.txt" -NoTruncate 
call "C:\scripts\1cBackup\BAK\Через_выгрузку\Reapir_1C_backup_test\mail_send_script\send_log_BP.bat"

"C:\Program Files (x86)\1cv8\8.3.4.408\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\UT_test_backup" /N backup /P y9GNUL51GSry /DisableStartupMessages /RestoreIB C:\backup\UT\UT_%datetemp%.dt /Out "C:\scripts\Reapir_1C_backup_test\1c8_UT_test_Log.txt"  
"C:\Program Files (x86)\1cv8\8.3.4.408\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\UT_test_backup" /N backup /P y9GNUL51GSry /DisableStartupMessages /IBCheckAndRepair -LogAndRefsIntegrity /Out "C:\scripts\Reapir_1C_backup_test\1c8_UT_test_Log.txt" -NoTruncate 
call "C:\scripts\1cBackup\BAK\Через_выгрузку\Reapir_1C_backup_test\mail_send_script\send_log_UT.bat"

"C:\Program Files (x86)\1cv8\8.3.4.408\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\ZUP_test_backup" /N backup /P y9GNUL51GSry /DisableStartupMessages /RestoreIB C:\backup\ZUP\ZUP_%datetemp%.dt /Out "C:\scripts\Reapir_1C_backup_test\1c8_ZUP_test_Log.txt" 
"C:\Program Files (x86)\1cv8\8.3.4.408\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\ZUP_test_backup" /N backup /P y9GNUL51GSry /DisableStartupMessages /IBCheckAndRepair -LogAndRefsIntegrity /Out "C:\scripts\Reapir_1C_backup_test\1c8_ZUP_test_Log.txt" -NoTruncate  
call "C:\scripts\1cBackup\BAK\Через_выгрузку\Reapir_1C_backup_test\mail_send_script\send_log_ZUP.bat"

rem pause