param(
    $date = (Get-Date).AddYears(-8),
    $bigESPSize = 15000000
)

$modsPattern = "ModOrganizer\Skyrim\Mods"
$modsFolder = Join-Path "$env:LOCALAPPDATA" $modsPattern
 
if(-Not(Test-Path $modsFolder)){
    foreach($drive in (Get-PSDrive -PSProvider 'FileSystem')){
        if(Test-Path (Join-Path $drive.Root $modsPattern)){
            $modsFolder = Join-Path $drive.Root $modsPattern
        }
    }

    while(-Not(Test-Path $modsFolder)){
        Write-Host "Please provide a valid path to your MO2 skyrim mods folder:"
        $modsFolder = Read-Host
    }
}    

$bigESPs = @()
$outdatedCount = 0
$i = 0
$modList = Get-ChildItem $modsFolder -Directory
$nexusTime = [DateTime]"1/1/1800 00:00:00"

#FIXME: doesnt't work:
$host.privatedata.ProgressForegroundColor = 'Blue'
$host.privatedata.ProgressBackgroundColor = $Host.UI.RawUI.BackgroundColor;

$exclusionList = @(
    "cleaned CCAE",
    "120 FPS User Interface",
    "3rd Person View During Alduin Attack on Helgen",
    "A Good Death - Old Orc's Various Opponents",
    "Blended Roads - ESP only",
    "Fires Hurt SE",
    "Trainwreck - A Crash Logger",
    "Jaxonz Renamer",
    "Realistic Conversations",
    "unofficial skyrim special edition patch",
    "Sea of Spirits"
)

#TODO: implement some "don't flag this if an update is installed on top" kinda deal.
# $exclusionIfUpdated = @(
#     "Exchange Currency SE",
#     "Frostfall 3.4.1 SE Release",
#     "Relationship Dialogue Overhaul",
#     "Lifelike Idle Animations by HHaleyy for SE"
# )

foreach($subfolder in $modList){
    $latestFile = Get-LatestFileInFolderNoConfig $subfolder
    $pluginList = Get-ChildItem $subfolder -File | Where-Object {$_ -match ".esp|.esm|.esl"}

    #TODO: read lastNexusUpdate in MO2 meta.ini if present
    #$nexusTime = 
    $current = [PSCustomObject]@{ 
        ModPath = $subfolder; 
        ModTime = $latestFile.FileTime; 
        NexusTime = $nexusTime; 
        ModFileType = Get-SkyrimModType $subfolder; 
        ModFramework = Get-SkyrimModFramework $subfolder;
    }

    $percentComplete = [math]::floor(($i / $modList.Length) * 100)
    $progressParameters = @{
        Activity = 'Scan in Progress...'
        Status = "Scanned $i of " + $modList.Length + ", total progress: $percentComplete%"
        PercentComplete = $percentComplete 
    }
    
    Write-Progress @progressParameters
    ++$i 

    if('' -eq $latestFile.FilePath){ 
        continue; 
    }
    
    if($exclusionList.Contains($current.ModPath.BaseName)){ 
        continue; 
    }

    #TODO: switch($current.ModFileType)
        #eval differently and warn differently based on mod type
        #ofc outdated .dll is bad D:
        #also different dates, 10 year old textures might be good, .esps nuh-uh

    #fallback:
    if($current.ModTime -lt $date){
        $outdatedCount += 1
        Write-Host "`nWARNING: " -NoNewline -ForegroundColor Red
        Write-Host "found likely outdated mod: "
        Write-Host "    Name:           " $current.ModPath.BaseName
        Write-Host "    Path:           " $current.ModPath
        Write-Host "    Type:            Unknown"
        Write-Host "    Last Updated:    " -NoNewline
        Write-Host $current.ModTime -ForegroundColor Red
        Write-Host ""
    }
    
    foreach($plugin in $pluginList){
        if($plugin.Length -gt $bigESPSize){
        $bigESPs += $plugin
        Write-Host "`nWARNING: " -NoNewline -ForegroundColor Yellow
        Write-Host "found large Plugin: "
        Write-Host "    Name:           " $plugin.BaseName
        Write-Host "    Path:           " $plugin
        Write-Host "    Size:            " -NoNewline
        Write-Host ([math]::Truncate($plugin.Length / 1MB)) -NoNewline -ForegroundColor Yellow
        Write-Host " MB`n" -ForegroundColor Yellow
        }
    }
}

#TODO: add 6 months, 1 year, 2 years and 3+ years back, separate them into categories

#TODO: read from MO2 .csv
    #add correct sorting via csv
    #add current separator progress
    #add skipping of disabled mods in current profile

$exclusionList = ''

#TODO: change the summary to distinct between different levels of outdated.
Write-Host "`nScan Complete.`n"
if($outdatedCount -gt 0){ 
    Write-Host "Summary:`n found $outdatedCount outdated mods (no changes except config since $date or earlier): please check log above." -ForegroundColor Red
}else{ 
    Write-Host "{No outdated mods could be found. Splendid!" -ForegroundColor Green 
}

if($bigESPs.Length -gt 0){
    Write-Host "Summary: found " $bigESPs.Length " large ESPs. Please check list of 10 biggest below and reconsider." -ForegroundColor Yellow
    for($j = 0; ($j -lt 10) -and ($j -lt $bigESPs.Length); ++$j){
        Write-Host $bigESPs[$j].BaseName -NoNewline
        Write-Host ", size: " -NoNewline
        Write-Host ([math]::Truncate($bigESPs[$j].Length / 1MB)) -NoNewline -ForegroundColor Yellow
        Write-Host " MB" -ForegroundColor Yellow
    }
}else{
    Write-Host "No particurlaly large ESPs found. Splendid!" -ForegroundColor Green
}
