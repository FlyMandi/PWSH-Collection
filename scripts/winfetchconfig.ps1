Param(
    [Parameter(Mandatory=$false,Position=0)]
    [string]$operation = '',
    [Parameter(Mandatory=$false,Position=1)]
    [string]$theme,
    [switch]$f = $false
)
    
$theme = [System.IO.Path]::GetFileNameWithoutExtension($theme)

$editor = "notepad"
if (Get-Command "nvim" -ErrorAction SilentlyContinue) { $editor = "nvim" }

$destination = Join-Path -PATH $env:USERPROFILE -ChildPath "\.config\winfetch"
if (-Not (Test-Path $destination)){
    &mkdir $destination | Out-Null
}

if (Test-Path("$env:Repo\dotfiles\winfetch\")){
    $env:configPath = Join-Path $env:Repo "\dotfiles\winfetch\"
}
else{
    $env:configPath = Join-Path $env:USERPROFILE "\.personalConfigs\winfetch\"
}


$defaultPath = (Join-Path -Path $env:configPath -ChildPath "\default\")
if (-Not (Test-Path $defaultPath)){
    &mkdir $defaultPath | Out-Null
}

$defaultConfig = Join-Path -Path $defaultPath -ChildPath "!default.ps1"
$currentConfig = Join-Path -Path $destination -ChildPath "config.ps1"

if (-Not (Test-Path $defaultConfig)){
    Copy-Item -Path $currentConfig -Destination $script:defaultPath
    Rename-Item -Path (Join-Path -Path $script:defaultPath -ChildPath "\config.ps1") -NewName "!default.ps1"
    Write-Host "`nCurrent config stored as '!default'."
}

$tempFolder = Join-Path -PATH $env:configPath -ChildPath "\temp"
$tempConfig = Join-Path -Path $tempFolder -ChildPath "\config.ps1"
function Set-Env{
    $script:themePath = Join-Path -Path $env:configPath -ChildPath "\$theme.ps1"
    $script:tempTheme = Join-Path -Path $tempFolder -ChildPath "$theme.ps1"
    $script:themePathValid = (Test-Path -Path $themePath)
}

Set-Env

function Clear-Temp {
    if ((Test-Path -Path $tempFolder)){
        Remove-Item -force -recurse $tempFolder
    }
}

Clear-Temp
mkdir $tempFolder | Out-Null

function Save-Theme{
    Copy-Item -Path $currentConfig -Destination $tempFolder
    Rename-Item -Path $tempConfig -NewName "$theme.ps1"
    Move-Item -Path $tempTheme -Destination $env:configPath
    Write-Host "Successfully saved theme as '$theme'"
}

function Get-List{
    Get-ChildItem "$env:configPath\*.ps1" | Select-Object BaseName
}

function Push-Theme{
    Copy-Item -Path $themePath -Destination $tempFolder
    Rename-Item -Path $tempTheme -NewName "config.ps1" 
    Move-Item -Path $tempConfig -Destination $destination -Force 
    winfetch
}

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

        if ($theme -eq ''){
            &$editor $currentConfig
        }
        else{
            &$editor $themePath
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
    ''{
        winfetch
    }
    Default {
        # super scuffed but listen, it works.
        $theme = $operation
        Set-Env
        if ($themePathValid){
            Push-Theme
        }
        else {
            Write-Host "No theme found with the name '$theme'."
        }
    }
}

Clear-Temp
