Param(
    [Parameter(Mandatory=$true,position=0)]
    [string]$operation,
    [Parameter(Mandatory=$false,position=1)]
    [DateTime]$date,
    [string]$mode
)

[DateTime]$nowRaw = Get-Date
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
    Set-Clipboard -Value $now
    Write-Host "Written unix time $now to clipboard. ($nowRaw)"
}

function Set-Stamp($timeIn){
    switch($mode){
        {($_ -eq "r")  -or ($_ -eq "relative")}     { return "<t:$timeIn`:R>" }
        {($_ -eq "lt") -or ($_ -eq "longtime")}     { return "<t:$timeIn`:T>" }
        {($_ -eq "st") -or ($_ -eq "shorttime")}    { return "<t:$timeIn`:t>" }
        {($_ -eq "ld") -or ($_ -eq "longdate")}     { return "<t:$timeIn`:D>" }
        {($_ -eq "sd") -or ($_ -eq "shortdate")}    { return "<t:$timeIn`:d>" }
        {($_ -eq "sf") -or ($_ -eq "shortfull")}    { return "<t:$timeIn`:f>" }
        {($_ -eq "lf") -or ($_ -eq "longfull")}     { return "<t:$timeIn`:F>" }
        Default{
            $script:mode = "default"
            return "<t:$timeIn>"
        }
    }
}

switch($operation){
    "convert"{
        Write-Host "time to convert: $date"
        Get-Date -UnixTimeSeconds $date
    }
    "get"{
        if ($null -eq $date){
            Set-Current
        }
        else{
            Set-Clipboard -Value (Get-Date -Date $date -UFormat %s)
            Write-Host "Written unix time $date to clipboard. ($date)"
        }
    }
    #FIXME: weird format and usage
    "discord"{
        $timeToStamp = Get-Date -UnixTimeSeconds $date
        if ($timeToStamp -ne 0){
            Write-Host "Writing discord timestamp for unix time '$timeToStamp' to clipboard:`n" (Get-Date -UnixTimeSeconds $timeToStamp)
            $discordStamp = Set-Stamp $timeToStamp
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
            Write-Host "Writing discord timestamp for current time to clipboard:" (Get-Date -UnixTimeSeconds $now)
            Set-Stamp $now
            Set-Clipboard -Value $discordStamp
            Write-host "Written $mode timestamp with: $discordStamp"
        }
    }
}
