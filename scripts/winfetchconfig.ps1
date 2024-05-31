Param(
    [Parameter(Mandatory=$false,Position=0)]
    [string]$operation = '',
    [Parameter(Mandatory=$false,Position=1)]
    [string]$theme,
    [switch]$f = $false
)
    
# juuust to make sure we don't run into "theme.ps1.ps1" shenanigans 
$theme = [System.IO.Path]::GetFileNameWithoutExtension($theme)

# destination should not need to be changed. Current config is in C:\users\YOU\.config\winfetch
$destination = Join-Path -PATH $env:USERPROFILE -ChildPath "\.config\winfetch"
if (-Not (Test-Path $destination)){
    throw "ERROR: winfetch not installed. Run 'scoop install winfetch' to install. If winfetch is installed, the .config folder can't be found."
}

$configPath = Join-Path -Path "$env:USERPROFILE" -ChildPath "\Documents\.personalConfigs\winfetch\"
$defaultPath = (Join-Path -Path $configPath -ChildPath "\default")
# if config directory doesn't exist, create it
if (-Not (Test-Path $defaultPath)){
    $defaultPath = (Join-Path -Path $configPath -ChildPath "\default")
    mkdir $defaultPath
}

$defaultConfig = Join-Path -Path $configPath -ChildPath "default\!default.ps1"
$currentConfig = Join-Path -Path $destination -ChildPath "\config.ps1"

# if "!default.ps1" doesn't exist, copy current config and store it there
if (-Not (Test-Path $defaultConfig)){
    Copy-Item -Path $currentConfig -Destination $script:defaultPath
    Rename-Item -Path (Join-Path -Path $script:defaultPath -ChildPath "\config.ps1") -NewName "!default.ps1"
    Write-Host "`nCurrent config stored as '!default'."
}

# set environment
$tempFolder = Join-Path -PATH $configPath -ChildPath "\temp"
$tempConfig = Join-Path -Path $tempFolder -ChildPath "\config.ps1"
function Set-Env{
    $script:themePath = Join-Path -Path $configPath -ChildPath "\$theme.ps1"
    $script:tempTheme = Join-Path -Path $tempFolder -ChildPath "$theme.ps1"
    $script:themePathValid = (Test-Path -Path $themePath)
}

Set-Env

function Clear-Temp {
    if ((Test-Path -Path $tempFolder)){
        Remove-Item -force -recurse $tempFolder
    }
}
# if it already exists, clear it
# called here just to be sure, can't hurt.
Clear-Temp
mkdir $tempFolder | Out-Null

function Save-Theme{
    Copy-Item -Path $currentConfig -Destination $tempFolder
    Rename-Item -Path $tempConfig -NewName "$theme.ps1"
    Move-Item -Path $tempTheme -Destination $configPath
    Write-Host "Successfully saved theme as '$theme'"
}

function Get-List{
    Get-ChildItem "$configPath\*.ps1" -Name
}

function Push-Theme{
    # move config from folder to winfetch
    Copy-Item -Path $themePath -Destination $tempFolder
    Rename-Item -Path $tempTheme -NewName "config.ps1" 
    Move-Item -Path $tempConfig -Destination $destination -Force 
    # finally, call winfetch to show changes
    winfetch
}

# input logic
switch ($operation) {
    "delete" {
        if (Test-Path $themePath){
            Remove-Item -Path $themePath
            Write-Host "Deleted theme '$theme'."
        }
        else{
            Write-Host "No theme found with the name '$theme'."
        }
    }
    "save" {
        if ($themePathValid){
            if ($f) {
                Remove-Item -Path $themePath -Force
                Save-Theme
                Write-Host "Theme overwritten."
            }
            else{
                Clear-Temp
                Write-Host "Config file with name already exists. To overwrite it, use 'winfetchconfig save ThemeName -f'"
            }
        }
        else{
            Save-Theme
        }
    }
    "list" {
        Get-List
    }
    "edit"{
        # notepad is fine, no real need to use another editor... but I'm not gonna stop you.
        if ($theme -eq ''){
            notepad $currentConfig
        }
        else{
            notepad $themePath
        }
    }
    "choose"{
        if ($themePathValid){
            Push-Theme
        }
        else {
            Write-Host "No theme found with the name '$theme'."
        }
    }
    "random"{
        $theme = (Get-List | Get-Random)
        $theme = [System.IO.Path]::GetFileNameWithoutExtension($theme)
        Set-Env
        Push-Theme
    }
    "reset"{
        Set-Env
        Copy-Item -Path $defaultConfig -Destination $tempFolder
        Rename-Item -Path "$tempFolder\!default.ps1" -NewName "config.ps1" 
        Move-Item -Path $tempConfig -Destination $destination -Force 
        winfetch
    }
    "savedefault"{
        Copy-Item -Path $currentConfig -Destination $tempFolder
        Rename-Item -Path $tempConfig -NewName "!default.ps1"
        Move-Item -Path "$tempFolder\!default.ps1" -Destination $defaultPath -Force
        Write-Host "Successfully saved current theme as default."
    }
    Default {
        Write-Host "Not a valid operation."
    }
}

# make sure to leave no leftovers
Clear-Temp