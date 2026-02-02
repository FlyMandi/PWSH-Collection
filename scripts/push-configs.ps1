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

[int]$script:filesAdded = 0
[int]$script:filesUpdated = 0

function Get-FilesAdded{
    if (-Not($script:filesAdded -eq 0)){Write-Host "Files Added: $script:filesAdded" -ForegroundColor Cyan -BackgroundColor Black}
    $script:filesAdded = 0
}

function Get-FilesUpdated{
    if(-Not($script:filesUpdated -eq 0)){Write-Host "Files Updated: $script:filesUpdated" -ForegroundColor Magenta -BackgroundColor Black}
    $script:filesUpdated = 0
}

$PS1Home = (Join-Path $env:SYSTEMROOT "\System32\WindowsPowerShell\v1.0")
$PS7exe = (Join-Path $env:PROGRAMFILES "\PowerShell\7\pwsh.exe")

if(-Not(Test-Path $env:Repo)){
    Write-Host "\Repository\ folder location at: " -ForegroundColor Red -NoNewline
    Write-Host "`"$env:Repo`"" -ForegroundColor Yellow -NoNewline
    Write-Host " not found, do you want to set it as 'C:\Repository\'?" -ForegroundColor Red -NoNewline
    Write-Host "(y/n): " -NoNewline -ForegroundColor Yellow

    $answer = Read-Host
    if (($answer -eq "y") -Or ($answer -eq "yes")){ 
        [System.Environment]::SetEnvironmentVariable("Repo", "C:\Repository\", "User")
        $env:Repo = "C:\Repository\"
    }
    else{
        Write-Host "Please provide another Directory: " -ForegroundColor Yellow -NoNewline
        $InputRepo = Read-Host

        if (-Not(Test-Path $InputRepo)){
            throw "FATAL: Directory doesn't exist. Please create it or choose a valid Directory."
        }
        else{
            [System.Environment]::SetEnvironmentVariable("Repo", $InputRepo, "User")
            $env:Repo = $InputRepo
        }
    }
}

function Copy-IntoRepo{
    Param(
        $folderName
    )
    
    $folderPath = Join-Path $env:Repo $folderName
    if((-Not(Test-Path $folderPath)) -Or ((Get-ChildItem $folderPath -File).count -eq 0)){
        &git clone "https://github.com/FlyMandi/$folderName" $folderPath
        Write-Host "Cloned FlyMandi/$folderName repository successfully!" -ForegroundColor Green
    }
}

$dotfiles = Join-Path -Path $env:Repo -ChildPath "\dotfiles\"

$WinVimpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\nvim\"
$RepoVimpath = Join-Path -PATH $dotfiles -ChildPath "\nvim\"

$WinGlazepath = Join-Path -PATH $env:USERPROFILE -ChildPath "\.glzr\glazewm\"
$RepoGlazepath = Join-Path -PATH $dotfiles -ChildPath "\glazewm\"

$WinPSPath = Join-Path -PATH $env:USERPROFILE -ChildPath "\Documents\PowerShell\" 
$RepoPSpath = Join-Path -PATH $dotfiles -ChildPath "\PowerShell\"

$WinTermpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\"
$WinTermPreviewPath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "\Packages\Microsoft\Windows.TerminalPreview_8wekyb3d8bbwe\LocalState\"
$RepoTermpath = Join-Path -PATH $dotfiles -ChildPath "\Windows.Terminal\LocalState\"
$RepoTermPreviewPath = Join-path -PATH $dotfiles -ChildPath "\Windows.TerminalPreview\LocalState\"

Copy-IntoRepo "dotfiles"
Copy-IntoRepo "PWSH-Collection"

if ($PSHome -eq $PS1Home){
    if(-Not(Test-Path $PS7exe)){ &winget install Microsoft.PowerShell }
    
    $commandPath = (Join-Path $env:Repo "\PWSH-Collection\scripts\push-configs.ps1")
    $commandArgs = "$commandPath", "-ExecutionPolicy Bypass", "-Wait", "-NoNewWindow"
    &$PS7exe $commandArgs

    Write-Host "`nUpdated to PowerShell 7!" -ForegroundColor Green 
    &cmd.exe "/c TASKKILL /F /PID $PID" | Out-Null
}

$pwshCollectionModules = Get-ChildItem (Join-Path $env:Repo "\PWSH-Collection\modules\")
foreach($module in $pwshCollectionModules){
    Import-Module $module
}

function Get-Binary{
    Param(
        [Parameter(Position = 0, mandatory = $false)]
        $command,
        [Parameter(Position = 1, mandatory = $false)]
        $sourceRepo,
        [Parameter(Position = 2, mandatory = $false)]
        $namePattern,
        [Parameter(Position = 3, mandatory = $false)]
        [switch]$preRelease = $false,
        [Parameter(Position = 4, mandatory = $false)]
        [string]$override = $null
    )

    if (-Not(Get-Command $command -ErrorAction SilentlyContinue)){
        $libFolder = Join-Path -PATH $env:Repo -ChildPath "/lib/"
       
        if ([string]::IsNullOrEmpty($override)){ $sourceURI = Get-GitLatestReleaseURI $sourceRepo -n $namePattern -preRelease $preRelease }
        else{ $sourceURI = $override }

        $zipFolderName = $(Split-Path -Path $sourceURI -Leaf)
        $tempZIP = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $zipFolderName 
        Invoke-WebRequest -Uri $sourceURI -Out $tempZIP
   
        if ([string]::IsNullOrEmpty($sourceRepo)){ $destFolder = Join-Path $libFolder -ChildPath $zipFolderName }
        else { $destFolder = (Join-Path $libFolder -ChildPath $sourceRepo) }


        Expand-Archive -Path $tempZIP -DestinationPath $destFolder -Force
        Remove-Item $tempZIP -Force
        
        Remove-LayeredFolderLayers $destFolder

        $binFolder = (Join-Path -PATH $destFolder -ChildPath "\bin")

        if ((Test-Path "$binFolder") -And -Not([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) -like "*$binFolder*")){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$binFolder",[EnvironmentVariableTarget]::User)       
            Write-Host "Added $binFolder to path!" -ForegroundColor Green
        }
        elseIf(-Not([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) -like "*$destFolder*")){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$destFolder",[EnvironmentVariableTarget]::User)       
            Write-Host "Added $destFolder to path!" -ForegroundColor Green
        }

        Write-Host "$command successfully installed!" -ForegroundColor Green
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
        Write-Host "Not a valid path to copy config from." -ForegroundColor Red
        break
    }

    if (-Not(Test-Path $outputPath) -Or $null -eq (Get-ChildItem $outputPath -File -Recurse)){
        Write-Host "`nNo existing config found in $outputPath, pushing..."
	    Copy-Item $inputPath $outputPath -Recurse
        $script:filesAdded += (Get-ChildItem $outputPath -File -Recurse).count
    }
    else{
        Write-Host "`nExisting config found in $outputPath, updating..."
    	Push-ChangedFiles $inputPath $outputPath
    }
        Write-Host "Update Complete. "
        if(($script:filesAdded -eq 0) -And ($script:filesUpdated -eq 0)){Write-Host "No files changed."}
}

&scoop cleanup --all 6>$null
Get-FromPkgmgr scoop '7z' -o '7zip'
Get-FromPkgmgr scoop 'everything'
Get-FromPkgmgr scoop 'fzf'
Get-FromPkgmgr winget 'git' -o 'git.git'
Get-FromPkgmgr winget 'glazewm' -o 'glzr-io.glazeWM'
Get-FromPkgmgr scoop 'innounp'
Get-FromPkgmgr scoop 'lazygit'
Get-FromPkgmgr scoop 'less'
Get-FromPkgmgr scoop 'neofetch'
Get-FromPkgmgr scoop 'nvim' -o 'neovim'
Get-FromPkgmgr scoop 'ninja'
Get-FromPkgmgr scoop 'npm' -o 'nodejs'
Get-FromPkgmgr scoop 'rg' -o 'ripgrep'
Get-FromPkgmgr scoop 'spt' -o 'spotify-tui'
Get-FromPkgmgr scoop 'winfetch'
Get-FromPkgmgr scoop "$env:PROGRAMFILES\WireGuard\wireguard.exe" -o 'wireguard.wireguard'
Get-FromPkgmgr scoop 'zoomit'

Get-ScoopPackage 'discord'
Get-ScoopPackage 'listary'
Get-ScoopPackage 'libreoffice'
Get-ScoopPackage 'spotify'
Get-ScoopPackage 'vcredist2022'

Get-Binary glsl_analyzer "nolanderc/glsl_analyzer" -namePattern "*x86_64-windows.zip"
Get-Binary premake5 "premake/premake-core" -namePattern "*windows.zip" -preRelease
Get-Binary fd "sharkdp/fd" -namePattern "*x86_64-pc-windows-msvc.zip" 

#Get-Binary alpine -o "https://alpineapp.email/alpine/release/src/alpine-2.26.zip"

Push-Certain $RepoTermpath $WinTermpath
Push-Certain $RepoTermPreviewpath $WinTermPreviewPath
Push-Certain $RepoVimpath $WinVimpath
Push-Certain $RepoGlazepath $WinGlazepath
Push-Certain $RepoPSpath $WinPSPath

Get-NewMachinePath

$gitUserName = &git config get user.name
$gitUserEmail = &git config get user.email

if([string]::IsNullOrEmpty($gitUserName)){
    Write-Host "No git user.name found, please enter one now: " -NoNewline
    $gitUserName = Read-Host
    if ([string]::IsNullOrEmpty($gitUserName)) {
        Write-Host "ERROR: please enter username." -ForegroundColor Red
        break
    }
    &git config set user.name $gitUserName
}

if([string]::IsNullOrEmpty($gitUserEmail)){
    Write-Host "No git user.email found, please enter one now: " -NoNewline
    $gitUserEmail = Read-Host
    if (-Not(Test-EmailAddress $gitUserEmail)) {
        Write-Host "ERROR: please enter a valid e-mail address." -ForegroundColor Red
        break
    }
    &git config set user.email $gitUserEmail
}

#TODO: automatically ask for git ssh key and set it up 

if(-Not($script:filesAdded -eq 0) -Or -Not($script:filesUpdated -eq 0)){
    Write-Host "`nTotal config file changes:" -ForegroundColor White

    Get-FilesAdded
    Get-FilesUpdated

    Write-Host "`nAll configs are now up to date! ^^" -ForegroundColor Green
}

if(Test-IsNotWinTerm){
    if (-Not(Get-Command wt -ErrorAction SilentlyContinue)){ &winget install Microsoft.WindowsTerminal }

    $window = Get-CimInstance Win32_Process -Filter "ProcessId = $PID"
    $windowPID = $window.ProcessId
    $parentPID = $window.ParentProcessId
    
    Start-Process wt.exe
    &cmd.exe "/c TASKKILL /PID $parentPID" | Out-Null
    &cmd.exe "/c TASKKILL /PID $windowPID" | Out-Null
}
