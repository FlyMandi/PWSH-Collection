if(-Not (Test-Path $repo)){
    Write-Host "Set \Repository\ location for first execution of this script:" -ForegroundColor Red 
    $repo = Read-Host
}

$dotfiles = Join-Path -Path $repo -ChildPath "\dotfiles\"
if (-Not(Test-Path $dotfiles)){ 
    Write-Host "No valid directory \dotfiles\ in $repo."
    &git clone "https://github.com/FlyMandi/dotfiles" $dotfiles 
    Write-Host "Cloned FlyMandi/dotfiles repo successfully!" -ForegroundColor Green
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

[int]$global:filesAdded = 0
[int]$global:filesUpdated = 0

function Get-filesAdded{
    if (-Not($global:filesAdded -eq 0)){Write-Host "Files Added: $global:filesAdded" -ForegroundColor Cyan}
    $global:filesAdded = 0
}

function Get-filesUpdated{
    if(-Not($global:filesUpdated -eq 0)){Write-Host "Files Updated: $global:filesUpdated" -ForegroundColor Magenta}
    $global:filesUpdated = 0
}

$scoopDir = Join-Path $env:USERPROFILE -ChildPath "\scoop\apps\"

$WinVimpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\nvim\"
$RepoVimpath = Join-Path -PATH $dotfiles -ChildPath "\nvim\"

$WinGlazepath = Join-Path -PATH $env:USERPROFILE -ChildPath "\.glzr\glazewm\"
$RepoGlazepath = Join-Path -PATH $dotfiles -ChildPath "\glazewm\"

$WinPSPath = Join-Path -PATH $env:USERPROFILE -ChildPath "\Documents\PowerShell\" 
$RepoPSpath = Join-Path -PATH $dotfiles -ChildPath "\PowerShell\"

#FIXME: this .json isn't the only file to copy, it doesn't include:
# keybinds
# general term profile
# default profile settings
# font & appearance settings

#$WinTermpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
#$WinTermPreviewPath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft\Windows.TerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
#$RepoTermpath = Join-Path -PATH $dotfiles -ChildPath "\wt\settings.json"

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
        $binFolder = (Join-Path -PATH $repoNameFolder -ChildPath "\bin")
        Expand-Archive -Path $tempZIP -DestinationPath $repoNameFolder -Force
        Remove-Item $tempZIP -Force

        $zipFolder = Join-Path -PATH $repoNameFolder -ChildPath ([io.path]::GetFileNameWithoutExtension($zipFolderName))
        if (Test-Path $zipFolder){
            Move-Item "$zipFolder\*.*" -Destination $repoNameFolder -Force
            Remove-Item $zipFolder -Recurse -Force
        }

        if ((Test-Path "$binFolder") -And -Not([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) -like "*$binFolder*")){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$binFolder",[EnvironmentVariableTarget]::User)       
            Write-Host "Added $binFolder to path!" -ForegroundColor Green
        }
        elseIf(-Not([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) -like "*$repoNameFolder*")){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$repoNameFolder",[EnvironmentVariableTarget]::User)       
            Write-Host "Added $repoNameFolder to path!" -ForegroundColor Green
        }

        Write-Host "$command successfully installed!" -ForegroundColor Green
    }
    else{
        Write-Host "$command already installed, continuing..."
    }
}

function Push-ChangedFiles{
    param(
        $sourceFolder,
        $destFolder
    )

    $sourceFileList = Get-ChildItem $sourceFolder -Recurse -File
    $destFileList = Get-ChildItem $destFolder -Recurse -File

    if($null -eq $sourceFileList){
        throw "ERROR: No files to copy from."
    }
    elseIf($null -eq $destFileList){
        throw "ERROR: no files to compare against."
    }
    else{
        $sourceTransformed = @()
        $destTransformed = @()

        foreach($file in $sourceFileList){
            $sourceTransformed += ([string]$file).Substring($sourceFolder.Length)
        }

        foreach($file in $destFileList){
            $destTransformed += ([string]$file).Substring($destFolder.Length)
        }

        $missingFiles = Compare-Object $sourceTransformed $destTransformed | Where-Object {$_.sideindicator -eq "<="}
    }

    foreach($file in $missingFiles){
        $fileInSource = (Join-Path -PATH $sourceFolder -ChildPath $file.InputObject)
        $fileInDest = (Join-Path -PATH $destFolder -ChildPath $file.InputObject)

        if (-Not(Test-Path (Split-Path $fileInDest))){&mkdir (Split-Path $fileInDest)}
        Copy-Item -Path $fileInSource -Destination $fileInDest
        Write-Host "Added Item: " -NoNewline
        Write-Host $file.InputObject -ForegroundColor Cyan
        $global:filesAdded += 1
    }
    
    foreach($file in $sourceTransformed){
        $fileInSource = (Join-Path -PATH $sourceFolder -ChildPath $file)
        $fileInDest = (Join-Path -PATH $destFolder -ChildPath $file)

        if(-Not((Get-FileHash $fileInSource).Hash -eq (Get-FileHash $fileInDest).Hash)){ 
            Remove-Item $fileInDest -Force
            Copy-Item $fileInSource -Destination $fileInDest
            Write-Host "Updated Item: " -NoNewline
            Write-Host $file -ForegroundColor Magenta
            $global:filesUpdated += 1
        }
    }

}

function Push-Certain{
    param (
        $inputPath,
        $outputPath
    )

    if (-Not(Test-Path $inputPath)){
        Write-Host "Could not write config from " -NoNewline -ForegroundColor Red
        Write-Host $inputPath -BackgroundColor DarkGray
        throw "Not a valid path to copy config from."
    }

    if (-Not(Test-Path $outputPath) -Or $null -eq (Get-ChildItem $outputPath -File -Recurse)){
        Write-Host "`nNo existing config found in $outputPath, pushing..."
	    Copy-Item $inputPath $outputPath -Recurse
        $global:filesAdded += (Get-ChildItem $outputPath -File -Recurse).count
    }
    else{
        Write-Host "`nExisting config found in $outputPath, updating..."
    	Push-ChangedFiles $inputPath $outputPath
    }
        Write-Host "Update Complete. "
        if(($global:filesAdded -eq 0) -And ($global:filesUpdated -eq 0)){Write-Host "No files changed."}
}

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

Push-Certain $RepoVimpath $WinVimpath
Push-Certain $RepoGlazepath $WinGlazepath
Push-Certain $RepoPSpath $WinPSPath

#FIXME: for some reason Windows Terminal doesn't want to play nice with the paths.
#Push-Certain $RepoTermpath $WinTermpath
#Push-Certain $RepoTermpath $WinTermPreviewPath

$temp = $env:Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
if (-Not($temp.Length) -eq ($env:Path.Length)){Write-Host "`nEnvironment variables updated!" -ForegroundColor Green}

if(-Not($global:filesAdded -eq 0) -Or -Not($global:filesUpdated -eq 0)){Write-Host "`nTotal:" -ForegroundColor Green}
Get-filesAdded
Get-filesUpdated
Write-Host "`nAll configs are now up to date! ^^" -ForegroundColor Green
