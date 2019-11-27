$DomainController = 'dchetznera.hq.fix.ru'

$LastName = Read-Host '������ ������� ������������'

$FirstName = Read-Host '������ ��� ������������'

function TranslitRu2Lat ([String] $text) {

    $translitTable = @{ 
        [char]'�' = "a";
        [char]'�' = "b";
        [char]'�' = "v";
        [char]'�' = "g";
        [char]'�' = "d";
        [char]'�' = "e";
        [char]'�' = "e";
        [char]'�' = "zh";
        [char]'�' = "z";
        [char]'�' = "i";
        [char]'�' = "y";
        [char]'�' = "k";
        [char]'�' = "l";
        [char]'�' = "m";
        [char]'�' = "n";
        [char]'�' = "o";
        [char]'�' = "p";
        [char]'�' = "r";
        [char]'�' = "s";
        [char]'�' = "t";
        [char]'�' = "u";
        [char]'�' = "f";
        [char]'�' = "kh";
        [char]'�' = "ts";
        [char]'�' = "ch";
        [char]'�' = "sh";
        [char]'�' = "sch";
        [char]'�' = "";
        [char]'�' = "y";
        [char]'�' = "";
        [char]'�' = "e";
        [char]'�' = "u";
        [char]'�' = "ya";
    }

    # ����� � ������ �������
    $text = $text.ToLower()

    $result = ""

    foreach ($c in $text.ToCharArray()) {
        if ($translitTable[$c] -cne $null ) {
            $result += $translitTable[$c]
        }
        else {
            $result += $c
        }
    }

    return [String] $result
}

$LastName = TranslitRu2Lat $LastName

$FirstName = TranslitRu2Lat $FirstName

$SAM = $FirstName[0].ToString().ToLower() + $LastName.ToLower() + '*'

(Get-ADUser -filter *).SamAccountName -like $SAM