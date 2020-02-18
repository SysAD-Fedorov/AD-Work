@echo off

net use p: \\192.168.135.9\backupbuh /PERSISTENT:YESecho Start backup %date% %time%

@set datetemp=%date:~-10%


TASKKILL /F /IM "1cv8.exe"


"C:\Program Files (x86)\1cv8\8.3.5.1248\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\1C_Bases\BP" /N backup /P y9GNUL51GSry /DisableStartupMessages /DumpIB C:\backup\BP\BP_%datetemp%.dt /Out "C:\Backup\1c8_BP_Log.txt" -NoTruncate

copy C:\backup\BP\BP_%datetemp%.dt p:\BP
forfiles /p c:\backup\BP /m *.* /s /c "cmd /c del /q /f @file" /d -60
forfiles /p p:\BP /m *.* /s /c "cmd /c del /q /f @file" /d -30


TASKKILL /F /IM "1cv8.exe"

"C:\Program Files (x86)\1cv8\8.3.4.408\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\1C_Bases\Trade" /N backup /P y9GNUL51GSry /DisableStartupMessages /DumpIB C:\backup\UT\UT_%datetemp%.dt /Out "C:\Backup\1c8_UT_Log.txt" -NoTruncate

copy C:\backup\UT\UT_%datetemp%.dt p:\UT
forfiles /p c:\backup\ut /m *.* /s /c "cmd /c del /q /f @file" /d -60
forfiles /p p:\UT /m *.* /s /c "cmd /c del /q /f @file" /d -30

rem "C:\Program Files (x86)\1cv8\8.3.5.1248\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\1C_Bases\BP" /N backup /P y9GNUL51GSry /ЗавершитьРаботуПользователей /Out C:\Backup\1c8_BP_Log.txt /DisableStartupMessages
rem start C:\scripts\ConnectionOff1C82.vbs


TASKKILL /F /IM "1cv8.exe"


"C:\Program Files (x86)\1cv8\8.3.4.408\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\1C_Bases\HRM" /N backup /P y9GNUL51GSry /DisableStartupMessages /DumpIB C:\backup\ZUP\ZUP_%datetemp%.dt /Out "C:\Backup\1c8_BP_Log.txt" -NoTruncate

copy C:\backup\ZUP\ZUP_%datetemp%.dt p:\BP
forfiles /p c:\backup\BP /m *.* /s /c "cmd /c del /q /f @file" /d -60
forfiles /p p:\BP /m *.* /s /c "cmd /c del /q /f @file" /d -30


call "C:\scripts\1cBackup\BAK\Через_выгрузку\checkBackup1C.bat"
rem pause