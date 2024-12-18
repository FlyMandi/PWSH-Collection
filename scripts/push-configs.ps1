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
            throw "ERROR: Directory doesn't exist. Please create it or choose a valid Directory."
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

function Test-IsNotWinTerm{
    $process = Get-CimInstance -Query "SELECT * from Win32_Process WHERE name LIKE 'WindowsTerminal%'"
    return($null -eq $process)
}

$dotfiles = Join-Path -Path $env:Repo -ChildPath "\dotfiles\"

$scoopDir = Join-Path $env:USERPROFILE -ChildPath "\scoop\apps\"

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

[int]$script:filesAdded = 0
[int]$script:filesUpdated = 0

Copy-IntoRepo "dotfiles"
Copy-IntoRepo "PWSH-Collection"

if ($PSHome -eq $PS1Home){
    if(-Not(Test-Path $PS7exe)){ &winget install Microsoft.PowerShell }

    if ($null -eq $PSCommandPath){ $commandPath = (Join-Path $env:Repo "\PWSH-Collection\scripts\push-configs.ps1") }
    else{ $commandPath = $PSCommandPath }
    
    $commandArgs = "-File `"$commandPath`" -NoExit -NoProfile -ExecutionPolicy Bypass -Wait -NoNewWindow"
    Start-Process $PS7exe $commandArgs
    Write-Host "`nUpdated to PowerShell 7!" -ForegroundColor Green
} #FIXME: I'm calling pwsh.exe with wrongly formatted arguments, apparently

#Start the rest of this process as admin (avoid using it, comment out only for testing)
#if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
#        Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle hidden
#}

#In separate functions, in case I want to call it after every download or config push.
function Get-FilesAdded{
    if (-Not($script:filesAdded -eq 0)){Write-Host "Files Added: $script:filesAdded" -ForegroundColor Cyan -BackgroundColor Black}
    $script:filesAdded = 0
}

function Get-FilesUpdated{
    if(-Not($script:filesUpdated -eq 0)){Write-Host "Files Updated: $script:filesUpdated" -ForegroundColor Magenta -BackgroundColor Black}
    $script:filesUpdated = 0
}

function Get-NewMachinePath{
    $temp = $env:Path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    if (-Not($temp.Length) -eq ($env:Path.Length)){Write-Host "`nEnvironment variables updated!" -ForegroundColor Green}
}

Function Get-FromPkgmgr{ 
    Param(
        $pkgmgr,
        $trgt,
        [string]$override = $null
    )

    if (-Not (Get-Command $trgt -ErrorAction SilentlyContinue)){ 
        if(-Not ($null -eq $override)){ $trgt = $override }
        &$pkgmgr install $trgt
    }
}

Function Get-ScoopPackage{
    Param(
        $scoopTrgt
    )

    if (-Not (Test-Path (Join-Path -Path $scoopDir -ChildPath $scoopTrgt))) { 
        &scoop install $scoopTrgt
    }
}

function Get-Binary{
    Param(
        $command,
        $sourceRepo,
        $namePattern,
        [switch]$preRelease = $false
    )
    if (-Not(Get-Command $command -ErrorAction SilentlyContinue)){
        $libFolder = Join-Path -PATH $env:Repo -ChildPath "/lib/"
        
        if ($preRelease){
            Write-Host "Installing latest $namePattern release package from $sourceRepo..."
            $sourceURI = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/$sourceRepo/releases")[0].assets | Where-Object name -like $namePattern).browser_download_url
        }else{
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
        }elseIf(-Not([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) -like "*$repoNameFolder*")){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$repoNameFolder",[EnvironmentVariableTarget]::User)       
            Write-Host "Added $repoNameFolder to path!" -ForegroundColor Green
        }

        Write-Host "$command successfully installed!" -ForegroundColor Green
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

        if (-Not(Test-Path (Split-Path $fileInDest))){&mkdir (Split-Path $fileInDest) | Out-Null}
        Copy-Item -Path $fileInSource -Destination $fileInDest
        Write-Host "Added Item: " -ForegroundColor White -NoNewline
        Write-Host $file.InputObject -ForegroundColor Cyan -BackgroundColor Black
        $script:filesAdded++
    }
    
    foreach($file in $sourceTransformed){
        $fileInSource = (Join-Path -PATH $sourceFolder -ChildPath $file)
        $fileInDest = (Join-Path -PATH $destFolder -ChildPath $file)

        if(-Not((Get-FileHash $fileInSource).Hash -eq (Get-FileHash $fileInDest).Hash)){ 
            Remove-Item $fileInDest -Force
            Copy-Item $fileInSource -Destination $fileInDest
            Write-Host "Updated Item: " -ForegroundColor White -NoNewline
            Write-Host $file -ForegroundColor Magenta -BackgroundColor Black
            $script:filesUpdated++
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
Get-FromPkgmgr scoop 'innounp'
Get-FromPkgmgr scoop 'lazygit'
Get-FromPkgmgr scoop 'neofetch'
Get-FromPkgmgr scoop 'nvim' -o 'neovim'
Get-FromPkgmgr scoop 'ninja'
Get-FromPkgmgr scoop 'npm' -o 'nodejs'
Get-FromPkgmgr scoop 'rg' -o 'ripgrep'
Get-FromPkgmgr scoop 'spt' -o 'spotify-tui'
Get-FromPkgmgr scoop 'winfetch'
Get-FromPkgmgr scoop 'zoomit'
Get-FromPkgmgr winget 'git' -o 'git.git'
Get-FromPkgmgr winget 'glazewm' -o 'glzr-io.glazeWM'

Get-ScoopPackage 'discord'
Get-ScoopPackage 'listary'
Get-ScoopPackage 'libreoffice'
Get-ScoopPackage 'spotify'
Get-ScoopPackage 'vcredist2022'

Get-Binary glsl_analyzer "nolanderc/glsl_analyzer" -namePattern "*x86_64-windows.zip"
Get-Binary premake5 "premake/premake-core" -namePattern "*windows.zip" -preRelease
Get-Binary fd "sharkdp/fd" -namePattern "*x86_64-pc-windows-msvc.zip" 

Push-Certain $RepoTermpath $WinTermpath
Push-Certain $RepoTermPreviewpath $WinTermPreviewPath
Push-Certain $RepoVimpath $WinVimpath
Push-Certain $RepoGlazepath $WinGlazepath
Push-Certain $RepoPSpath $WinPSPath

Get-NewMachinePath

#TODO: automatically ask for git user.name and user.email if they are not set

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

