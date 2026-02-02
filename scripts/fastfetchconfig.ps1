#TODO: fix linux
param
(
    [Parameter(Mandatory=$false,Position=0)]
    $operation,
    [Parameter(Mandatory=$false,Position=1)]
    $name,
    [Parameter(Mandatory=$false,Position=2)]
    $destination
)

if($isLinux)
{
    $configFolder = "~/.config/fastfetch/"
}
elseIf($IsWindows)
{
    $configFolder = Join-Path -PATH $env:USERPROFILE -ChildPath "/.config/fastfetch/"
}

$currentConfig = Join-Path -PATH $configFolder -ChildPath "/config.jsonc"
$pathFromThemeName = Join-Path $configFolder "/$name.jsonc"

$themeNotFound = "NOTE: '$name' couldn't be found in list of available themes."

function Get-Fastfetch
{
    Clear-Host
    Write-Host ""
    fastfetch
    Write-Host ""
}

switch($operation)
{
    "save"
    {
        Copy-Item $currentConfig (Join-Path $configFolder "/$name.jsonc")
        Write-Host "Successfully saved theme '$name'."
    }
    "list"
    {
        (Get-ChildItem "$configFolder/*.jsonc" | Select-Object BaseName) | Where-Object {$_ -notmatch "config"}
    }
    "edit"
    {
        $editor = "vim"
        if($null -ne $env:EDITOR)
        {
            $editor = $env:EDITOR
        }

        if(Test-Path $pathFromThemeName)
        {
            &$editor $pathFromThemeName
        }
        else
        {
            &$editor $currentConfig
        }
    }
    "delete"
    {
        if(Test-Path $pathFromThemeName)
        {
            Remove-Item $pathFromThemeName
            Write-Host "Successfully removed theme '$name'."
        }else
        {
            $themeNotFound
        }
    }
    "slot"
    {
        #TODO: modular config with default in the base folder, then /slot1/, /slot2/ subfolders
    }
    ""
    {
        Get-Fastfetch
    }
    Default
    {
        $name = $operation
        $themeNotFound = "NOTE: '$name' couldn't be found in list of available themes."
        $pathFromThemeName = Join-Path $configFolder "/$name.jsonc"

        if(Test-Path $pathFromThemeName)
        {
            Remove-Item $currentConfig
            Copy-Item $pathFromThemeName $currentConfig
            Get-Fastfetch
        }
        else
        {
            $themeNotFound
        }
    }
}
