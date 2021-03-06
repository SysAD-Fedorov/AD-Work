#########################################
# V1.1
# 2014-12-04
# Author Artyom Nijazov aka Th0mson
#########################################
cls
# ---------------------------------------------------------------------
# Checking Execution Policy
# ---------------------------------------------------------------------
#$Policy = "Unrestricted"
$Policy = "RemoteSigned"
If ((get-ExecutionPolicy) -ne $Policy) {
  Write-Host "Script Execution is disabled. Enabling it now"
  Set-ExecutionPolicy $Policy -Force
  Write-Host "Please Re-Run this script in a new powershell enviroment"
  Write-Host '-----------------------------------'
  Exit
}
############################# Global Settings #############################
# --------------------------------------------------------------------
# Define the variables.
# --------------------------------------------------------------------
If (!($args[0] -eq $null)){
	$NameScript = $args[0]
}
Else{
	Write-Host 'Not input project name for updating'
	exit
}

If (!($args[1] -eq $null)){
	$ServerURL = $args[1]
}
Else{
	Write-Host 'Not input URL of server'
	exit
}

If (!($args[2] -eq $null)){
	$FileNameScript = $args[2]
}

$Exclude = @("Install_$NameScript.ps1", "config.xml")

#-------------- Parsing XML Config -----------------
$ConfigFile = New-Object System.Xml.XmlDocument
$ConfigFile.Load("$ServerUrl/config.xml")
$PathScripts = $ConfigFile.Root.PathScripts
$TempPath = "$PathScripts\Temp"
$VerWeb = ($ConfigFile.Root.Scripts_List.SelectNodes("*") | 
where {$_.title -ieq "$NameScript"}).Version
$OldProjectConfigFile = New-Object System.Xml.XmlDocument
$OldProjectConfigFile.Load("$PathScripts\$NameScript\config.xml")
$VerLoc = $OldProjectConfigFile.root.Version
If ($([float]$VerLoc) -lt $([float]$VerWeb)) {
	$OldProjectConfigFile.root.Version = $VerWeb
}
Else {
	Write-Host 'Update not required'
	break
}
$OldProjectConfigFile.Save("$PathScripts\$NameScript\config.xml")
#---------------------------------------------------
############################# End Settings ################################

################ Function for Downloading Arhive of Script ################
Function DownLoadScript($ScriptName, $Url, $Path){
	$FullURL="$Url/$ScriptName"
	$ListScriptsURL = $FullURL + '/list.xml'
	#------- Create Variable for XML Config ------------
	$ListScriptsFile = New-Object System.Xml.XmlDocument
	$ListScripts = @()
	#---------------------------------------------------
	
	If (!(test-path $Path)){
		Write-Host '------------------------------------------------------'
		Write-Host 'Create Temp Folder...'
		New-Item -ItemType directory -Path $Path
		Write-Host ''
	}
	
	$ScriptPath = "$Path\$ScriptName"
	
	If (!(test-path $ScriptPath)){
		Write-Host '------------------------------------------------------'
		Write-Host 'Create' $ScriptPath 'Folder...'
		New-Item -ItemType directory -Path $ScriptPath
		Write-Host ''
	}

	$UrlIsValid = $false
	try{
    	$HTTP_Request = [System.Net.WebRequest]::Create($ListScriptsURL)
    	$HTTP_Request.Method = 'HEAD'
    	$HTTP_Response = $HTTP_Request.GetResponse()
    	$HTTP_Status = $HTTP_Response.StatusCode
    	$urlIsValid = ($HTTP_Status -eq 'OK')
    	$tryError = $null
    	$HTTP_Response.Close()
	}
	catch [System.Exception] {
    	$HTTP_Status = $null
    	$tryError = $_.Exception
    	$UrlIsValid = $false;
	}
	If ($UrlIsValid) {
		#-------------- Parsing XML Config -----------------
		$ListScriptsFile.Load("$FullURL/list.xml")
		$ListScripts += $ListScriptsFile.Root.ListScripts | 
		Select-Object -ExpandProperty List | 
		foreach {$_.title}
		#---------------------------------------------------
		
		Write-Host '------------------------------------------------------'
    	Write-Host "Script Downloading..."
		$WebClient = New-Object System.Net.WebClient
		#----------- Downloading files ---------------
		foreach ($ScriptFile in $ListScripts) {
			$ListScriptsFileURL = $FullURL + '/' + $ScriptFile
			$ScriptFilePath = $ScriptPath + '\' + $ScriptFile
			$tmpvar = [regex]::Unescape([Regex]::Matches($ScriptFilePath,'.*?(?=[\\\/])')-join'\')
			If (!(test-path $tmpvar)){
				New-Item -ItemType directory -Path $tmpvar
			}
			$WebClient.DownloadFile($ListScriptsFileURL,$ScriptFilePath)		
		}
		#---------------------------------------------
		$i = 0
		foreach ($ScriptFile in $ListScripts) {
			$ScriptFilePath = $ScriptPath + '\' + $ScriptFile
			If (test-path $ScriptFilePath){
				$i++
			}
		}
		If ($i -lt $ListScripts.Length) { 
			Write-Host "Script Not Downloading! Cheking it" -ForegroundColor Red
			$Global:PathArhScript=$Null
		}

		Else {
			Write-Host "Script Download Complete"
			$Global:PathArhScript=$ScriptPath
		}
	}
	Else {
		Write-Host '------------------------------------------------------'
    	Write-Host "The Site or Script is not Response, please check!" -ForegroundColor Red
		$Global:PathArhScript=$Null
	}
	sleep 2
}
###########################################################################

################################# Begin ###################################
DownLoadScript $NameScript $ServerURL $TempPath
Write-Host '------------------------------------------------------'
If ($PathArhScript -ne $null){
	If (!(test-path "$PathScripts\$NameScript")){
		Write-Host "Create $PathScripts\$NameScript Folder..."
		Write-Host '-----------------------------------'
		New-Item -ItemType directory -Path "$PathScripts\$NameScript"
		Write-Host '---------'
	}
	Get-Childitem $TempPath\$NameScript -Recurse -Exclude $Exclude |
	Copy-Item -Destination "$PathScripts\$NameScript\" -Force 
	Write-Host "Updateing $ProjectName from $ServerURL done"
}
Write-Host 'Starting script' $FileNameScript
If (!($FileNameScript -eq $null)){
	Start-Process powershell.exe "-ExecutionPolicy RemoteSigned `
			$PathScripts\$NameScript\$FileNameScript"
}
Get-ChildItem $TempPath -Recurse | Remove-Item –Recurse
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
sleep 2
################################## End ####################################
