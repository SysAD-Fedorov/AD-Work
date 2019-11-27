$DomainController = 'dchetznera.hq.fix.ru'

$LastName = Read-Host 'Ведите Фамилию пользователя'

$FirstName = Read-Host 'Ведите Имя пользователя'

function TranslitRu2Lat ([String] $text) {

    $translitTable = @{ 
        [char]'а' = "a";
        [char]'б' = "b";
        [char]'в' = "v";
        [char]'г' = "g";
        [char]'д' = "d";
        [char]'е' = "e";
        [char]'ё' = "e";
        [char]'ж' = "zh";
        [char]'з' = "z";
        [char]'и' = "i";
        [char]'й' = "y";
        [char]'к' = "k";
        [char]'л' = "l";
        [char]'м' = "m";
        [char]'н' = "n";
        [char]'о' = "o";
        [char]'п' = "p";
        [char]'р' = "r";
        [char]'с' = "s";
        [char]'т' = "t";
        [char]'у' = "u";
        [char]'ф' = "f";
        [char]'х' = "kh";
        [char]'ц' = "ts";
        [char]'ч' = "ch";
        [char]'ш' = "sh";
        [char]'щ' = "sch";
        [char]'ъ' = "";
        [char]'ы' = "y";
        [char]'ь' = "";
        [char]'э' = "e";
        [char]'ю' = "u";
        [char]'я' = "ya";
    }

    # текст в нижний регистр
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