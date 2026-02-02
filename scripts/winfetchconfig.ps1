Param(
    [Parameter(Mandatory=$false,Position=0)]
    [string]$operation = '',
    [Parameter(Mandatory=$false,Position=1)]
    [string]$theme,
    [switch]$f = $false
)

#TODO: write "random" functionality

# destination should not need to be changed. Current config is in C:\users\YOU\.config\winfetch
$destination = Join-Path -PATH $env:USERPROFILE -ChildPath "\.config\winfetch"
if (-Not (Test-Path $destination)){
    throw "ERROR: winfetch not installed. Run 'scoop install winfetch' to install. If winfetch is installed, the .config folder can't be found."
}

$configPath = Join-Path -Path "$env:USERPROFILE" -ChildPath "\Documents\.personalConfigs\winfetch\"
# if config directory doesn't exist, create it
if (-Not (Test-Path $configPath)){
    mkdir $configPath
}

$defaultConfig = Join-Path -Path $configPath -ChildPath "\!default.ps1"
$currentConfig = Join-Path -Path $destination -ChildPath "\config.ps1"

# if "!default.ps1" doesn't exist, copy current config and store it there
if (-Not (Test-Path $defaultConfig)){
    Copy-Item -Path $currentConfig -Destination $configPath
    Rename-Item -Path (Join-Path -Path $configPath -ChildPath "\config.ps1") -NewName "!default.ps1"
    Write-Host "`nCurrent config stored as '!default'."
}

$tempFolder = Join-Path -PATH $configPath -ChildPath "\temp"
# if it already exists, clear it
function Clear-Temp {
    if ((Test-Path -Path $tempFolder)){
        Remove-Item -force -recurse $tempFolder
    }
}
# just to be sure, can't hurt.
Clear-Temp
mkdir $tempFolder | Out-Null

$themePath = Join-Path -Path $configPath -ChildPath "\$theme.ps1"
$tempConfig = Join-Path -Path $tempFolder -ChildPath "\config.ps1"
$tempTheme = Join-Path -Path $tempFolder -ChildPath "$theme.ps1"

function Save-Theme{
    Copy-Item -Path $currentConfig -Destination $tempFolder
    Rename-Item -Path $tempConfig -NewName "$theme.ps1"
    Move-Item -Path $tempTheme -Destination $configPath
    Write-Host "Successfully saved theme as '$theme'"
}

switch ($operation) {
    "delete" {
        Remove-Item -Path $themePath
    }
    "save" {
        if (Test-Path $themePath){
            if ($f) {
                Remove-Item -Path $themePath -Force
                Save-Theme
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
        Clear-Temp
        Get-ChildItem $configPath -Name
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
        if (Test-Path -Path $themePath){
            # move config from folder to winfetch
            Copy-Item -Path $themePath -Destination $tempFolder 
            Rename-Item -Path $tempTheme -NewName "config.ps1" 
            Move-Item -Path $tempConfig -Destination $destination -Force 
            # finally, call winfetch to show changes and success!
            winfetch
        }
        else {Write-Host "Not a valid theme name."}
    }
    Default {
        Write-Host "Not a valid operation."
    }
}

Clear-Temp