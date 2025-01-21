function Test-LayeredFolder{
    param( $folder )
    $childFolder = Get-ChildItem $folder
    return (($childFolder.count -eq 1) -And ((Get-ChildItem $childFolder).count -gt 0))
}
Set-Alias tlf Test-LayeredFolder
Export-ModuleMember -Function Test-LayeredFolder -Alias tlf

function Remove-LayeredFolderLayers{
    param ( $folder )
    $childFolder = Get-ChildItem $folder

    while (Test-LayeredFolder $folder){
        Move-Item "$childFolder\*.*" -Destination $folder -Force
        Remove-Item $childFolder -Recurse -Force
    }
}
Set-Alias rlfl Remove-LayeredFolderLayers
Export-ModuleMember -Function Remove-LayeredFolderLayers -Alias rlfl

function Push-ChangedFiles{
    param(
        $sourceFolder,
        $destFolder
    )
    if ([string]::IsNullOrEmpty($sourceFolder)){ 
        Write-Host "ERROR: source folder is an empty path."
        break
    }
    if ([string]::IsNullOrEmpty($destFolder)){ 
        Write-Host "ERROR: destination folder is an empty path."
        break
    }

    $sourceFileList = Get-ChildItem $sourceFolder -Recurse -File
    $destFileList = Get-ChildItem $destFolder -Recurse -File

    if($null -eq $sourceFileList){
        Write-Host "ERROR: No files to copy from." -ForegroundColor Red
        break
    }
    elseIf($null -eq $destFileList){
        Write-Host "ERROR: no files to compare against." -ForegroundColor Red
        break
    }
    else{
        $sourceTransformed = @()
        $destTransformed = @()

        foreach($file in $sourceFileList){
            $sourceTransformed += ([string]$file).Substring($sourceFolder.Length)
        }

        foreach($file in $destFileList){
            $destTransformed += ([string]$file).Substring($destFolder.Length)
        }

        $missingFiles = Compare-Object $sourceTransformed $destTransformed | Where-Object {$_.sideindicator -eq "<="}
    }

    foreach($file in $missingFiles){
        $fileInSource = (Join-Path -PATH $sourceFolder -ChildPath $file.InputObject)
        $fileInDest = (Join-Path -PATH $destFolder -ChildPath $file.InputObject)

        if (-Not(Test-Path (Split-Path $fileInDest))){&mkdir (Split-Path $fileInDest) | Out-Null}
        Copy-Item -Path $fileInSource -Destination $fileInDest
        Write-Host "Added Item: " -ForegroundColor White -NoNewline
        Write-Host $file.InputObject -ForegroundColor Cyan -BackgroundColor Black
        $script:filesAdded++
    }
    
    foreach($file in $sourceTransformed){
        $fileInSource = (Join-Path -PATH $sourceFolder -ChildPath $file)
        $fileInDest = (Join-Path -PATH $destFolder -ChildPath $file)

        if(-Not((Get-FileHash $fileInSource).Hash -eq (Get-FileHash $fileInDest).Hash)){ 
            Remove-Item $fileInDest -Force
            Copy-Item $fileInSource -Destination $fileInDest
            Write-Host "Updated Item: " -ForegroundColor White -NoNewline
            Write-Host $file -ForegroundColor Magenta -BackgroundColor Black
            $script:filesUpdated++
        }
    }
}
Export-ModuleMember -Function Push-ChangedFiles

function Test-IsConfigFileExtension{
    param(
        $extension
    )
    $listOfConfigFileExtensions = ".ini", ".xml", ".toml", ".yaml", ".txt", ".json"
    return $listOfConfigFileExtensions.Contains($extension)
}
Export-ModuleMember -Function Test-IsConfigFileExtension

function Get-LatestFileInFolderNoConfig{
    param(
        $path
    )

    if((Get-ChildItem $path).count -eq 0){
        $file = Get-Item $path
        return [PSCustomObject]@{ path = $path; extension = $file.Extension; time = $file.LastWriteTime }
    }
    else{
        [PsCustomObject]$result = @{ Path = ''; Extension = ''; Time = "5/27/1800"; }
        $filesList = Get-ChildItem $path -File -Recurse
        foreach($file in $filesList){
            [PsCustomObject]$current = @{ Path = $file; Extension = $file.Extension; Time = $file.LastWriteTime }
            if($current.Time -gt $result.Time && -Not((Test-IsConfigFileExtension $current.Extension))){
                $result = $current
            }
        }
        return $result
    }
}
Export-ModuleMember -Function Get-LatestFileInFolderNoConfig
