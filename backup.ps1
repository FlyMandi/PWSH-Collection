# example usage: rarBackup -f "C:\Important Files\" -t "D:\Backup Folder\"
# -f is to be understood as  "from" and -t as "to"
Param(
    [string]$f,
    [string]$t
)

# path to your installed rar.exe (NOT WinRAR.exe), default:
$rar = "C:\Program Files\WinRAR\Rar.exe"

$date = Get-Date -format "yy-MM-dd"
$leafName = Split-Path -Path $f -Leaf
$archiveName = "$leafName`_backup-$date.rar"
$archive_full = "$t\$archiveName"

# run rar.exe "a -u" (add/update) "-y" (presume yes) "-m5" (highest compression) "-t" (test after finishing)
&$rar a -u -y -m5 -t $archive_full $f