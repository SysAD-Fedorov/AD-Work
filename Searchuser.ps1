$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = "LDAP://OU=Users,OU=P16,OU=TOGS,DC=rosstat,DC=local"
#$objSearcher.Filter = "(&(objectCategory=person)(!userAccountControl:1.2.840.113556.1.4.803:=2))"
$users = $objSearcher.FindAll()
# Количество учетных записей
$users.Count 
$users | ForEach-Object {
   $user = $_.Properties
   New-Object PsObject -Property @{
	samaccountname = [string]$user.samaccountname
	displayname = [string]$user.displayname 
	sn = [string]$user.sn
	givenname = [string]$user.givenname
	initials = [string]$user.initials
	userprincipalname = [string]$user.userprincipalname
	description = [string]$user.description
	telephonenumber = [string]$user.telephonenumber
	mail = [string]$user.mail
	ipphone = [string]$user.ipphone
	physicaldeliveryofficename = [string]$user.physicaldeliveryofficename
	department = [string]$user.department
	extensionattribute10 = [string]$user.extensionattribute10
    extensionattribute11 = [string]$user.extensionattribute11
    extensionattribute12 = [string]$user.extensionattribute12
	title = [string]$user.title
	manager = [string]$user.manager
	company = [string]$user.company
	co = [string]$user.co
	c = [string]$user.c
	st = [string]$user.st
	l = [string]$user.l
	streetaddress = [string]$user.streetaddress
	extensionattribute1 = [string]$user.extensionattribute1
	extensionattribute2 = [string]$user.extensionattribute2
	extensionattribute3 = [string]$user.extensionattribute3
    
   }
} | Export-Csv -Delimiter ";" -Encoding utf8 -Path  "d:\_Работа\AD\Add+Change+search\All.csv"