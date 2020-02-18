@echo
set datetemp=%date:~-10%

dir find "C:\backup\BP\BP_%datetemp%.dt" ||  call "C:\scripts\1cBackup\BAK\Через_выгрузку\emailsendBP.bat"
dir find "C:\backup\ZUP\ZUP_%datetemp%.dt" ||  call "C:\scripts\1cBackup\BAK\Через_выгрузку\emailsendZUP.bat"
dir find "C:\backup\UT\UT_%datetemp%.dt" ||  call "C:\scripts\1cBackup\BAK\Через_выгрузку\emailsendUT.bat"
pause