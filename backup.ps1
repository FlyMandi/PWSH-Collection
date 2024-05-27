# example usage: backup -f "C:\Important Files\" -t "D:\Backup Folder\"
# OR simply "backup", it will take the defaults set here, $pwd is current directory
Param(
    [string]$f = $pwd,
    [string]$t = "T:\AutoBackup_MDrive\"
)
# path error handling
If ((-Not (Test-Path $f))) {
    Throw "The source directory $f does not exist, please provide a valid path."
} ElseIf (-Not (Test-Path $t)){
    Throw "The destination directory $t does not exist, please provide a valid path."
}

# # path to your installed rar.exe (NOT WinRAR.exe), default:
# $rar = "C:\Program Files\WinRAR\Rar.exe"

# setting 7zip path
$7zipPath = "$env:USERPROFILE\scoop\apps\7zip\24.06\7z.exe"
Set-Alias Start-SevenZip $7zipPath

if (-not (Test-Path -Path $7zipPath -PathType Leaf)) {
    throw "7 zip file '$7zipPath' not found"
}

$date = Get-Date -format "yy-MM-dd"

$leafName = Split-Path -Path $f -Leaf
$archiveName = "$leafName`_backup-$date.7z"

# making sure there's only 1 `\`
$archive_full = Join-Path -Path $t -ChildPath $archiveName

# # run rar.exe "a -u" (add/update) "-y" (presume yes) "-m5" (highest compression) "-t" (test after finishing)
# &$rar a -u -y -m5 -t $archive_full $f

# run 7zip
&$7zipPath u -mx=9 $archive_full $f
&$7zipPath t $archive_full