function Set-LocalCompileCommands{
    param(
        $CCJ,
        $destFolderList
    )
    if(-Not(Test-Path $CCJ)){
        Write-Host "ERROR: compile_commands.json could not be found." -ForegroundColor Red
        Write-Host "given path: $CCJ"
        return;
    }
    #TODO: 
    # read file
    # parse include filepaths
    # edit only relative filepaths.
    # set them based on diff, foreach path in destFolderList
}
Export-ModuleMember -Function Set-LocalCompileCommands
