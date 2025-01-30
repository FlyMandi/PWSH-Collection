$extensionPath = $null
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
    if(-Not(Test-Path $extensionPath)){ throw: "ERROR: the path you provided is invalid." }
}

$backgroundChangerImageFolder = Join-Path $extensionPath "ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\Images"

$backgroundChangerJsonPath = Join-Path $extensionPath "ExtensionsData\3afdd02b-db6c-4b60-8faa-2971d6dfad2a\BackgroundChanger"

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

foreach($gameFolder in (Get-ChildItem $backgroundChangerImageFolder)){
    $gameID = (Get-Item $gameFolder).BaseName
    $BCJson = "$backgroundChangerJsonPath\$gameID.json"
    
    Write-Host "Scanning Game with id $gameID..."

    if(-Not(Test-Path $BCJson)){
        Remove-Item $gameFolder -Recurse
        Write-Host "    Removed leftover Folder (no corresponding .json): " -ForegroundColor Red -NoNewline
        Write-Host $gameFolder
        continue;
    }

    $BCPhotos = Get-ChildItem -File $gameFolder
    $BCPhotosJson = Get-Content -Raw $BCJson | ConvertFrom-Json
    
    foreach($photo in $BCPhotos){
        if(-Not(Test-HasCorrespondingJson $photo $BCPhotosJson)){
            Remove-Item $photo
            Write-Host "    Removed leftover Photo (no .json Name entry): " -ForegroundColor Red -NoNewline
            Write-Host $photo
        }
    }
}
