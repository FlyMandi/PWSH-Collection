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

$WinGlazepath = Join-Path -PATH $env:USERPROFILE -ChildPath "\.glzr\glazewm\"
$RepoGlazepath = Join-Path -PATH $dotfiles -ChildPath "\glazewm\"

#FIXME: this .json isn't the only file to copy, it doesn't include:
# keybinds
# general term profile
# default profile settings
# font & appearance settings

#$WinTermpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
#$WinTermPreviewPath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft\Windows.TerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
#$RepoTermpath = Join-Path -PATH $dotfiles -ChildPath "\wt\settings.json"

$RepoPSpath = Join-Path -PATH $dotfiles -ChildPath "\PowerShell\"

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
    else{
        Write-Host "$command already installed, continuing..."
    }
}

function Push-ChangedFiles{
    param(
        $folder1,
        $folder2
    )

#FIXME: Cannot bind argument to parameter 'DifferenceObject' because it is null.
    $missingFiles = Compare-Object -ReferenceObject (Get-ChildItem -Path $folder1 -File) -DifferenceObject (Get-ChildItem -Path $folder2 -File) | Where-Object { $_.SideIndicator -eq '<=' }
    $filesToReplace = Compare-Object -ReferenceObject (Get-ChildItem -Path $folder1 -File) -DifferenceObject (Get-ChildItem -Path $folder2 -File) | Where-Object { $_.SideIndicator -eq '=>' }
    
    foreach ($file in $missingFiles) {
        $fileName = $file.InputObject.BaseName
	$fileNameWithExtension = $fileName + $file.InputObject.Extension
        Write-Host "file name: $fileNameWithExtension"
        Copy-Item -Path (Join-Path -PATH $folder1 -ChildPath $fileNameWithExtension) -Destination (Join-Path -PATH $folder2 -ChildPath $fileNameWithExtension)
    } 

#FIXME:
    foreach($file in $filesToReplace){
        Remove-Item "$($file.InputObject)"
        Copy-Item -Path "$folder1\$($file.InputObject)" -Destination "$folder2\$($file.InputObject)"
    }
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

    if (-Not(Test-Path $outputPath) || (Get-ChildItem $outputPath -Force -File | Measure-Object).count -eq 0){
        Write-Host "`nNo existing config found in $outputPath, pushing..."
	Copy-Item $inputPath $outputPath -Recurse
    }
    else{
        Write-Host "`nExisting config found in $outputPath, updating..."
    	Push-ChangedFiles $inputPath $outputPath
    }

    Write-Host "Config push successful.`n" -ForegroundColor Green -NoNewline
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

#FIXME: finish implementing file change detection
Push-Certain $RepoVimpath $WinVimpath
Push-Certain $RepoGlazepath $WinGlazepath
Push-Certain $RepoPSpath "$PROFILE.."

#FIXME: for some reason Windows Terminal doesn't want to play nice with the paths.
#Push-Certain $RepoTermpath $WinTermpath
#Push-Certain $RepoTermpath $WinTermPreviewPath

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "`nEnvironment variables refreshed."
Write-Host "All configs are now up to date! ^^" -ForegroundColor Cyan 
