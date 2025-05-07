param(
    $date = (Get-Date).AddYears(-10)
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

$count = 0
$i = 0
$modList = Get-ChildItem $modsFolder -Directory
$nexusTime = [DateTime]"1/1/1800 00:00:00"

#FIXME: doesnt't work:
$host.privatedata.ProgressForegroundColor = 'Blue'
$host.privatedata.ProgressBackgroundColor = $Host.UI.RawUI.BackgroundColor;

#TODO: expand exclusion list
$exclusionList = @(
    "120 FPS User Interface",
    "3rd Person View During Alduin Attack on Helgen",
    "A Good Death - Old Orc's Various Opponents",
    ""
)

foreach($subfolder in $modList){
    $latestFile = Get-LatestFileInFolderNoConfig $subfolder

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


    if('' -eq $latestFile.FilePath){ continue; }
    
    if($exclusionList.Contains($current.ModPath.BaseName)){ continue; }
   
    #TODO:feature - switch($current.ModFramework)
        #warn about outdated frameworks:
        #FNIS
        #Nemesis
        #DAR
        #Anything not "NG" that has an "NG" equivalent
        #Anything "NG" that's borked -> like Fires Hurt
        #incorrect TK Dodge setup
        #Using MFAO and CFPAO together
        #Having mods share OAR priority
        #SPID & SkyPatcher for leveled lists

    #TODO: warn about not having run parallaxgen or CS enabled with PBR textures 

    #TODO: switch($current.ModFileType)
        #eval differently and warn differently based on mod type
        #ofc outdated .dll is bad D:
        #also different dates, 10 year old textures might be good, .esps nuh-uh

    #fallback:
    if($current.ModTime -lt $date){
        $count += 1
        Write-Host "`nWARNING: " -NoNewline -ForegroundColor Red
        Write-Host "found likely outdated mod: "
        Write-Host "    Name:           " $current.ModPath.BaseName
        Write-Host "    Path:           " $current.ModPath
        Write-Host "    Type:            Unknown"
        Write-Host "    Last Updated:    " -NoNewline
        Write-Host $current.ModTime -ForegroundColor Red
        Write-Host ""
    }

}

#TODO: add 6 months, 1 year, 2 years and 3+ years back, separate them into categories

#TODO: read from MO2 .csv
    #add correct sorting via csv
    #add current separator progress
    #add skipping of disabled mods in current profile

$exclusionList = ''

#TODO: change the summary to distinct between different levels of outdated
Write-Host "`nScan Complete.`n"
if($count -gt 0){ Write-Host "Summary: found " $count " outdated mods (no changes except config since" $date" or earlier): please check log above." -ForegroundColor Red}
else{ Write-Host "No outdated mods could be found. Splendid!" -ForegroundColor Green }
