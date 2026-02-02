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

function Test-IsConfigFileExtension{
    param(
        $extension
    )
    $listOfConfigFileExtensions = ".ini", ".xml", ".toml", ".yaml", ".txt", ".json", ".jslot"
    return $listOfConfigFileExtensions.Contains($extension)
}
Export-ModuleMember -Function Test-IsConfigFileExtension

function Get-LatestFileInFolderNoConfig{
    param(
        $path
    )

    [DateTime]$placeholderTime = "1/1/1800 00:00:00"

    [PsCustomObject]$result = @{ 
        FilePath = ''; 
        FileExtension = ''; 
        FileTime = $placeholderTime;
    }
    $current = $result
    $filesList = Get-ChildItem -LiteralPath $path -File -Recurse

    foreach($file in $filesList){
        $current = @{ FilePath = $file; FileExtension = $file.Extension; FileTime = [DateTime]$file.LastWriteTime }
        if(($current.FileTime -gt $result.FileTime) -And (-Not((Test-IsConfigFileExtension $current.FileExtension)))){
            $result.FilePath = $current.FilePath
            $result.FileExtension = $current.FileExtension
            $result.FileTime = $current.FileTime
        }
    }
    return $result
}
Export-ModuleMember -Function Get-LatestFileInFolderNoConfig
