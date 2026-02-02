Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$alarmTimeString = "",
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$path
)

if ($alarmTimeString -match "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]:?[0-5]?[0-9]?$") {

    $_hours = $alarmTimeString.Substring(0,2)
    $_minutes = $alarmTimeString.Substring(3,2)
    
    if ($alarmTimeString -match "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$"){
        $_seconds = $alarmTimeString.Substring(6,2)
        $alarmTimeTminus = New-TimeSpan -Hours $_hours -Minutes $_minutes -Seconds $_seconds
        $alarmTime = Get-Date -Hour $_hours -Minute $_minutes -Second $_seconds
    }
    else { 
        $alarmTimeTminus = New-TimeSpan -Hours $_hours -Minutes $_minutes  
        $alarmTime = Get-Date -Hour $_hours -Minute $_minutes
    }

    if ((Get-Date) -gt $alarmTime) {
        throw "Timestamp has already passed."
    }
}
else {
    throw "Not a valid time format."
}

$fileName = [System.IO.Path]::GetFileNameWithoutExtension($path)


#TODO: actually schedule to play the video or audio file


Write-Host "alarm set to go off at " -NoNewline
Write-Host $alarmTime -NoNewline -BackgroundColor Green
Write-Host ", queued to play " -NoNewline
Write-Host $fileName -BackgroundColor Cyan -NoNewline
