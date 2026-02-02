Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$pkg,
    [Parameter(Mandatory=$false,Position=1)]
    [string]$reg
)
#TODO: find folder from app name given by package, -r is now fallback only
#TODO: verify if found folder is a valid path ($keypath) or ($keypath2)

$valueName = "DisplayVersion"
$pathSet = $false

If(-Not('' -eq $reg)){
    $app = $reg
    $pathSet = $true
    $keyPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\$reg"
    $keyPath2 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$reg"
}

if (-Not ($pathSet)){
    $appPattern = "Found (?<appName>.*) \[.*\]"
    (winget show $pkg | Where-Object{$_ -match "Found"}) -match $appPattern
    $app = $matches["appName"]

    $keyPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\$app"
    $keyPath2 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$app"
}

$pathValid = Test-Path $keyPath
$path2Valid = Test-Path $keyPath2

Write-Host "Trying to update the registry for '$app'.`n"

if ($pathValid){
    $truePath = $keyPath
    $oldVersion = (Get-Item -LiteralPath $truePath).GetValue($valueName)
} 
ElseIf ($path2Valid){
    $truePath = $keyPath2
    $oldVersion = (Get-Item -LiteralPath $truePath).GetValue($valueName)
} 
Else {
    throw "ERROR: Can't find a valid registry path."
}

Write-Host "Found registry key in $truePath"

# pull newest version number from winget
$newVersion = (winget show $pkg | FINDSTR "Version").Trim("Version: ")

if($oldVersion -eq $newVersion) {
    Write-Host "`nRegistry key DisplayVersion for $app is up-to-date."
}
ElseIf ($oldVersion -gt $newVersion){
    throw "ERROR: New version can't be lower than old version."
}
else {
    Set-ItemProperty -Path $truePath -Name $valueName -Value $newVersion
    # setVersion = the new, changed value
    $setVersion = (Get-Item -LiteralPath $truePath).GetValue($valueName)
    Write-Host "`n Updated registry key to reflect winget package newest version:`n    Outdated: $oldVersion`n    Now: $setVersion"
}
