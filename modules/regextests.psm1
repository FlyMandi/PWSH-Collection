function Test-EmailAddress{
    param ( $userEmail )
    return ( $userEmail -match "[a-zA-Z0-9._%±]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}" )
}
Set-Alias testmail Test-EmailAddress
Export-ModuleMember -Function Test-EmailAddress -Alias testmail
