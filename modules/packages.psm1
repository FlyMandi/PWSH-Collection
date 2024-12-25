Function Get-FromPkgmgr{ 
    Param(
        $pkgmgr,
        $trgt,
        $override = $null
    )

    if (-Not (Get-Command $trgt -ErrorAction SilentlyContinue)){ 
        if(-Not ($null -eq $override)){ &$pkgmgr install $override }
        else { &$pkgmgr install $trgt }
    }
}
Export-ModuleMember -Function Get-FromPkgmgr

Function Get-ScoopPackage{
    Param(
        $scoopTrgt
    )
    $scoopDir = Join-Path $env:USERPROFILE -ChildPath "\scoop\apps\"

    if (-Not (Test-Path (Join-Path -Path $scoopDir -ChildPath $scoopTrgt))) { 
        &scoop install $scoopTrgt
    }
}
Export-ModuleMember -Function Get-ScoopPackage

function Get-GitLatestReleaseURI{
    param(
        [Parameter(Position = 0, mandatory = $false)]
        $sourceRepo,
        [Parameter(Position = 1, mandatory = $false)]
        $namePattern,
        [Parameter(Position = 2, mandatory = $false)]
        [switch]$preRelease = $false
    )

        if ($preRelease){
            Write-Host "Installing latest $namePattern release package from $sourceRepo..."
            $sourceURI = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/$sourceRepo/releases")[0].assets | Where-Object name -like $namePattern).browser_download_url
        }
        else{
            Write-Host "Installing latest $namePattern pre-release package from $sourceRepo..."
            $sourceURI = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/$sourceRepo/releases/latest").assets | Where-Object name -like $namePattern).browser_download_url
        }
    return $sourceURI
}
Export-ModuleMember -Function Get-GitLatestReleaseURI