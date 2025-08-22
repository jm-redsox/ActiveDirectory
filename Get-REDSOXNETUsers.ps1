Import-Module ActiveDirectory

$values = @('Full Time','Part Time','Event Staff','Seasonal','ICS')
$ldap   = "(|(extensionAttribute1=*)(extensionAttribute2=*)(extensionAttribute3=*))"

# We’ll also query a small set without presence filter to find those with no values at all.
# To keep it efficient, scope with -SearchBase if possible.

# 1) Pull users that have ANY of the attributes populated (presence)
$withAny =
Get-ADUser -LDAPFilter $ldap -Properties extensionAttribute1,extensionAttribute2,extensionAttribute3,DisplayName,SamAccountName,DistinguishedName,mail,Enabled

# 2) Build the “clean” set (none of the populated values are disallowed)
$resultsWithValues =
$withAny | ForEach-Object {
    $vals = @($_.extensionAttribute1,$_.extensionAttribute2,$_.extensionAttribute3) | Where-Object { $_ }
    $hasDisallowed = $vals | Where-Object { $_ -in $values } | Select-Object -First 1
    if (-not $hasDisallowed) {
        [PSCustomObject]@{
            DisplayName         = $_.DisplayName
            SamAccountName      = $_.SamAccountName
            DistinguishedName   = $_.DistinguishedName
            Mail                = $_.mail
            Enabled             = $_.Enabled
            ExtAttr1            = $_.extensionAttribute1
            ExtAttr2            = $_.extensionAttribute2
            ExtAttr3            = $_.extensionAttribute3
            ValuesPresent       = ($vals -join '; ')
            HasDisallowedValue  = $false
            HasAnyValue         = $true
        }
    }
}

# 3) Pull users where NONE of the three attributes are set
#    Use a negative presence LDAP filter to avoid client-side scanning.
$noValuesLdap = "(&(!(extensionAttribute1=*))
                    (!(extensionAttribute2=*))
                    (!(extensionAttribute3=*)))"

$noValues =
Get-ADUser -LDAPFilter $noValuesLdap -Properties DisplayName,SamAccountName,DistinguishedName,mail,Enabled

$resultsNoValues =
$noValues | ForEach-Object {
    [PSCustomObject]@{
        DisplayName         = $_.DisplayName
        SamAccountName      = $_.SamAccountName
        DistinguishedName   = $_.DistinguishedName
        Mail                = $_.mail
        Enabled             = $_.Enabled
        ExtAttr1            = $null
        ExtAttr2            = $null
        ExtAttr3            = $null
        ValuesPresent       = ''
        HasDisallowedValue  = $false
        HasAnyValue         = $false
    }
}

# At this point you have two separate, queryable collections:
# - $resultsWithValues : have at least one ext attr populated, none are disallowed
# - $resultsNoValues   : none of the three ext attrs are set

# Optional: Combine if you want a full “good” snapshot in one table
$resultsAll = @()
$resultsAll += $resultsWithValues
$resultsAll += $resultsNoValues

# Examples:
# $resultsWithValues.Count
# $resultsNoValues.Count
# $resultsAll | Group-Object HasAnyValue
# $resultsWithValues | Sort-Object DisplayName | Format-Table DisplayName,SamAccountName,ValuesPresent -AutoSize
# $resultsNoValues   | Export-Csv .\Users-ExtAttr-None.csv -NoTypeInformation -Encoding UTF8
# $resultsWithValues | Export-Csv .\Users-ExtAttr-PresentNotDisallowed.csv -NoTypeInformation -Encoding UTF8
