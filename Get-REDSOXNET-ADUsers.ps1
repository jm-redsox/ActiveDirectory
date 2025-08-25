
<#  Get-CustomADUserReport function:
    1. Pull in the Active Directory module and get all users with specified properties
    2. Then filter out users based on ExtensionAttribute values and export to CSV files
#>

function Get-CustomADUserReport {
    [CmdletBinding()]
    param (
        [string[]]$ExcludeValues = @('Full Time','Part Time','Event Staff','Seasonal','ICS'),
        [string]$AllUsersCsv = "$FileOutputPath`all_REDSOXNETUsers.csv",
        [string]$FilteredUsersCsv = "$FileOutputPath`filtered_REDSOXNETUsers.csv"
    )

    Import-Module ActiveDirectory -ErrorAction Stop

    $AllUsers = Get-ADUser -Filter * -Properties `
        DistinguishedName, `
        Enabled, `
        GivenName, `
        mail, `
        extensionAttribute1, `
        extensionAttribute2, `
        extensionAttribute3, `
        Name, `
        ObjectClass, `
        ObjectGUID, `
        SamAccountName, `
        SID, `
        Surname, `
        UserPrincipalName

    $Results = $AllUsers | ForEach-Object {
        [PSCustomObject]@{
            DistinguishedName   = $_.DistinguishedName
            Enabled             = $_.Enabled
            Name                = $_.Name
            GivenName           = $_.GivenName
            Surname             = $_.Surname
            UserPrincipalName   = $_.UserPrincipalName
            Mail                = $_.Mail
            ExtensionAttribute1 = $_.ExtensionAttribute1
            ExtensionAttribute2 = $_.ExtensionAttribute2
            ExtensionAttribute3 = $_.ExtensionAttribute3
            SamAccountName      = $_.SamAccountName
        }
    }

    $FilteredResults = $Results | Where-Object {
        $_.ExtensionAttribute1 -notin $ExcludeValues -and
        $_.ExtensionAttribute2 -notin $ExcludeValues -and
        $_.ExtensionAttribute3 -notin $ExcludeValues
    }

    $Results | Export-Csv -Path $AllUsersCsv -NoTypeInformation -Encoding UTF8
    $FilteredResults | Export-Csv -Path $FilteredUsersCsv -NoTypeInformation -Encoding UTF8
}

<#
Main Execution Block
#>