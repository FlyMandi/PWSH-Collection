Function Remove-PlayniteDuplicateCoversInclusive{
    $scoopDir = Join-Path $env:USERPROFILE -ChildPath "\scoop\apps\"
    $playniteMetadataFolder = Join-Path $scoopDir "\playnite\current\library\files"

    foreach($game in (Get-ChildItem $playniteMetadataFolder)){
        $fileHash = ''
        $hashList = ''
        $duplicatehashList = ''
        foreach($file in (Get-ChildItem $game)){
            $fileHash = Get-FileHash $file
            if($hashList.Contains($fileHash.Hash)){ 
                    if(-Not($duplicatehashList.Contains($fileHash.Hash))){ $duplicateHashList += $fileHash.Hash }
                }
            else{$hashList += $fileHash.Hash}
        }
        foreach($file in (Get-ChildItem $game)){
            $fileHash = Get-FileHash $file
            if($duplicatehashList.Contains($fileHash.Hash)) { 
                Write-Host $fileHash.path -ForegroundColor Red
                Remove-Item $fileHash.path
            }
        }
    }
}
Export-ModuleMember -Function Remove-PlayniteDuplicateCoversInclusive
