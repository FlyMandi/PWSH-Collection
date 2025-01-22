param(
    $folder,
    $date = (Get-Date).AddYears(-6)
)

$count = 0
$i = 0
$folderList = Get-ChildItem $folder -Directory
$length = $folderList.Length

$host.privatedata.ProgressForegroundColor = 'Blue'
$host.privatedata.ProgressBackgroundColor = $Host.UI.RawUI.BackgroundColor;

foreach($subfolder in $folderList){
    [PsCustomObject]$latestFile = Get-LatestFileInFolderNoConfig $subfolder 

    #TODO: use this to make choices

    if('' -eq $latestFile.Path) { continue; } 

    $current = [PSCustomObject]@{ Path = $subfolder; Time = $latestFile.FileTime }

    $percentComplete = [math]::floor(($i / $length) * 100)
    $progressParameters = @{
        Activity = 'Scan in Progress...'
        Status = "Scanned $i of $length, total progress: $percentComplete%"
        PercentComplete = $percentComplete 
    }

    if($current.Time -lt $date){
        $count += 1
        Write-Host "`nWARNING: " -NoNewline -ForegroundColor Red
        Write-Host "found likely outdated mod: "
        Write-Host "    Name: " $current.FilePath.BaseName
        Write-Host "    Path: " $current.FilePath
        Write-Host "    Last Updated: " -NoNewline
        Write-Host $current.FileTime -ForegroundColor Red
        Write-Host ""
    }

    Write-Progress @progressParameters
    ++$i 
}
#TODO: add 6 months, 1 year, 2 years and 3+ years back, separate them into categories

#TODO: add list of exclusions of old mods that STILL work on 1.6.1170

#TODO: read from MO2 .csv
    #add correct sorting via csv
    #add current separator progress
    #add skipping of disabled mods in current profile

$exclusionList = ''

#TODO: change the summary to distinct between different levels of outdated
Write-Host "`nScan Complete.`n"
if($count -gt 0){ Write-Host "Summary: found " $count " outdated mods (no changes except config since" $date" or earlier): please check log above." -ForegroundColor Red}
else{ Write-Host "No outdated mods could be found. Splendid!" -ForegroundColor Green }
