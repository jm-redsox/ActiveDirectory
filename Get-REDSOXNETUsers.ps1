Import-Module ActiveDirectory

# values to exclude
$ExcludeValues = @('Full Time','Part Time','Event Staff','Seasonal','ICS')

# store all users from ad db in a variable
$allUsers =  Get-ADUser -Filter "*" -Properties "DistinguishedName", "Enabled", "GivenName", "mail", "extensionAttribute1", "extensionAttribute1", "extensionAttribute2", "extensionAttribute3", "Name", "ObjectClass", "ObjectGUID", "SamAccountName", "SID", "Surname", "UserPrincipalName"

# extract specific attributes and hold them in a variable (array)
$results = @()
foreach ($user in $allUsers) {
    $results += [PSCustomObject]@{
        DisplayName         = $user.DisplayName
        DistinguishedName   = $user.DistinguishedName
        Enabled             = $user.Enabled
        Name                = $user.Name
        GivenName           = $user.GivenName
        Surname             = $user.Surname
        UserPrincipalName   = $user.UserPrincipalName
        mail                = $user.mail
        ExtensionAttribute1 = $user.ExtensionAttribute1
        ExtensionAttribute2 = $user.ExtensionAttribute2
        ExtensionAttribute3 = $user.ExtensionAttribute3
        SamAccountName      = $user.SamAccountName
    }
}

# filter out users based on the exclusion criteria
$filteredResults = $results | Where-Object {
    $_.ExtensionAttribute1 -notin $ExcludeValues -and
    $_.ExtensionAttribute2 -notin $ExcludeValues -and
    $_.ExtensionAttribute3 -notin $ExcludeValues
}
