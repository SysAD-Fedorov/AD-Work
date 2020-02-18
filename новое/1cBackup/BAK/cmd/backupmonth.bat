@echo off

net use p: \\192.168.135.9\backupbuh /PERSISTENT:YES
echo Start backup %date% %time%

@set datetemp=%date:~-10%

TASKKILL /F /IM "1cv8.exe"

"C:\Program Files (x86)\1cv82\8.2.19.76\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\1C_Bases\Trade" /N backup /P y9GNUL51GSry /DumpIB C:\backup\UT\UT_%datetemp%.dt /Out "C:\Backup\1c8_UT_Log.txt" -NoTruncate

copy C:\backup\UT\UT_%datetemp%.dt p:\month\UT

TASKKILL /F /IM "1cv8.exe"

"C:\Program Files (x86)\1cv82\8.2.19.76\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\1C_Bases\Accounting" /N backup /P y9GNUL51GSry /DumpIB C:\backup\BP\BP_%datetemp%.dt /Out "C:\Backup\1c8_BP_Log.txt" -NoTruncate

copy C:\backup\BP\BP_%datetemp%.dt p:\month\BP

TASKKILL /F /IM "1cv8.exe"

"C:\Program Files (x86)\1cv82\8.2.19.76\bin\1cv8.exe" DESIGNER /F "C:\1CBiT\1C_Bases\HRM" /N backup /P y9GNUL51GSry /DumpIB C:\backup\ZUP\XUP_%datetemp%.dt /Out "C:\Backup\1c8_ZUP_Log.txt" -NoTruncate

copy C:\backup\ZUP\ZUP_%datetemp%.dt p:\month\ZUP


#pause