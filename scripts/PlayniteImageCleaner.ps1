$script:BCfileCount = 0
$script:CSfileCount = 0
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

    $i = 0
    $backgroundChangerImageFolder = Join-Path $extensionPath "\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\Images"
    $backgroundChangerJsonPath = Join-Path $extensionPath "\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\BackgroundChanger"
    $backgroundChangerImageFolderList = Get-ChildItem $backgroundChangerImageFolder

    foreach($gameFolder in $backgroundChangerImageFolderList){

        $percentComplete = [math]::floor(($i / $backgroundChangerImageFolderList.Length) * 100)
        $progressParameters = @{
            Activity = "Scanning BC game with id " + $gameID
            Status = "Scanned $i of " + $backgroundChangerImageFolderList.Length
            PercentComplete = $percentComplete 
        }
        Write-Progress @progressParameters
        ++$i

        $gameID = (Get-Item $gameFolder).BaseName
        $BCJson = "$backgroundChangerJsonPath\$gameID.json"

        if(-Not(Test-Path $BCJson)){
            $script:BCfileCount += (Get-ChildItem $gameFolder).count
            Remove-Item $gameFolder -Recurse
            #Write-Host "    Removed leftover Folder (no corresponding BC {gameid}.json): " -ForegroundColor Red -NoNewline
            #Write-Host $gameFolder
            continue;
        }

        $BCPhotos = Get-ChildItem -File $gameFolder
        $BCPhotosJson = Get-Content -Raw $BCJson | ConvertFrom-Json
        
        foreach($photo in $BCPhotos){
            if(-Not(Test-HasCorrespondingJson $photo $BCPhotosJson)){
                ++$script:BCfileCount
                Remove-Item $photo
                #Write-Host "    Removed leftover Photo (no BC {gameid}.json Name entry): " -ForegroundColor Red -NoNewline
                #Write-Host $photo
            }
        }
    }
}

function Remove-DuplicateCoversInFolder{
    param( $path )

    $imageFullList = Get-ChildItem $path
    $imageNameList = ""
    foreach($new in $imageFullList){
        if($imageNameList.Contains($new.BaseName)){
            foreach($cover in $imageFullList){
                if(($new.BaseName -eq $cover.BaseName) -and ($new -ne $cover)){
                    if($new.LastWriteTime -ge $cover.LastWriteTime){
                        if(Test-Path $cover){ 
                            ++$script:CSfileCount
                            Remove-Item $cover
                            #Write-Host "    Removed (older) duplicate cover: " -ForegroundColor DarkRed -NoNewline
                            #Write-Host $cover
                        }
                    }elseIf(Test-Path $new){
                        ++$script:CSfileCount
                        Remove-Item $new
                        #Write-Host "    Removed (older) duplicate cover: " -ForegroundColor DarkRed -NoNewline
                        #Write-Host $new

                        $new = $cover
                    }
                }
            }
        }else{
            $imageNameList += $new.BaseName
        }
    }
}

function Remove-DuplicatesInSlot{
    param( $path )

    $i = 0

    $CSplatformFolderList = Get-ChildItem -Directory $path
    foreach($platform in $CSplatformFolderList){

        $percentComplete = [math]::floor(($i / $CSplatformFolderList.Length) * 100)
        $progressParameters = @{
            Activity = "Scanning CS platform in slot: " + $path.BaseName
            Status = "Scanned $i of " + $CSplatformFolderList.Length
            PercentComplete = $percentComplete
        }
        Write-Progress @progressParameters
        ++$i

        if(($platform.BaseName -eq "gameid") -or ($platform.BaseName -eq "special characters")){
            Remove-DuplicatesInSlot $platform
        }else{
            Remove-DuplicateCoversInFolder $platform
        }
    }
}

function Remove-CoverInSlotIfNoEquivalent{
    param( $path )

    if($path.BaseName -ne "original"){ throw "ERROR: trying to run equivalent removal on slot other than original: $path" }
   
    $rawList = Get-ChildItem -File -Recurse $path
    $slotFolder = Get-ChildItem $path.parent | Where-Object {$_ -NotMatch "original"}

    $i = 0

    foreach($image in $rawList){
        $percentComplete = [math]::floor(($i / $rawList.Length) * 100)
        $progressParameters = @{
            Activity = "Scanning CS original covers for duplicates: "
            Status = "Scanned $i of " + $rawList.Length
            PercentComplete = $percentComplete
        }
        Write-Progress @progressParameters
        ++$i

        $hasNoEquivalent = $true
        $file = $image
        $fileWithoutExtension = Join-Path $file.DirectoryName $file.BaseName
        $fileWithoutExtensionRelative = [System.IO.Path]::GetRelativePath($path, $fileWithoutExtension)

        foreach($slot in $slotFolder){
            $check = Join-Path -PATH $slot -ChildPath $fileWithoutExtensionRelative
            if(Test-Path "$check*"){ $hasNoEquivalent = $false; continue; }
        }

        if($hasNoEquivalent){
            Remove-Item $image
            ++$script:CSfileCount
            #Write-Host "    Removed unnecessarily saved cover: " -ForegroundColor DarkRed -NoNewline
            #Write-Host $image
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
        if($slot.BaseName -eq "original"){ Remove-CoverInSlotIfNoEquivalent $slot }
    }
}

Remove-BackgroundChangerLeftovers
Remove-CoverStyleDuplicates

Write-Host "Summary: Removed " -NoNewline
Write-Host $script:BCfileCount -ForegroundColor Red -NoNewline
Write-Host " unused images and " -NoNewline
Write-Host $script:CSfileCount -ForegroundColor DarkRed -NoNewline
Write-Host " duplicates."
