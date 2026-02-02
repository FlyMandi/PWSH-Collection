Param(
    [Parameter(Mandatory=$false,position=0)]
    [string]$operation,
    [Parameter(Mandatory=$false,position=1)]
    [int64]$time = 0,
    [switch]$convert = $false,
    [string]$m
)

#TODO: take military time input (0530, 0030, 2359, etc)
#TOD: take date input (05/12/2024), (6/12/2000), etc

$nowRaw = Get-Date
$now = ([int64](Get-Date -UFormat %s))

switch($operation){
    "convert"{
        Write-Host "time to convert: $time"
        Get-Date -UnixTimeSeconds $time
    }
    "get"{
        Write-Host "Writing time $nowRaw ($now) to clipboard."
        Set-Clipboard -Value $now
    }
    "discord"{
        Write-Host "Writing time $nowRaw to clipboard."
        switch($m){
            {($_ -eq "r") -or ($_ -eq "relative")}      { $discordTime = "<t:$now`:R>" }
            {($_ -eq "lt") -or ($_ -eq "longtime")}     { $discordTime = "<t:$now`:T>" }
            {($_ -eq "st") -or ($_ -eq "shorttime")}    { $discordTime = "<t:$now`:t>" }
            {($_ -eq "ld") -or ($_ -eq "longdate")}     { $discordTime = "<t:$now`:D>" }
            {($_ -eq "sd") -or ($_ -eq "shortdate")}    { $discordTime = "<t:$now`:d>" }
            {($_ -eq "sf") -or ($_ -eq "shortfull")}    { $discordTime = "<t:$now`:f>" }
            {($_ -eq "lf") -or ($_ -eq "longfull")}     { $discordTime = "<t:$now`:F>" }
            Default                                     { $discordTime = "<t:$now>"    }
        }
        Write-host "Written timestamp with mode $m`: $discordTime"
        Set-Clipboard -Value $discordTime
    }
    Default{
        Write-Host "Writing time $nowRaw ($now) to clipboard."
        Set-Clipboard -Value $now
    }
}