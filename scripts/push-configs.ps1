if (Test-Path "T:\Repository\dotfiles\"){
	$RepoPath = "T:\Repository\dotfiles\"
}
elseIf (Test-Path "C:\Repository\dotfiles\"){
	$RepoPath = "C:\Repository\dotfiles\"
}
else{
	throw "No valid Repository\dotfiles\ path found."
}

$WinVimpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\nvim\"
$RepoVimpath = Join-Path -PATH $RepoPath -ChildPath "\nvim\"

$WinGlazepath = Join-Path -PATH $env:USERPROFILE -ChildPath "\.glzr\glazewm\config.yaml"
$RepoGlazepath = Join-Path -PATH $RepoPath -ChildPath "\glazewm\config.yaml"

$WinTermpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$WinTermPreviewPath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft\Windows.TerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"

$RepoTermpath = Join-Path -PATH $RepoPath -ChildPath "\wt\settings.json"
$RepoPSpath = Join-Path -PATH $RepoPath -ChildPath "\PowerShell\Microsoft.PowerShell_profile.ps1"


function Push-Config
{
    param (
        $inputPath,
        $outputPath
    )

    if (-Not(Test-Path $inputPath))
    {
        throw "$inputPath is not a valid repo path to copy from."
    }

    if ( Test-Path $outputPath )
    {
        Remove-Item -PATH $outputPath -Recurse
        Write-Host "Deleted existing config in $outputPath." 
    } else
    {
        Write-Host "No existing config found in $outputPath, pushing..."
    }
    Copy-Item -PATH $inputPath -Destination $outputPath -Recurse
    Write-Host "Config push successful.`n" -ForegroundColor Green -NoNewline
}

Push-Config $RepoVimpath $WinVimpath
Push-Config $RepoGlazepath $WinGlazepath
if (Test-Path $WinTermpath){
	Push-Config $RepoTermpath $WinTermpath
}
if (Test-Path $WinTermPreviewPath){
	Push-Config $RepoTermpath $WinTermPreviewPath
}

if (Test-Path $PROFILE){
    Push-Config $RepoPSpath $PROFILE 
}
elseIf(Test-Path "$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1"){
    Push-Config $RepoPSpath "$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1"
}
