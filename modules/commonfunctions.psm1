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

function Test-IsNotWinTerm{
    $process = Get-CimInstance -Query "SELECT * from Win32_Process WHERE name LIKE 'WindowsTerminal%'"
    return($null -eq $process)
}
Set-Alias tinwt Test-IsNotWinTerm
Export-ModuleMember -Function Test-IsNotWinTerm -Alias tinwt

function Test-EmailAddress{
    param ( $userEmail )
    return ( $userEmail -match "[a-zA-Z0-9._%±]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}" )
}
Set-Alias testmail Test-EmailAddress
Export-ModuleMember -Function Test-EmailAddress -Alias testmail
