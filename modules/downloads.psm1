function Get-Binary{
    Param(
        [Parameter(Position = 0, mandatory = $false)]
        $command,
        [Parameter(Position = 1, mandatory = $false)]
        $sourceRepo,
        [Parameter(Position = 2, mandatory = $false)]
        $namePattern,
        [Parameter(Position = 3, mandatory = $false)]
        [switch]$preRelease = $false,
        [Parameter(Position = 4, mandatory = $false)]
        [string]$override = $null
    )

    if(-Not(Get-Command $command -ErrorAction SilentlyContinue)){
        $libFolder = Join-Path -PATH $env:Repo -ChildPath "/lib/"
       
        if([string]::IsNullOrEmpty($override)){ $sourceURI = Get-GitLatestReleaseURI $sourceRepo -n $namePattern -preRelease $preRelease }
        else{ $sourceURI = $override }

        $zipFolderName = $(Split-Path -Path $sourceURI -Leaf)
        $tempZIP = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $zipFolderName 
        Invoke-WebRequest -Uri $sourceURI -Out $tempZIP
   
        if([string]::IsNullOrEmpty($sourceRepo)){ $destFolder = Join-Path $libFolder -ChildPath $zipFolderName }
        else { $destFolder = (Join-Path $libFolder -ChildPath $sourceRepo) }


        Expand-Archive -Path $tempZIP -DestinationPath $destFolder -Force
        Remove-Item $tempZIP -Force
        
        Remove-LayeredFolderLayers $destFolder

        $binFolder = (Join-Path -PATH $destFolder -ChildPath "\bin")

        if((Test-Path "$binFolder") -And -Not([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) -like "*$binFolder*")){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$binFolder",[EnvironmentVariableTarget]::User)       
            Write-Host "Added $binFolder to path!" -ForegroundColor Green
        }
        elseIf(-Not([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) -like "*$destFolder*")){
            [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$destFolder",[EnvironmentVariableTarget]::User)       
            Write-Host "Added $destFolder to path!" -ForegroundColor Green
        }

        Write-Host "$command successfully installed!" -ForegroundColor Green
    }
}
Export-ModuleMember -Function Get-Binary
