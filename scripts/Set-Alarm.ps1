Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$alarmTimeString = "",
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$path
)

#TODO: run this only if prompted by user to do so
# Unregister-ScheduledTask -TaskName 'ALARM' -Confirm:$false

#TODO: add error handling for trying to create an alarm that already exists, or deleting one that doesn't.

#TODO: parse alarm name from user input

if (-Not (Test-Path $path)){
    throw "Not a valid filepath."
}

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

Write-Host "alarm set to go off at " -NoNewline
Write-Host $alarmTime -NoNewline -BackgroundColor Green
Write-Host ", queued to play " -NoNewline
Write-Host $fileName -BackgroundColor Cyan -NoNewline


if (Get-Command mpvnet -errorAction SilentlyContinue){
    $params = '--really-quiet', '--title=ALARM', '--fs', '--keep-open=no', '--loop-file=inf' 

#FIXME: mpvnet not executing properly
    $action = New-ScheduledTaskAction -Execute "mpvnet" -Argument "$params $path"
    $trigger = New-ScheduledTaskTrigger -Once -At $alarmTime
    $settings = New-ScheduledTaskSettingsSet -WakeToRun
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings

    Register-ScheduledTask -TaskName 'ALARM' -InputObject $task
}
else{
    throw "mpvnet not installed."
}
