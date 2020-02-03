$Servers = '?????? 1' , 'Server2' , 'Server3'
$Username = Read-Host '?????? ??? ????????????'
Foreach ($server in $Servers) {
    Get-ChildItem "\\$Server\c$\Users\$Username\AppData\Local\1C\1cv82\*" , "\\$server\D:\UserProfiles\$Username.v2\AppData\Roaming\1C\1Cv82*" | Where { $_.Name -as [guid] } <#| Remove-Item -Force -Recurse #> }
