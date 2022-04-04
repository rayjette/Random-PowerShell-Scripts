#Requires -Modules 'MSOnline', 'ExchangeOnlineManagement', 'Microsoft.Online.SharePoint.PowerShell'

Function Get-SpaceUsageByUser
{
    <#
        .SYNOPSIS
            Returns the amount of Office 365 space a user is using by service.

        .DESCRIPTION
            Returns the amount of Office 365 space a user is using by service.

            The following services are reported on: Mailbox, Mailbox Archive, and
            OneDrive.

        .PARAMETER UserPrincipalName
            One or more UserPrincipalName's for users you are to report space usage for.

            If this parameter is not set all user's will be reported on.

        .PARAMETER Unit
            The unit of size.

        .EXAMPLE
            Get-SpaceUsageByUser -Unit GB

        .NOTES
            This function requires both MSOnline and ExchangeOnline modules.

    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]] $UserPrincipalName,

        [ValidateSet('KB', 'MB', 'GB', 'TB')]
        [string] $Unit
    )
    begin
    {
        Function Test-ConnectedToMsol
        {
            <#
                .SYNOPSIS
                    A helper function that tests if we are connected to Msol.
            #>
            try
            {
                $null = Get-MsolDomain -ErrorAction 'Stop'
                $true
            }
            catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException]
            {
                $false
            }
        }

        Function Test-ConnectedToExchangeOnline
        {
            <#
                .SYNOPSIS
                    A helper function that tests if we are connected to Exchange Online.
            #>
            try
            {
                $null = Get-EXOMailbox -ResultSize 1
                $true
            }
            catch [Microsoft.Exchange.Management.RestApiClient.RestClientException]
            {
                $false
            }
        }

        Function Test-ConnectedToSharepointOnline
        {
            <#
                .SYNOPSIS
                    A helper function that tests if we are connect to Share Point Online
            #>
            try
            {
                $null = Get-SPOSite -Limit 1 -WarningAction 'SilentlyContinue'
                $true
            }
            catch [System.InvalidOperationException]
            {
                $false
            }
        }

        Function Get-LicensedUsers
        {
            <#
                .SYNOPSIS
                    Returns user account from Office 365 which are licensed.

                .Parameter UserPrincipalName
                    Returns user accounts from the list of UserPrincipalName's 
                    which are licensed.
            #>
            param (
                [string[]] $UserPrincipalName
            )

            if (-not ($PSBoundParameters.ContainsKey('UserPrincipalName')))
            {
                return Get-MsolUser -All | Where-Object -FilterScript {$_.isLicensed -eq $true}
            }

            $users = @()
            foreach ($upn in $UserPrincipalName)
            {
                $users += Get-MsolUser -UserPrincipalName $upn
            }
            $users | Where-Object {$_.isLicensed}
        }

        Function Get-PrimarySmtpAddress
        {
            <#
                .SYNOPSIS
                    Returns the primary smtp address from objects contaning
                    the proxyaddresses property.
            #>
            param (
                [Parameter(ValueFromPipeline)]
                [object] $UserAccount
            )
            process
            {
                $proxyAddresses = $UserAccount.proxyaddresses
                $proxyAddresses -clike "*SMTP:*" -Replace 'SMTP:'
            }
        }

        Function ConvertFrom-ExchangeSize
        {
            <#
                .SYNOPSIS
                    A helper function that converts an Exchange size into bytes.
            #>
            param (
                [Parameter(ValueFromPipeline)]
                [string] $Size
            )
            [int64]((($Size -split '\(')[1]) -replace ' bytes\)' -replace ',')
        }

        Function Get-MailboxSize
        {
            <#
                .SYNOPSIS
                    Returns the size of a mailbox in bytes.
            #>
            param (
                [string] $SmtpAddress
            )
            $mailboxStats = Get-MailboxStatistics -Identity $SmtpAddress
            $mailboxStats.TotalItemSize.Value | ConvertFrom-ExchangeSize
        }

        Function Get-MailboxArchiveSize
        {
            <#
                .SYNOPSIS
                    Returns the size of a mailbox archive in bytes.
            #>
            param (
                [string] $SmtpAddress
            )
            $splat = @{
                Archive     = $true
                Identity    = $SmtpAddress
                ErrorAction = 'SilentlyContinue'
            }
            try
            {
                $archiveStats = Get-MailboxStatistics @splat
                $archiveStats.TotalItemSize.Value | ConvertFrom-ExchangeSize
            }
            catch { 0 }
        }

        Function Get-OneDriveSites
        {
            <#
                Gets all OneDrive Sites
            #>
            Get-SpoSite -IncludePersonalSite $true -Limit All | Where-Object {$_.url -like "*/personal/*"}
        }

        Function Get-OneDriveSize
        {
            <#
                Gets the size of the specified OneDrive site
            #>
            param (
                [string] $UserPrincipalName,

                [object[]] $Sites
            )
            $site = $Sites | Where-Object {$_.Owner -eq $UserPrincipalName}
            $site.StorageUsageCurrent * 1024 * 1024
        }

        Function Format-Size
        {
            <#
                .SYNOPSIS
                    A helper function to format size to a given unit.
            #>
            param
            (
                [int64] $Size,
                [string] $Unit,
                [int64] $Places
            )
            [math]::round($Size / "1$Unit" , $Places)
        }

        # Check if we are connected to Microsoft Online and terminate
        # with an appropriate error if not.
        if (-not (Test-ConnectedToMsol))
        {
            throw 'Run Connect-MsolService before running this command.'
        }

        # Check if we are connect to Exchange Online and termine with
        # an appropriate error if not.
        if (-not (Test-ConnectedToExchangeOnline))
        {
            throw 'Run Connect-ExchangeOnline before running this command.'
        }

        # Check if we are connected to SharePoint Online and termine with
        # an appropriate error if not.
        if (-not (Test-ConnectedToSharepointOnline))
        {
            throw 'Run Connect-SPOService before running this command.'
        }

        $result = [PSCustomObject]@{
            UserPrincipalName = $null
            "MailboxSize$($Unit)"       = $null
            "ArchiveSize$($Unit)"       = $null
            "OneDriveSize$($Unit)"      = $null
        }

        $licensedUsers = @()

        $OneDriveSites = Get-OneDriveSites
    }
    process
    {
        if ($PSBoundParameters.ContainsKey('UserPrincipalName'))
        {
            foreach ($upn in $UserPrincipalName)
            {
                $licensedUsers += Get-LicensedUsers -UserPrincipalName $upn
            }
        }
    }
    end
    {
        if (-not ($PSBoundParameters.ContainsKey('UserPrincipalName')))
        {
            $licensedUsers = Get-LicensedUsers
        }

        foreach ($user in $licensedUsers)
        {
            $primarySmtpAddress = Get-PrimarySmtpAddress -UserAccount $user

            $mailboxSize = Format-Size -Size (Get-MailboxSize -SmtpAddress $primarySmtpAddress) -Unit $Unit -Places 2
            $archiveSize = Format-Size -Size (Get-MailboxArchiveSize -SmtpAddress $primarySmtpAddress) -Unit $Unit -Places 2
            $oneDriveSize = Format-Size -Size (Get-OneDriveSize -UserPrincipalName $user.userPrincipalName -Sites $OneDriveSites) -Unit $Unit -Places 2

            $result.UserPrincipalName = $user.UserPrincipalName
            $result."MailboxSize$($Unit)"  = $mailboxSize
            $result."ArchiveSize$($Unit)"  = $archiveSize
            $result."OneDriveSize$($Unit)" = $oneDriveSize

            $result
        }
    }
}