param(
    $folder
)

$outdated = @()
$yearOld = (Get-Date).AddYears(-1)
$fiveYearsOld = (Get-Date).AddYears(-5)
$decadeOld = (Get-Date).AddYears(-10)

foreach ($subfolder in (Get-ChildItem $folder)){
   $current = [PSCustomObject]@{ Path = $subfolder; Time = (Get-LatestFileinFolderNoConfig $subfolder).Time }
   if ($current.Time -lt $yearOld){ $outdated += $current }
}

Write-Host $outdated


