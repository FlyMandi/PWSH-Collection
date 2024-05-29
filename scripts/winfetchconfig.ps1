Param(
    [Parameter(Mandatory=$false,Position=0)]
    [string]$theme,
    [switch]$save = $false,
    [switch]$f = $false,
    [switch]$delete = $false
)

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
Clear-Temp
mkdir $tempFolder | Out-Null

$themePath = Join-Path -Path $configPath -ChildPath "\$theme.ps1"
$tempConfig = Join-Path -Path $tempFolder -ChildPath "\config.ps1"
$tempTheme = Join-Path -Path $tempFolder -ChildPath "$theme.ps1"

function Save-Theme{
    Copy-Item -Path $currentConfig -Destination $tempFolder
    Rename-Item -Path $tempConfig -NewName "$theme.ps1"
    Move-Item -Path $tempTheme -Destination $configPath
}

if (($save -and $delete) -or ($f -and $delete)){
    throw "ERROR: Choose only 1 operation at a time. (save/delete)"
}
elseif ($f){
    if (Test-Path $themePath){
        Remove-Item -Path $themePath
        Save-Theme
    }
    else{
        Save-Theme
    }
}
elseif ($save){
    if (Test-Path $themePath){    
        Clear-Temp
        throw "Config file with name already exists. To overwrite it, use 'winfetchconfig ThemeName -save -f'"
    }
    else{
        Save-Theme
    }
}
elseif ($delete){
    Remove-Item -Path $themePath
}
elseif (Test-Path -Path $themePath){
    Copy-Item -Path $themePath -Destination $tempFolder 
    Rename-Item -Path $tempTheme -NewName "config.ps1" 
    Move-Item -Path $tempConfig -Destination $destination -Force 
    # finally, call winfetch to show changes and success!
    winfetch
}
else{
    Write-Host "Not a valid theme name."
}
Clear-Temp