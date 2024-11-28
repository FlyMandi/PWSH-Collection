Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [int]$alarmTime = -1,
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$path
)

#TODO: normalize alarmTime to seconds

#TODO: get chopped off path name (just filename)
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($path)

#TODO: normalize alarmTime to readable time string
$readableTime = "3 minutes 10 seconds"


Write-Host "alarm set to go off in " -NoNewline
Write-Host $readableTime -NoNewline -BackgroundColor Green
Write-Host ", queued to play " -NoNewline
Write-Host $fileName -BackgroundColor Cyan -NoNewline

