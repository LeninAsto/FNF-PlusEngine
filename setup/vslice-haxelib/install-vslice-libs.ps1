$ErrorActionPreference = "Stop"

function Install-HaxelibGit($Name, $Url, $Ref, $SubDir = $null) {
	Write-Host "Installing $Name from $Url#$Ref"
	if ($SubDir) {
		haxelib git $Name $Url $Ref $SubDir
	} else {
		haxelib git $Name $Url $Ref
	}
}

function Install-HaxelibRelease($Name, $Version) {
	Write-Host "Installing $Name $Version"
	haxelib install $Name $Version --quiet
}

Install-HaxelibGit "json2object" "https://github.com/FunkinCrew/json2object" "59e0467c953d1f26e3cbf2a070f140e2d2e8457d"
Install-HaxelibRelease "jsonpatch" "1.1.0"
Install-HaxelibRelease "jsonpath" "1.1.0"
Install-HaxelibGit "thx.core" "https://github.com/fponticelli/thx.core" "2bf2b992e06159510f595554e6b952e47922f128"
Install-HaxelibGit "thx.semver" "https://github.com/fponticelli/thx.semver" "bdb191fe7cf745c02a980749906dbf22719e200b"
Install-HaxelibGit "flixel-animate" "https://github.com/Psych-Plus-Team/flixel-animate" "main"
Install-HaxelibGit "FlxPartialSound" "https://github.com/FunkinCrew/FlxPartialSound.git" "2f984e244f1544ca98c0e03b9b21ae570f07ac55"
Install-HaxelibGit "hxjsonast" "https://github.com/nadako/hxjsonast/" "20e72cc68c823496359775ac1f06500e67f189d5"
Install-HaxelibGit "polymod" "https://github.com/Psych-Plus-Team/polymod" "master"

Write-Host "VSlice runtime haxelibs are ready."
