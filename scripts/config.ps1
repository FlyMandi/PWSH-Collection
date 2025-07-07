#TODO: test this thang on VMs
#Win11 23H2 onwards.
#for linux prob only arch.
#macOS I don't care about.

param( $operation )

if(-Not (Get-Command winget -ErrorAction SilentlyContinue) -and $IsWindows)
{
    Invoke-RestMethod   "https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1"
                        | Invoke-Expression | Out-Null
}

if(-Not (Get-Command scoop -ErrorAction SilentlyContinue) -and $IsWindows)
{
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression

    #probably move into a function called Install-PKGMGRs or something?
    &scoop config SCOOP_BRANCH develop
    &scoop bucket add "extras"
    &scoop bucket add "nerd-fonts"
    &scoop bucket add "sysinternals"
    &scoop bucket add scoop-imgcat https://github.com/danielgatis/scoop-imgcat.git
    &scoop update
}

#TODO: Replace wt detecting functionality with WezTerm

[int]$script:filesAdded = 0
[int]$script:filesUpdated = 0

if($IsWindows)
{
    $PS1Home = (Join-Path $env:SYSTEMROOT "/System32/WindowsPowerShell/v1.0")
    $PS7exe = (Join-Path $env:PROGRAMFILES "/PowerShell/7/pwsh.exe")
}

function Get-FilesAdded
{
    if(-Not($script:filesAdded -eq 0))
    {
        Write-Host "Files Added: $script:filesAdded" -ForegroundColor Cyan -BackgroundColor Black
    }
    $script:filesAdded = 0
}

function Get-FilesUpdated
{
    if(-Not($script:filesUpdated -eq 0))
    {
        Write-Host "Files Updated: $script:filesUpdated" -ForegroundColor Magenta -BackgroundColor Black
    }
    $script:filesUpdated = 0
}

function Get-UpdateSummary
{
    if(($script:filesAdded -gt 0) -Or ($script:filesUpdated -gt 0))
    {
        Write-Host "`nTotal config file changes:" -ForegroundColor White
        Get-FilesAdded
        Get-FilesUpdated
        Write-Host "`nAll configs are now up to date! ^^" -ForegroundColor Green

        if($operation -eq "push")
        {
            Write-Host "Would you like to commit your changes now?(y/n): " -ForegroundColor Yellow -NoNewline
            $answer = Read-Host
            if(($answer -eq "y") -Or ($answer -eq "yes"))
            {
                Push-Location "$env:Repo/dotfiles/"
                &lazygit
                Pop-Location
            }
        }
    }
}

function Push-ChangedFiles
{
    param
    (
        $sourceFolder,
        $destFolder,
        $sourceFileList,
        $destFileList
    )

    if($null -eq $sourceFileList)
    {
        Write-Host "ERROR: No files to copy from." -ForegroundColor Red
        break
    }
    elseIf($null -eq $destFileList)
    {
        Write-Host "ERROR: No files to compare against." -ForegroundColor Red
        break
    }
    else
    {
        $sourceTransformed = @()
        $destTransformed = @()

        foreach($file in $sourceFileList)
        {
            $sourceTransformed += ([string]$file).Substring($sourceFolder.Length)
        }

        foreach($file in $destFileList)
        {
            $destTransformed += ([string]$file).Substring($destFolder.Length)
        }

        $missingFiles = Compare-Object $sourceTransformed $destTransformed
                        | Where-Object {$_.sideindicator -eq "<="}
    }

    foreach($file in $missingFiles)
    {
        $fileInSource = (Join-Path -PATH $sourceFolder -ChildPath $file.InputObject)
        $fileInDest = (Join-Path -PATH $destFolder -ChildPath $file.InputObject)

        if(-Not(Test-Path (Split-Path $fileInDest)))
        {
            &mkdir (Split-Path $fileInDest) | Out-Null
        }
        Copy-Item -Path $fileInSource -Destination $fileInDest
        Write-Host "Added Item: " -ForegroundColor White -NoNewline
        Write-Host $file.InputObject -ForegroundColor Cyan -BackgroundColor Black
        $script:filesAdded++
    }

    foreach($file in $sourceTransformed)
    {
        $fileInSource = (Join-Path -PATH $sourceFolder -ChildPath $file)
        $fileInDest = (Join-Path -PATH $destFolder -ChildPath $file)

        if(-Not((Get-FileHash $fileInSource).Hash -eq (Get-FileHash $fileInDest).Hash))
        {
            Remove-Item $fileInDest -Force
            Copy-Item $fileInSource -Destination $fileInDest
            Write-Host "Updated Item: " -ForegroundColor White -NoNewline
            Write-Host $file -ForegroundColor Magenta -BackgroundColor Black
            $script:filesUpdated++
        }
    }
}

if(-Not(Test-Path $env:Repo))
{
    if($isLinux)
    {
        Write-Host "/Repository/ folder location at: " -ForegroundColor Red -NoNewline
        Write-Host "`"$env:Repo`"" -ForegroundColor Yellow -NoNewline
        Write-Host " not found, do you want to set it as '~/repository/'?" -ForegroundColor Red -NoNewline
        Write-Host "(y/n): " -NoNewline -ForegroundColor Yellow

        #FIXME : finish setting up repo
        $answer = Read-Host
        if(($answer -eq "y") -Or ($answer -eq "yes"))
        {
            [System.Environment]::SetEnvironmentVariable("repo", "~/repository/", "User")
            $env:Repo = "~/repository/"
        }
        else
        {
            Write-Host "Please provide another Directory: " -ForegroundColor Yellow -NoNewline
            $InputRepo = Read-Host

            if(-Not(Test-Path $InputRepo))
            {
                throw "FATAL: Directory doesn't exist. Please create it or choose a valid Directory."
            }
            else
            {
                [System.Environment]::SetEnvironmentVariable("Repo", $InputRepo, "User")
                $env:Repo = $InputRepo
            }
        }
    }
    elseIf($IsWindows)
    {
        Write-Host "/Repository/ folder location at: " -ForegroundColor Red -NoNewline
        Write-Host "`"$env:Repo`"" -ForegroundColor Yellow -NoNewline
        Write-Host " not found, do you want to set it as 'C:/Repository/'?" -ForegroundColor Red -NoNewline
        Write-Host "(y/n): " -NoNewline -ForegroundColor Yellow

        $answer = Read-Host
        if(($answer -eq "y") -Or ($answer -eq "yes"))
        {
            [System.Environment]::SetEnvironmentVariable("Repo", "C:/Repository/", "User")
            $env:Repo = "C:/Repository/"
        }
        else
        {
            Write-Host "Please provide another Directory: " -ForegroundColor Yellow -NoNewline
            $InputRepo = Read-Host

            if(-Not(Test-Path $InputRepo))
            {
                throw "FATAL: Directory doesn't exist. Please create it or choose a valid Directory."
            }
            else
            {
                [System.Environment]::SetEnvironmentVariable("Repo", $InputRepo, "User")
                $env:Repo = $InputRepo
            }
        }
    }
}

function Copy-IntoRepo
{
    Param(
        $folderName
    )

    $folderPath = Join-Path $env:Repo $folderName
    if((-Not(Test-Path $folderPath)) -Or ((Get-ChildItem $folderPath -File).count -eq 0))
    {
        &git clone "https://github.com/FlyMandi/$folderName" $folderPath
        Write-Host "Cloned FlyMandi/$folderName repository successfully!" -ForegroundColor Green
    }
    elseIf($operation -eq "update")
    {
        $current = Get-Location
        Set-Location $folderPath
        &git pull
        Set-Location $current
    }
}

function Push-ConfigSafely
{
    param
    (
        $inputPath,
        $outputPath,
        $inputFileList,
        $outputFileList
    )
    $updated = $script:filesUpdated

    if(-Not(Test-Path $inputPath))
    {
        Write-Host "Could not write config from " -NoNewline -ForegroundColor Red
        Write-Host $inputPath -BackgroundColor DarkGray
        Write-Host "Not a valid path to copy config from." -ForegroundColor Red
        break;
    }

    if(-Not(Test-Path $outputPath) -Or $null -eq (Get-ChildItem $outputPath -File -Recurse))
    {
        Write-Host "`nNo existing config found in $outputPath, pushing..."

        foreach($item in $inputFileList)
        {
            Copy-Item $item $outputPath
        }

        $script:filesAdded += $inputFileList.size
    }
    else
    {
        Write-Host "`nExisting config found in $outputPath, updating..."
    	Push-ChangedFiles $inputPath $outputPath $inputFileList $outputFileList
    }

    Write-Host "Update Complete. "
    if($script:filesUpdated -eq $updated)
    {
        Write-Host "No existing files changed."
    }
}

# TODO: resolve these paths on linux & MAYBE android()
$dotfiles = Join-Path -Path $env:Repo -ChildPath "/dotfiles/"

$RepoVimpath = Join-Path -PATH $dotfiles -ChildPath "/nvim/"
    #TODO: ignore anything that isn't:
    # init.lua
    # lua/*
    # ftplugin/*

#LINUX PATHS
if($isLinux)
{
    $LinVimPath = "~/.config/nvim/"
    $LinVimList = Get-ChildItem $LinVimpath -File -Recurse | Where-Object {$_ -notmatch "lazy-lock"}

    $LinX11Path =   "~/"
    $LinX11List =   (Join-Path $LinX11Path "/.xinitrc")

    $LinSXWMPath =  "~/.config/"
    $LinSXWMList =  (Join-Path $LinSXWMPath "/sxwmrc")

    $LinWeztermPath =   "~/"
    $LinWeztermList =   (Join-Path $LinWeztermPath "/.wezterm.lua")

    $LinPSPath =    "~/.config/powershell/"
    $LinPSList =    (Join-Path $LinPSPath "/config.omp.json"),
                    (Join-Path $LinPSPath "/Microsoft.Powershell_profile.ps1")

    $LinFastfetchPath = "~/.config/fastfetch/"
    $LinFastfetchList = Get-ChildItem $WinFastfetchPath -File -Recurse
                        | Where-Object {$_ -notmatch "config.jsonc"}
}
#WINDOWS PATHS
elseIf($IsWindows)
{
    $WinVimpath = Join-Path -PATH $env:LOCALAPPDATA -ChildPath "/nvim/"
    $WinVimList = Get-ChildItem $WinVimpath -File -Recurse | Where-Object {$_ -notmatch "lazy-lock"}

    $WinGlazePath = Join-Path -PATH $env:USERPROFILE -ChildPath "/.glzr/glazewm/"
    $WinGlazeList = Get-ChildItem $WinGlazePath -File -Recurse | Where-Object {$_ -notmatch ".log"}

    $WinWeztermPath = Join-Path -PATH $env:USERPROFILE -ChildPath "/.config/wezterm/"
    $WinWeztermList = Get-ChildItem $WinWeztermPath -File -Recurse | Where-Object {$_ -notmatch ".log"}

    $WinPSPath =    Join-Path -PATH $env:USERPROFILE -ChildPath "/Documents/PowerShell/"
    $WinPSList =    (Join-Path $WinPSPath "/config.omp.json"),
                    (Join-Path $WinPSPath "/Microsoft.PowerShell_profile.ps1")

    $WinFastfetchPath = Join-Path -PATH $env:USERPROFILE -ChildPath "/.config/fastfetch/"
    $WinFastfetchList = Get-ChildItem $WinFastfetchPath -File -Recurse
                        | Where-Object {$_ -notmatch "config.jsonc"}

    $WinFancontrolPath = Join-Path -PATH $env:USERPROFILE -ChildPath "/scoop/persist/fancontrol/configurations/"
    $WinFancontrolList = Get-Childitem $WinFancontrolPath -File -Recurse | Where-Object {$_ -notmatch "CACHE"}
}

#REPO PATHS
$RepoVimList = Get-ChildItem $RepoVimpath -File -Recurse | Where-Object {$_ -notmatch "lazy-lock"}

$RepoGlazePath = Join-Path -PATH $dotfiles -ChildPath "/glazewm/"
$RepoGlazeList = Get-ChildItem $RepoGlazePath -File -Recurse | Where-Object {$_ -notmatch ".log"}

$RepoX11Path = Join-Path -PATH $dotfiles -ChildPath "/x11/"
$RepoX11List = Join-Path $RepoX11Path "/.xinitrc"

$RepoSXWMPath = Join-Path -PATH $dotfiles -ChildPath "/sxwm/"
$RepoSXWMList = Join-Path $RepoSXWMPath "/sxwmrc"

$RepoWeztermPath = Join-Path -PATH $dotfiles -ChildPath "/wezterm/"
$RepoWeztermList = Get-ChildItem $RepoWeztermPath -File -Recurse | Where-Object {$_ -notmatch ".log"}

$RepoPSPath = Join-Path -PATH $dotfiles -ChildPath "/PowerShell/"
$RepoPSList =   (Join-Path $RepoPSpath "/config.omp.json"),
                (Join-Path $RepoPSpath "/Microsoft.PowerShell_profile.ps1")

$RepoFastfetchPath = Join-Path -PATH $dotfiles -ChildPath "/fastfetch/"
$RepoFastfetchList =    Get-ChildItem $RepoFastfetchPath -File -Recurse
                        | Where-Object {$_ -notmatch "config.jsonc"}

$RepoFancontrolPath = Join-Path -PATH $dotfiles -ChildPath "/fancontrol/"
$RepoFancontrolList =   Get-Childitem $RepoFancontrolPath -File -Recurse
                        | Where-Object {$_ -notmatch "CACHE"}

if($isWindows -and ($PSHome -eq $PS1Home))
{
    if(-Not(Test-Path $PS7exe))
    {
        &winget install Microsoft.PowerShell
    }

    $commandPath = (Join-Path $env:Repo "/PWSH-Collection/scripts/config.ps1")
    $commandArgs = "$commandPath", "-ExecutionPolicy Bypass", "-Wait", "-NoNewWindow"
    &$PS7exe $commandArgs

    Write-Host "`nUpdated to PowerShell 7!" -ForegroundColor Green
    &cmd.exe "/c TASKKILL /F /PID $PID" | Out-Null
}

Copy-IntoRepo "dotfiles"
Copy-IntoRepo "PWSH-Collection"

$pwshCollectionModules = Get-ChildItem (Join-Path $env:Repo "/PWSH-Collection/modules/")
foreach($module in $pwshCollectionModules)
{
    Import-Module $module
}

Get-NewMachinePath

function Push-LinuxToRepo
{
    Push-ConfigSafely $LinVimpath           $RepoVimpath        $LinVimList         $RepoVimList
    Push-ConfigSafely $LinX11Path           $RepoX11Path        $LinX11List         $RepoX11List
    Push-ConfigSafely $LinSXWMPath          $RepoSXWMPath       $LinSXWMList        $RepoSXWMList
    Push-ConfigSafely $LinWeztermPath       $RepoWeztermPath    $LinWeztermList     $RepoWeztermList
    Push-ConfigSafely $LinPSPath            $RepoPSpath         $LinPSList          $RepoPSList
    Push-ConfigSafely $LinFastfetchPath     $RepoFastfetchPath  $LinFastfetchList   $RepoFastfetchList
}

function Push-RepoToLinux
{
    Push-ConfigSafely $RepoVimpath          $LinVimpath         $RepoVimList        $LinVimList
    Push-ConfigSafely $RepoSXWMPath         $LinSXWMPath        $RepoSXWMList       $LinSXWMList
    Push-ConfigSafely $RepoWeztermPath      $LinWeztermPath     $RepoWeztermList    $LinWeztermList
    Push-ConfigSafely $RepoPSpath           $LinPSPath          $RepoPSList         $LinPSList
    Push-ConfigSafely $RepoFastfetchPath    $LinFastfetchPath   $RepoFastfetchList  $LinFastfetchList
}

function Push-WindowsToRepo
{
    Push-ConfigSafely $WinVimpath           $RepoVimpath        $WinVimList         $RepoVimList
    Push-ConfigSafely $WinGlazePath         $RepoGlazePath      $WinGlazeList       $RepoGlazeList
    Push-ConfigSafely $WinWeztermPath       $RepoWeztermPath    $WinWeztermList     $RepoWeztermList
    Push-ConfigSafely $WinPSPath            $RepoPSpath         $WinPSList          $RepoPSList
    Push-ConfigSafely $WinFastfetchPath     $RepoFastfetchPath  $WinFastfetchList   $RepoFastfetchList
    Push-ConfigSafely $WinFancontrolPath    $RepoFancontrolPath $WinFancontrolList  $RepoFancontrolList
}

function Push-RepoToWindows
{
    Push-ConfigSafely $RepoVimpath          $WinVimpath         $RepoVimList        $WinVimList
    Push-ConfigSafely $RepoGlazePath        $WinGlazePath       $RepoGlazeList      $WinGlazeList
    Push-ConfigSafely $RepoWeztermPath      $WinWeztermPath     $RepoWeztermList    $WinWeztermList
    Push-ConfigSafely $RepoPSpath           $WinPSPath          $RepoPSList         $WinPSList
    Push-ConfigSafely $RepoFastfetchPath    $WinFastfetchPath   $RepoFastfetchList  $WinFastfetchList
    Push-ConfigSafely $RepoFancontrolPath   $WinFancontrolPath  $RepoFancontrolList $WinFancontrolList
}

switch($operation)
{
    "push"
    {
        if($isLinux)
        {
            Push-LinuxToRepo
        }
        elseIf($IsWindows)
        {
            Push-WindowsToRepo
        }

        Get-UpdateSummary

    }
    "pull"
    {
        if($isLinux)
        {
            Push-RepoToLinux
        }
        elseIf($IsWindows)
        {
            Push-RepoToWindows
        }

        Get-UpdateSummary

    }
    "clean"
    {
        #TODO: linux cleanup & windows expanded
        &scoop cleanup --all
        $nvimLogs = (Get-ChildItem -File (Join-Path $env:LOCALAPPDATA "/nvim-data/"))
                    | Where-Object {$_ -match ".log"}

        foreach($log in $nvimLogs)
        {
            Remove-Item $log
        }

    }
    "update"
    {
        if($IsLinux)
        {
            &yay
            # Get-NewMachinePath
        }
        elseIf($IsWindows)
        {
            &scoop update --all
            &winget upgrade --all
            Get-NewMachinePath
        }

    }
    "verify"
    {
        #FIXME: wip
        Write-Host "Please verify all paths are set adequately below:"

        if($isLinux)
        {
            foreach($file in $LinVimList)
            {
                Write-Host $file
            }
        }
        elseIf($IsWindows)
        {
            foreach($file in $WinVimList)
            {
                Write-Host $file
            }
        }
    }
    "setup"
    {
        if($isLinux)
        {
            Get-FromPkgmgr pacman   'bat'
            Get-FromPkgmgr pacman   'btop'
            Get-FromPkgmgr pacman   'cloc'
            Get-FromPkgmgr pacman   'dust'
            Get-FromPkgmgr pacman   'fastfetch'
            Get-FromPkgmgr pacman   'fzf'
            Get-FromPkgmgr pacman   'gcc'
            Get-FromPkgmgr pacman   'git'
            Get-FromPkgmgr pacman   'lazygit'
            Get-FromPkgmgr pacman   'less'
            Get-FromPkgmgr pacman   'libx11'
            Get-FromPkgmgr pacman   'libxinerama'
            Get-FromPkgmgr pacman   'make'
            Get-FromPkgmgr pacman   'nvim'
            Get-FromPkgmgr pacman   'openssh'
            Get-FromPkgmgr yay      'powershell-bin'
            Get-FromPkgmgr pacman   'wezterm'
            Get-FromPkgmgr pacman   'rofi'
            Get-FromPkgmgr pacman   'qutebrowser'
            Get-FromPkgmgr yay      'sxwm'
            Get-FromPkgmgr pacman   'xorg-server'
            Get-FromPkgmgr pacman   'xorg-xinit'
            Get-FromPkgmgr pacman   'xorg-xrandr'

            Push-RepoToLinux
        }
        elseIf($isWindows)
        {
            Get-FromPkgmgr scoop    '7z' -o '7zip'
            Get-FromPkgmgr scoop    'bat'
            Get-FromPkgmgr scoop    'btop'
            Get-FromPkgmgr scoop    'cloc'
            Get-FromPkgmgr scoop    'dust'
            Get-FromPkgmgr scoop    'everything'
            Get-FromPkgmgr scoop    'fastfetch'
            Get-FromPkgmgr scoop    'fzf'
            Get-FromPkgmgr winget   'git' -o 'git.git'
            Get-FromPkgmgr scoop    'glazewm'
            Get-FromPkgmgr scoop    'hwinfo'
            Get-FromPkgmgr scoop    'hxd'
            Get-FromPkgmgr scoop    'innounp'
            Get-FromPkgmgr scoop    'imgcat'
            Get-FromPkgmgr scoop    'lazygit'
            Get-FromPkgmgr scoop    'less'
            Get-FromPkgmgr scoop    'luarocks'
            Get-FromPkgmgr scoop    'ninja'
            Get-FromPkgmgr scoop    'npm' -o 'nodejs'
            Get-FromPkgmgr scoop    'nvim' -o 'neovim'
            Get-FromPkgmgr scoop    'premake5' -o 'premake'
            Get-FromPkgmgr scoop    'rg' -o 'ripgrep'
            Get-FromPkgmgr scoop    'renderdoccli' -o 'renderdoc'
            Get-FromPkgmgr scoop    'tree-sitter'
            Get-FromPkgmgr scoop    'tldr'
            Get-FromPkgmgr scoop    'winfetch'
            Get-FromPkgmgr scoop    'wireguard' -o 'wireguard.wireguard'
            Get-FromPkgmgr scoop    'yt-dlp'
            Get-FromPkgmgr scoop    'zoomit'

            Get-ScoopPackage 'cpu-z'
            Get-ScoopPackage 'ddu'
            Get-ScoopPackage 'discord'
            Get-ScoopPackage 'fancontrol'
            Get-ScoopPackage 'gpu-z'
            Get-ScoopPackage 'listary'
            Get-ScoopPackage 'libreoffice'
            Get-ScoopPackage 'lua-for-windows'
            Get-ScoopPackage 'spotify'
            Get-ScoopPackage 'vcredist2022'

            #TODO: move OS detection into Get-Binary
            Get-Binary glsl_analyzer "nolanderc/glsl_analyzer" -namePattern "*x86_64-windows.zip"
            Get-Binary fd "sharkdp/fd" -namePattern "*x86_64-pc-windows-msvc.zip"
            Get-Binary raddbg "EpicGamesExt/raddebugger" -namePattern "raddbg.zip"

            Push-RepoToWindows
        }

        Get-NewMachinePath

        Test-GitUserName
        Test-GitUserEmail

        #TODO: automatically ask for git ssh key and set it up

        Get-UpdateSummary
    }
}

#TODO: rewrite function for WezTerm
# if(Test-IsNotWinTerm){
#     if(-Not(Get-Command wt -ErrorAction SilentlyContinue)){ &winget install Microsoft.WindowsTerminal.Preview }
#
#     $window = Get-CimInstance Win32_Process -Filter "ProcessId = $PID"
#     $windowPID = $window.ProcessId
#     $parentPID = $window.ParentProcessId
#
#     Start-Process wt.exe
#     &cmd.exe "/c TASKKILL /PID $parentPID" | Out-Null
#     &cmd.exe "/c TASKKILL /PID $windowPID" | Out-Null
# }
