if (-Not (Get-Command winget -ErrorAction SilentlyContinue)){
    Invoke-RestMethod "https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1" | Invoke-Expression | Out-Null
}
if (-Not (Get-Command scoop -ErrorAction SilentlyContinue)){ 
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression

    &scoop bucket add extras
    &scoop bucket add nerd-fonts 
}

$dotfiles = Join-Path -Path $repo -ChildPath "\dotfiles\"
if (-Not (Test-Path $dotfiles)){ throw "No valid directory \dotfiles\ in $repo." }

$scoopDir = Join-Path $env:USERPROFILE -ChildPath "\scoop\apps\"

$WinVimpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\nvim\"
$RepoVimpath = Join-Path -PATH $dotfiles -ChildPath "\nvim\"

$WinGlazepath = Join-Path -PATH $env:USERPROFILE -ChildPath "\.glzr\glazewm\config.yaml"
$RepoGlazepath = Join-Path -PATH $dotfiles -ChildPath "\glazewm\config.yaml"

#FIXME: this .json isn't the only file to copy, it doesn't include:
# keybinds
# general term profile
# default profile settings
# font & appearance settings

#$WinTermpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
#$WinTermPreviewPath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft\Windows.TerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
#$RepoTermpath = Join-Path -PATH $dotfiles -ChildPath "\wt\settings.json"

$RepoPSpath = Join-Path -PATH $dotfiles -ChildPath "\PowerShell\Microsoft.PowerShell_profile.ps1"

Function Get-Package { 
    Param(
        $pkgmgr,
        $trgt,
        $override = "default"
    )
    if (-Not (Get-Command $trgt -ErrorAction SilentlyContinue)){
        if (-Not ($override -eq "default")) { $trgt = $override }
        &$pkgmgr install $trgt
        Write-Host "$trgt successfully installed!" -ForegroundColor Green
    }
    else{
        Write-Host "$trgt already installed, continuing..."
    }
}

Function Get-ScoopPackage {
    Param(
        $scoopTrgt
    )

    if (-Not (Test-Path (Join-Path -Path $scoopDir -ChildPath $scoopTrgt))) { 
        &scoop install $scoopTrgt
        Write-Host "$scoopTrgt successfully installed!" -ForegroundColor Green
    }
    else{
        Write-Host "$scoopTrgt already installed, continuing..."
    }
}

function Push-Config
{
    param (
        $inputPath,
        $outputPath
    )

    if (-Not(Test-Path $inputPath)){
        Write-Host "Could not write config from " -NoNewline -ForegroundColor Red
        Write-Host $inputPath -NoNewline -BackgroundColor DarkGray
        Write-Host " because it's not a valid path."
    }

    if (Test-Path $outputPath){
        Remove-Item -PATH $outputPath -Recurse
        Write-Host "Deleted existing config in $outputPath." 
    }
    else{
        Write-Host "No existing config found in $outputPath, pushing..."
    }

    Copy-Item -PATH $inputPath -Destination $outputPath -Recurse
    Write-Host "Config push successful.`n" -ForegroundColor Green -NoNewline
}

Get-Package scoop 7z -o 7zip
Get-Package scoop everything
Get-Package scoop innounp
Get-Package scoop lazygit
Get-Package scoop neofetch
Get-Package scoop nvim -o neovim
Get-Package scoop ninja
Get-Package scoop npm -o nodejs
Get-Package scoop winfetch

Get-Package winget git -o git.git
Get-Package winget glazewm -o glzr-io.glazeWM

Get-ScoopPackage listary
Get-ScoopPackage discord

Push-Config $RepoVimpath $WinVimpath
Push-Config $RepoGlazepath $WinGlazepath
#FIXME: for some reason Windows Terminal doesn't want to play nice with the paths.
#Push-Config $RepoTermpath $WinTermpath
#Push-Config $RepoTermpath $WinTermPreviewPath
Push-Config $RepoPSpath $PROFILE 

Write-Host "`nAll configs are now up to date! ^^" -ForegroundColor Cyan 
