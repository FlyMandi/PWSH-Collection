function Test-EmailAddress{
    param ( $userEmail )
    return ( $userEmail -match "[a-zA-Z0-9._%±]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}" )
}
Set-Alias testmail Test-EmailAddress
Export-ModuleMember -Function Test-EmailAddress -Alias testmail

function Test-GitUserName{
    $gitUserName = &git config get user.name
    if([string]::IsNullOrEmpty($gitUserName)){
        Write-Host "No git user.name found, please enter one now: " -NoNewline
        $gitUserName = Read-Host
        if([string]::IsNullOrEmpty($gitUserName)) {
            Write-Host "ERROR: please enter username." -ForegroundColor Red
            break
        }
        &git config set user.name $gitUserName
    }
}
Export-ModuleMember -Function Test-GitUserName

function Test-GitUserEmail{
    $gitUserEmail = &git config get user.email
    if([string]::IsNullOrEmpty($gitUserEmail)){
        Write-Host "No git user.email found, please enter one now: " -NoNewline
        $gitUserEmail = Read-Host
        if(-Not(Test-EmailAddress $gitUserEmail)) {
            Write-Host "ERROR: please enter a valid e-mail address." -ForegroundColor Red
            break
        }
        &git config set user.email $gitUserEmail
    }
}
Export-ModuleMember -Function Test-GitUserEmail
