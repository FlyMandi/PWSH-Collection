Param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$name = "",
    [Parameter(Mandatory = $false, Position = 1)]
    [string]$timeString = "",
    [Parameter(Mandatory = $false, Position = 2)]
    [string]$path = "",
    [Parameter(Mandatory = $false, Position = 3)]
    [switch]$cancel = $false,
    [Parameter(Mandatory = $false, Position = 4)]
    [switch]$status = $false
)

if ($cancel -or $status){
    if ($name = ""){
        throw "No alarm name specified."
    }

    $formattedTime = (((Get-ScheduledTask -TaskName $name -Verbose | Select-Object *).Triggers).StartBoundary -replace ".*T" -replace "[+].*")
}

if ($cancel){
    Unregister-ScheduledTask -TaskName $name -Confirm:$false

    Write-Host "Alarm with name " -NoNewline
    Write-Host $name -BackgroundColor DarkCyan -NoNewline
    Write-Host " scheduled for " -NoNewline
    Write-Host $formattedTime -NoNewline
    Write-Host " cancelled." -ForegroundColor Red
}
elseIf($status){

    Write-Host "Alarm with name " -NoNewline
    Write-Host $name -BackgroundColor DarkCyan -NoNewline
    Write-Host " going off at " -NoNewline
    Write-Host $formattedTime -NoNewline
    Write-Host " today."
}
else{

#TODO: add error handling for trying to create an alarm that already exists, or deleting one that doesn't.

#TODO: parse alarm name from user input

    if (-Not (Test-Path $path)){
        throw "Not a valid filepath."
    }

    if ($timeString -match "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]:?[0-5]?[0-9]?$") {

        $_hours = $timeString.Substring(0,2)
        $_minutes = $timeString.Substring(3,2)
        
        if ($timeString -match "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$"){
            $_seconds = $timeString.Substring(6,2)
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

    Write-Host "Alarm with name '$name' set to go off at " -NoNewline
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

        Register-ScheduledTask -TaskName $name -InputObject $task
    }
    else{
        throw "mpvnet not installed."
    }

}
