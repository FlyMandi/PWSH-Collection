$gameCount = 0
$fileCount = 0
$i = 0
$extensionPath = $null


function Test-HasCorrespondingJson{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $photo,
        [Parameter(Mandatory=$true,Position=1)]
        $gameJson
    )

    foreach($photoJson in $gameJson.Items){
        if(($photo.BaseName + $photo.Extension) -eq ($photoJson.Name)){ return $true }
    }
    return $false
}

function Remove-BackgroundChangerLeftovers{
    $backgroundChangerImageFolder = Join-Path $extensionPath "ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\Images"
    $backgroundChangerJsonPath = Join-Path $extensionPath "ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\BackgroundChanger"

    $backgroundChangerImageFolderList = Get-ChildItem $backgroundChangerImageFolder
    foreach($gameFolder in $backgroundChangerImageFolderList){

        $percentComplete = [math]::floor(($i / $backgroundChangerImageFolderList.Length) * 100)
        $progressParameters = @{
            Activity = "Scanning game with id " + $gameID
            Status = "Scanned $i of " + $backgroundChangerImageFolderList.Length
            PercentComplete = $percentComplete 
        }
        Write-Progress @progressParameters
        ++$i

        ++$gameCount
        $gameID = (Get-Item $gameFolder).BaseName
        $BCJson = "$backgroundChangerJsonPath\$gameID.json"
        

        if(-Not(Test-Path $BCJson)){
            $fileCount += (Get-ChildItem $gameFolder).count
            Remove-Item $gameFolder -Recurse
            Write-Host "    Removed leftover Folder (no corresponding BC {gameid}.json): " -ForegroundColor Green -NoNewline
            Write-Host $gameFolder
            continue;
        }

        $BCPhotos = Get-ChildItem -File $gameFolder
        $BCPhotosJson = Get-Content -Raw $BCJson | ConvertFrom-Json
        
        foreach($photo in $BCPhotos){
            if(-Not(Test-HasCorrespondingJson $photo $BCPhotosJson)){
                ++$fileCount
                Remove-Item $photo
                Write-Host "    Removed leftover Photo (no BC {gameid}.json Name entry): " -ForegroundColor Green -NoNewline
                Write-Host $photo
            }
        }
    }
}

function Remove-CoverStyleDuplicates{
    #TODO: if there are 2 images with the same name but different extensions, delete the older one
}

if(Test-Path (Join-Path $env:LOCALAPPDATA "Playnite\ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a")){ 
    $extensionPath = Join-Path $env:LOCALAPPDATA "\Playnite\" 
}
elseif(Test-Path(Join-Path $env:USERPROFILE "\scoop\persist\playnite\ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a")){ 
    $extensionPath = Join-Path $env:USERPROFILE "\scoop\persist\playnite"
}

if($null -eq $extensionPath){
    Write-Host "ERROR: couldn't find a BackgroundChanger ExtensionsData folder in any of the typical Playnite install locations. Please provide the full path to " -NoNewLine
    Write-Host "..\Playnite\ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a"
    Read-Host $extensionPath
    if(-Not(Test-Path $extensionPath)){ Write-Host "ERROR: the path you provided is invalid. Skipping BackgroundChanger..."}
}else{
    Remove-BackgroundChangerLeftovers 
}

#TODO: find cover styles folder

Write-Host "`nSummary: Scanned " -NoNewline
Write-Host $gameCount -ForegroundColor Blue -NoNewline
Write-Host " Folders and removed " -NoNewline
Write-Host $fileCount -ForegroundColor Green -NoNewline
Write-Host " Images that were no longer used." -NoNewline
