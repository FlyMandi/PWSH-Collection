if(-Not (Test-Path $repo)){
    Write-Host "Set `$repo for first execution of this script:"    
    $repo = Read-Host
}

$dotfiles = Join-Path -Path $repo -ChildPath "\dotfiles\"
if (-Not(Test-Path $dotfiles)){ 
    Write-Host "No valid directory \dotfiles\ in $repo."
    &git clone "https://github.com/FlyMandi/dotfiles" (Join-Path -PATH $repo -ChildPath "\dotfiles\")
}

if (-Not (Get-Command winget -ErrorAction SilentlyContinue)){
    Invoke-RestMethod "https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1" | Invoke-Expression | Out-Null
}
if (-Not (Get-Command scoop -ErrorAction SilentlyContinue)){ 
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression

    &scoop bucket add "extras"
    &scoop bucket add "nerd-fonts" 
    &scoop bucket add "sysinternals"
}

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

#TODO: turn function arguments into references whereever possible

Function Get-Package { 
    Param(
        $pkgmgr,
        $trgt,
        $override = "default"
    )
    if (-Not (Get-Command $trgt -ErrorAction SilentlyContinue)){
        if (-Not ($override -eq "default")) { $trgt = $override }
        &$pkgmgr install $trgt
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
    }
    else{
        Write-Host "$scoopTrgt already installed, continuing..."
    }
}

function Get-Binary {
    Param(
        $command,
        $sourceRepo,
        $namePattern,
        [switch]$preRelease = $false
    )
    if (-Not(Get-Command $command -ErrorAction SilentlyContinue)){
        $libFolder = Join-Path -PATH $repo -ChildPath "/lib/"
        
        if ($preRelease){
            Write-Host "Installing latest $namePattern release package from $sourceRepo..."
            $sourceURI = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/$sourceRepo/releases")[0].assets | Where-Object name -like $namePattern).browser_download_url
        }
        else{
            Write-Host "Installing latest $namePattern pre-release package from $sourceRepo..."
            $sourceURI = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/$sourceRepo/releases/latest").assets | Where-Object name -like $namePattern).browser_download_url
        }
        $zipFolderName = $(Split-Path -Path $sourceURI -Leaf)
        $tempZIP = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $zipFolderName 
        Invoke-WebRequest -Uri $sourceURI -Out $tempZIP
    
        $repoNameFolder = (Join-Path -PATH $libFolder -ChildPath $SourceRepo) 
        $binFolder = (Join-Path -PATH $repoNameFolder -ChildPath "\bin\")
        Expand-Archive -Path $tempZIP -DestinationPath $repoNameFolder -Force
        Remove-Item $tempZIP -Force

        $zipFolder = Join-Path -PATH $repoNameFolder -ChildPath ([io.path]::GetFileNameWithoutExtension($zipFolderName))
        if (Test-Path $zipFolder){
            Move-Item "$zipFolder\*.*" -Destination $repoNameFolder -Force
            Remove-Item $zipFolder -Recurse -Force
        }

        if (Test-Path "$binFolder"){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$binFolder",[EnvironmentVariableTarget]::User)       
        }
        else{
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$repoNameFolder",[EnvironmentVariableTarget]::User)       
        }

        Write-Host "$command successfully installed and added to path!" -ForegroundColor Green
    }
    #TODO: change this to elseIf(there's no new release available)
    else{
        Write-Host "$command already installed, continuing..."
    }
    #else{
    #TODO: remove all old files (folder and shortcut) and call function recursively
    #
    #    if (Test-Path $repoNameFolder){
    #        Remove-Item "$repoNameFolder\.." -Recurse -Force
    #   }
    #} 
}

function Get-FileChange{
    param(
        $file1,
        $file2
    )
    #TODO:
    #if file 1 identical to file 2
        #return true
    #else false
}

function Remove-OnFileChange{
    param(
        $inputPath,
        $outputPath
    )
   
   #TODO: for (every child item in file folder and its counterpart){
        if (Get-FileChange $file1 $file2){
            Remove-Item -PATH $outputPath -Recurse
        }
    #}
}

function Push-Certain
{
    param (
        $inputPath,
        $outputPath
    )

    if (-Not(Test-Path $inputPath)){
        Write-Host "Could not write config from " -NoNewline -ForegroundColor Red
        Write-Host $inputPath -BackgroundColor DarkGray
        throw "Not a valid path to copy config from."
    }

    if (Test-Path $outputPath){
        Write-Host "`nExisting config found in $outputPath, updating..."
        Remove-OnFileChange $inputPath $outputPath
    }
    else{
        Write-Host "`nNo existing config found in $outputPath, pushing..."
    }

    Copy-Item -PATH $inputPath -Destination $outputPath -Recurse
    Write-Host "Config push successful.`n" -ForegroundColor Green -NoNewline
}

#FIXME: Out-Null not working at all here

&scoop cleanup --all 6>$null
Get-Package scoop '7z' -o '7zip'
Get-Package scoop 'everything'
Get-Package scoop 'innounp'
Get-Package scoop 'lazygit'
Get-Package scoop 'neofetch'
Get-Package scoop 'nvim' -o 'neovim'
Get-Package scoop 'ninja'
Get-Package scoop 'npm' -o 'nodejs'
Get-Package scoop 'rg' -o 'ripgrep'
Get-Package scoop 'spt' -o 'spotify-tui'
Get-Package scoop 'winfetch'
Get-Package scoop 'zoomit'

Get-ScoopPackage 'discord'
Get-ScoopPackage 'listary'
Get-ScoopPackage 'libreoffice'
Get-ScoopPackage 'spotify'
Get-ScoopPackage 'vcredist2022'

Get-Package winget 'git' -o 'git.git'
#TODO: automatically check & set github username and e-mail
#TODO: automatically set up ssh (take ssh key from github as input)
Get-Package winget 'glazewm' -o 'glzr-io.glazeWM'

Get-Binary glsl_analyzer "nolanderc/glsl_analyzer" -namePattern "*x86_64-windows.zip"
Get-Binary premake5 "premake/premake-core" -namePattern "*windows.zip" -preRelease
Get-Binary fd "sharkdp/fd" -namePattern "*x86_64-pc-windows-msvc.zip" 

#TODO: finish implementing file change detection
#Push-Certain $RepoVimpath $WinVimpath
#Push-Certain $RepoGlazepath $WinGlazepath
#Push-Certain $RepoPSpath $PROFILE

#FIXME: for some reason Windows Terminal doesn't want to play nice with the paths.
#Push-Certain $RepoTermpath $WinTermpath
#Push-Certain $RepoTermpath $WinTermPreviewPath

#TODO: reload environment variables without closing the console
Write-Host "`nAll configs are now up to date! ^^" -ForegroundColor Cyan 
