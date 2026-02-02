Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$pkg,
    [Parameter(Mandatory=$false,Position=1)]
    [string]$reg
)

$valueName = "DisplayVersion"
$pathSet = $false

If(-Not('' -eq $reg)){
    # Set the folder name directly
    $app = $reg
    $pathSet = $true
    $keyPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\$reg"
    $keyPath2 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$reg"
}

try {
    if (-Not ($pathSet)){
        # try to derive key path from package info
        $app =(((winget show $pkg | FINDSTR "Found").Trim("Found ")) -replace('(\[.*)')).Trim()
        #search in registry from app name
        $keyPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\$app"
        $keyPath2 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$app"
    }

    # test validity of paths
    $pathValid = Test-Path $keyPath
    $path2Valid = Test-Path $keyPath2

    Write-Host "Trying to update the registry for '$app'.`n"
    Write-Host "'$keyPath':`nFound path: $pathValid`n`n'$keyPath2'`nFound path: $path2Valid`n`n"

    if ($pathValid){
        $truePath = $keyPath
        $oldVersion = (Get-Item -LiteralPath $truePath).GetValue($valueName)
    } ElseIf ($path2Valid){
        $truePath = $keyPath2
        $oldVersion = (Get-Item -LiteralPath $truePath).GetValue($valueName)
    } Else {
        throw "Can't find a valid registry path."
    }

    # pull newest version number from winget
    $newVersion = (winget show $pkg | FINDSTR "Version").Trim("Version: ")

    # if keypath doesn't exist, it doesn't exist.
    if (-Not ($pathValid) -and -Not($path2Valid)){
        throw "DisplayVersion registry key for $app does not exist."
    }
    ElseIf($oldVersion -eq $newVersion) {
        Write-Host "`nRegistry key DisplayVersion for $app is up-to-date."
    } 
    else {
        Set-ItemProperty -Path $truePath -Name $valueName -Value $newVersion
        # setVersion = the new, changed value
        $setVersion = (Get-Item -LiteralPath $truePath).GetValue($valueName)
        Write-Host "`n Updated registry key to reflect winget package newest version:
    Outdated: $oldVersion`n    Now: $setVersion"
    }
} 
catch {
    "No valid package name provided and/or no valid registry key found in folder."
}
