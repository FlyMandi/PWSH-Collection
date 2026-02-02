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
}

try {
    if (-Not ($pathSet)){
        # try to derive key path from package info
        $app =(((winget show $pkg | FINDSTR "Found").Trim("Found ")) -replace('(\[.*)')).Trim()
        #search in registry from app name
        $keyPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\$app"
    }

    Write-Host "Trying to update the registry for '$app'."
    Write-Host "'$keyPath'"

    # old version is the one installed
    $oldVersion = (Get-Item -LiteralPath $keyPath).GetValue($valueName)
    # pull newest version number from winget
    $newVersion = (winget show $pkg | FINDSTR "Version").Trim("Version: ")

    if ($null -eq $oldVersion){
        throw "DisplayVersion registry key for $app does not exist."
    }
    ElseIf($oldVersion -eq $newVersion) {
        Write-Host "`nRegistry key DisplayVersion for $app is up-to-date."
    } 
    else {
        Set-ItemProperty -Path $keyPath -Name $valueName -Value $newVersion
        # setVersion = the new, changed value
        $setVersion = (Get-Item -LiteralPath $keyPath).GetValue($valueName)
        Write-Host "`n Updated registry key to reflect winget package newest version:
        Outdated: $oldVersion`n    Now: $setVersion"
    }
} 
catch {
    "No valid package name provided or no valid registry folder found from package name."
}
