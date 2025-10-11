function Test-IsNotWinTerm
{
    $process = Get-CimInstance -Query "SELECT * from Win32_Process WHERE name LIKE 'WindowsTerminal%'"
    return($null -eq $process)
}
Set-Alias tinwt Test-IsNotWinTerm
Export-ModuleMember -Function Test-IsNotWinTerm -Alias tinwt

function Get-NewMachinePath
{
    $temp = $env:Path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    if(-Not($temp.Length) -eq ($env:Path.Length))
    {
        Write-Host "`nEnvironment variables updated!" -ForegroundColor Green
    }
}
Export-ModuleMember -Function Get-NewMachinePath

function Add-ToMachinePath
{
    Param([string]$toAdd)

    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$toAdd", [System.EnvironmentVariableTarget]::Machine);
}
Export-ModuleMember -Function Add-ToMachinePath
