$BCfileCount = 0
$CSfileCount = 0
$i = 0
$extensionPath = $null
$coverStylesBackupFolder = $null

$ERRpathInvalid = "ERROR: The path you have provided is invalid, aborted."
$PROprovidePath = "Please provide the path to yours or skip by typing `"skip`":"

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
    if(Test-Path (Join-Path $env:LOCALAPPDATA "Playnite\ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a")){ 
        $extensionPath = Join-Path $env:LOCALAPPDATA "\Playnite\ExtensionsData\" 
    }elseif(Test-Path(Join-Path $env:USERPROFILE "\scoop\persist\playnite\ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a")){ 
        $extensionPath = Join-Path $env:USERPROFILE "\scoop\persist\playnite\ExtensionsData\"
    }else{
        Write-Host "Couldn't find an ExtensionsData folder in any of the typical Playnite install locations. $PROprovidePath" -NoNewLine
        Write-Host "..\Playnite\ExtensionsData\"
        Read-Host $extensionPath
        if("skip" -eq $extensionPath){
            Write-Host "Skipped BackgroundChanger folder."
            return
        }elseIf(-Not(Test-Path $extensionPath)){ throw $ERRpathInvalid}
    }

    $backgroundChangerImageFolder = Join-Path $extensionPath "\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\Images"
    $backgroundChangerJsonPath = Join-Path $extensionPath "\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\BackgroundChanger"
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

        $gameID = (Get-Item $gameFolder).BaseName
        $BCJson = "$backgroundChangerJsonPath\$gameID.json"
        

        if(-Not(Test-Path $BCJson)){
            $BCfileCount += (Get-ChildItem $gameFolder).count
            Remove-Item $gameFolder -Recurse
            Write-Host "    Removed leftover Folder (no corresponding BC {gameid}.json): " -ForegroundColor Green -NoNewline
            Write-Host $gameFolder
            continue;
        }

        $BCPhotos = Get-ChildItem -File $gameFolder
        $BCPhotosJson = Get-Content -Raw $BCJson | ConvertFrom-Json
        
        foreach($photo in $BCPhotos){
            if(-Not(Test-HasCorrespondingJson $photo $BCPhotosJson)){
                ++$BCfileCount
                Remove-Item $photo
                Write-Host "    Removed leftover Photo (no BC {gameid}.json Name entry): " -ForegroundColor Green -NoNewline
                Write-Host $photo
            }
        }
    }
}

function Remove-DuplicatesInSlot{
    param( $path )

    foreach($platform in (Get-ChildItem -Directory $path)){
        if(($platform.BaseName -eq "gameid") -or ($platform.BaseName -eq "special characters")){
            Remove-DuplicatesInSlot $platform
        }else{
            #TODO: actually do the thing    
        }
    }
}

function Remove-CoverStyleDuplicates{
    $coverStylesBackupFolder = "C:\Cover Styles\Backup\"
    if(-Not(Test-Path $coverStylesBackupFolder)){
        Write-Host "No Cover Styles folder found. $PROprovidePath"
        Write-Host "..\Cover Styles\Backup\"
        Read-Host $coverStylesBackupFolder
        if("skip" -eq $coverStylesBackupFolder){
            Write-Host "Skipped Cover Styles folder."
            return
        }elseIf(-Not(Test-Path $coverStylesBackupFolder)){
            throw $ERRpathInvalid
        }else{ Remove-CoverStyleDuplicates $coverStylesBackupFolder }
    }

    foreach($slot in (Get-ChildItem -Directory $coverStylesBackupFolder)){
        Remove-DuplicatesInSlot $slot
    }
}

Remove-BackgroundChangerLeftovers
Remove-CoverStyleDuplicates

Write-Host "`nSummary: Removed " -NoNewline
Write-Host $BCfileCount -ForegroundColor Green -NoNewline
Write-Host " unused images and " -NoNewline
Write-Host $CSfileCount -ForegroundColor Blue -NoNewline
Write-Host " duplicates."
