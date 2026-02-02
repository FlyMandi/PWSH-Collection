$RepoPath = "T:\Repository\dotfiles"

$WinVimpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\nvim\"
$RepoVimpath = Join-Path -PATH $RepoPath -ChildPath "\nvim\"

$WinGlazepath = Join-Path -PATH $env:USERPROFILE -ChildPath "\.glzr\glazewm\config.yaml"
$RepoGlazepath = Join-Path -PATH $RepoPath -ChildPath "\glazewm\config.yaml"

$WinTermpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$RepoTermpath = Join-Path -PATH $RepoPath -ChildPath "\wt\settings.json"
$RepoPSpath = Join-Path -PATH $RepoPath -ChildPath "PowerShell\Microsoft.PowerShell_profile.ps1"


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
Push-Config $RepoTermpath $WinTermpath
Push-Config $RepoPSpath $PROFILE
