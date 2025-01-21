param(
    $folder,
    $date = (Get-Date).AddYears(-2)
)

$count = 0

foreach($subfolder in (Get-ChildItem $folder -Directory)){
    $current = [PSCustomObject]@{ Path = $subfolder; Time = (Get-LatestFileinFolderNoConfig $subfolder).Time }
    if($current.Time -lt $date){ 
        $count += 1
        Write-Host "`nWARNING: " -NoNewline -ForegroundColor Yellow
        Write-Host "found likely outdated mod: "
        Write-Host "    Name: " $current.Path.BaseName
        Write-Host "    Path: " $current.Path
        Write-Host "    Last Updated: " -NoNewline
        Write-Host $current.Time -ForegroundColor Yellow
    }
}
#TODO: add 6 months, 1 year, 2 years and 3+ years back, separate them into categories

#TODO: add list of exclusions of old mods that STILL work on 1.6.1170

#TODO: change the summary to distinct between different levels of outdated
Write-Host "`n  Scan Complete.`n"
if($count -gt 0){ Write-Host "Summary: found " $count " outdated mods (no changes except config since " $date"), please check log above." -ForegroundColor Red}
else{ Write-Host "No outdated mods could be found. Splendid!" -ForegroundColor Green }
