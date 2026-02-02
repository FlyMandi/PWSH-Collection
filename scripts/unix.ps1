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

$nowRaw = Get-Date
$now = ([int64](Get-Date -UFormat %s))
# fallback for unix value is current time
$unix = $now

# use these values for 'unix discord -d yesterday -m r' or something like that
# example inputs:
# 'unix discord -t in5hr', 'unix discord -t in2d', 'unix discord -t yesterday -m shortdate'
# fallback disc timestamp mode = relative
$oneHour = 3600
$oneDay = 86400 
$oneWeek = 604800
$oneMonth = 2629743 
$oneYear = 31556926

switch($operation){
    "convert"{
        Write-Host "time to convert: $time"
        Get-Date -UnixTimeSeconds $time
    }
    "get"{
        if ($time -eq 0){
            Write-Host "Writing time $nowRaw ($now) to clipboard."
            Set-Clipboard -Value $now
        }
        else{
            # get unix timestamp from time & date specified
        }
    }
    "discord"{
        # only set time if time was input
        if ($time -ne 0){
            $unix = $time
        }
        # else, fallback to current unix time
        Write-Host "Writing time"(Get-Date -UnixTimeSeconds $unix)"to clipboard."
            switch($mode){
                {($_ -eq "r") -or ($_ -eq "relative")}      { $discordTime = "<t:$unix`:R>" }
                {($_ -eq "lt") -or ($_ -eq "longtime")}     { $discordTime = "<t:$unix`:T>" }
                {($_ -eq "st") -or ($_ -eq "shorttime")}    { $discordTime = "<t:$unix`:t>" }
                {($_ -eq "ld") -or ($_ -eq "longdate")}     { $discordTime = "<t:$unix`:D>" }
                {($_ -eq "sd") -or ($_ -eq "shortdate")}    { $discordTime = "<t:$unix`:d>" }
                {($_ -eq "sf") -or ($_ -eq "shortfull")}    { $discordTime = "<t:$unix`:f>" }
                {($_ -eq "lf") -or ($_ -eq "longfull")}     { $discordTime = "<t:$unix`:F>" }
                Default                                     { $discordTime = "<t:$unix>"    }
            }
            Write-host "Written timestamp with mode $m`: $discordTime"
            Set-Clipboard -Value $discordTime
    }
    Default{
        Write-Host "Writing time $nowRaw ($now) to clipboard."
        Set-Clipboard -Value $now
    }
}