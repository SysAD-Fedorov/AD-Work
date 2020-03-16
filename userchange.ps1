$users = Import-Csv "d:\_Работа\AD\Add+Change+search\All_.csv" -Delimiter ";"
$props = $users | Get-Member -MemberType NoteProperty | Select -Expand name

foreach ($user in $users)
{
	Try{
	      $objuser = ([adsisearcher]"(userPrincipalName=$($user.userPrincipalName))").FindOne().GetDirectoryEntry()
	}
	
	Catch {
		continue
	}
    
	$log = New-Object Text.StringBuilder
	
	$props | Foreach {
            $prop = $_.ToLower()
            $oldprop = $objuser.InvokeGet($prop)
			if ($user.$prop -eq "")
			{
				$objuser.PutEx(1, $prop, 0)
                $text = "{0} : old {1} new {2} prop {3} - {4}" -f $objuser.name[0],$oldprop,"не задано",$prop,(Get-Date)
                $log.AppendLine($text) | Out-Null

			} elseif ($user.$prop -cne $oldprop)
			{
				$objuser.Put("$prop",$user.$prop)
                $text = "{0} : old {1} new {2} prop {3} - {4}" -f $objuser.name[0],$oldprop,$user.$prop,$prop,(Get-Date)
                $log.AppendLine($text) | Out-Null
            }
      }
    
	Try {
       $objuser.SetInfo()
	   if($log.ToString())
	   {
	   		$log.ToString() | Out-File "d:\_Работа\AD\Add+Change+search\All_.txt" -Append
	   }
    }
    Catch {
        $_
    }
}