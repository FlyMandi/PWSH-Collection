Param(
    [Parameter(Mandatory=$false,position=0)]
    [string]$operation,
    [Parameter(Mandatory=$false,position=1)]
    [int64]$time = 0,
    [string]$date = '',
    [switch]$convert = $false,
    [string]$mode
)

#TODO: take military time input (0530, 0030, 2359, etc)
#TODO: take 12h input (530AM, 1230AM, 1159PM, etc)
#TODO: take date input (05/12/2024), (6/12/2000), etc

[string]$nowRaw = Get-Date
[int64]$now = ([int64](Get-Date -UFormat %s))
[int64]$unix = 0

# use these values for 'unix discord -d yesterday -m r' or something like that
# example inputs:
# 'unix discord -d in5hr', 'unix discord -d in2d', 'unix discord -d yesterday -m shortdate'
# fallback disc timestamp mode = relative
[int64]$oneHour = 3600
[int64]$oneDay = 86400 
[int64]$oneWeek = 604800
[int64]$oneMonth = 2629743 
[int64]$oneYear = 31556926

function Set-Current{
    Write-Host "Writing unix time $now to clipboard. ($nowRaw)"
    Set-Clipboard -Value $now
}

function Set-Stamp($timeIn){
    switch($mode){
        {($_ -eq "r") -or ($_ -eq "relative")}      { $script:discordStamp = "<t:$timeIn`:R>" }
        {($_ -eq "lt") -or ($_ -eq "longtime")}     { $script:discordStamp = "<t:$timeIn`:T>" }
        {($_ -eq "st") -or ($_ -eq "shorttime")}    { $script:discordStamp = "<t:$timeIn`:t>" }
        {($_ -eq "ld") -or ($_ -eq "longdate")}     { $script:discordStamp = "<t:$timeIn`:D>" }
        {($_ -eq "sd") -or ($_ -eq "shortdate")}    { $script:discordStamp = "<t:$timeIn`:d>" }
        {($_ -eq "sf") -or ($_ -eq "shortfull")}    { $script:discordStamp = "<t:$timeIn`:f>" }
        {($_ -eq "lf") -or ($_ -eq "longfull")}     { $script:discordStamp = "<t:$timeIn`:F>" }
        Default                                     {
            $script:discordStamp = "<t:$timeIn>"
            $script:mode = "default"
        }
    }
}

switch($operation){
    "convert"{
        Write-Host "time to convert: $time"
        Get-Date -UnixTimeSeconds $time
    }
    "get"{
        if ($time -eq 0){
            Set-Current
        }
        else{
            # get unix timestamp from time & date specified
        }
    }
    "discord"{
        if ($time -ne 0){
            # set directly
            Write-Host "Writing discord timestamp for unix time '$time' to clipboard:`n" (Get-Date -UnixTimeSeconds $time)
            Set-Stamp $time
            Set-Clipboard -Value $discordStamp
            Write-host "Written $mode timestamp with: $discordStamp"
        }
        elseIf($date -ne ''){
            switch($date){
                "now"{
                    $unix = $now
                }
                "today"{
                    $unix = $now - ($now % $oneday) - (2 * $oneHour)
                }
                "midnight"{
                    $unix = $now - ($now % $oneday) - (2 * $oneHour) + $oneDay
                }
                "tomorrow"{
                    $unix = $now + $oneday
                }
                "yesterday"{
                    $unix = $now - $oneday
                }
                # regex recognize date & time{
                # 
                # }
                Default{
                    throw "Could not find date '$date'."
                }
            }
            Write-Host "Writing discord timestamp for '$date' to clipboard:" (Get-Date -UnixTimeSeconds $unix)
            Set-Stamp $unix
            Set-Clipboard -Value $discordStamp
            Write-host "Written $mode timestamp with: $discordStamp"
        }
        else{
            # fallback is current unix time
            Write-Host "Writing discord timestamp for current time to clipboard:" (Get-Date -UnixTimeSeconds $now)
            Set-Stamp $now
            Set-Clipboard -Value $discordStamp
            Write-host "Written $mode timestamp with: $discordStamp"
        }
    }
    Default{
        Set-Current
    }
}