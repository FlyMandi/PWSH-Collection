function Get-SkyrimModType{
    param(
        $path
    )
    $fileList = Get-ChildItem -LiteralPath $path -File -Recurse -Name
    $folderList = Get-ChildItem -LiteralPath $path -Directory -Recurse -Name

    [PSCustomObject]$mod = @{
        FileList = $fileList
        FolderList = $folderList
        ModType = ''
        ConfidenceScore = 0
    }
    #TODO: write logic
}
Export-ModuleMember -Function Get-SkyrimModType

function Get-SkyrimModFramework{
    param(
        $path
    )

}
Export-ModuleMember -Function Get-SkyrimModFramework
