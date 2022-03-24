#Requires -Modules MSOnline, Microsoft.Online.SharePoint.PowerShell

Function Get-OneDriveReport
{
    <#
    .SYNOPSIS
    Gets a basic OneDrive report.

    .DESCRIPTION
    This gets a OneDrive report for all users in Microsoft Office 365.

    .PARAMETER Unit
    Unit is how the space used by OneDrive is reported.  Accepted
    Values are 'KB', 'MB', 'GB', and 'TB'.  If this is not specified
    the size will be output in bytes.

    .EXAMPLE
    Get-OneDriveReport
    Reports information about OneDrive for all users in
    Office 365.

    .EXAMPLE
    Get-OneDriveReport -Unit GB
    Reports information about OneDrive for all users in
    Office 365.  The size information will be displayed in GB.

    .EXAMPLE
    Get-OneDriveReport | Where-Object {$_.IsLicensed}
    Reports on only licensed Office 365 accounts.

    .INPUTS
    Get-OneDriveReports does not accept input from the pipeline.

    .OUTPUTS
    System.Management.Automation.PSCustomObject.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param (
        [ValidateSet('KB','MB','GB', 'TB')]
        [string] $Unit
    )

    Function Test-HasOneDrive($UserPrincipalName, $SPOSites)
    {
        <#
            .SYNOPSIS
            Tests if a user has a provisioned OneDrive.
        #>
        $splat = @{
            UserPrincipalName = $UserPrincipalName
            SPOSites = $SPOSites
        }
        [bool](Get-UsersOneDrive @splat)
    }


    Function Get-UsersOneDrive($UserPrincipalName, $SPOSites)
    {
        <#
            .SYNOPSIS
            Returns the OneDrive of a specified user.
        #>
        $SPOSites.where({$PSItem.Owner -eq $UserPrincipalName})
    }


    Function Get-AllNonExternalMsolUsers
    {
        <#
            .SYNOPSIS
            Returns user's which are not external from Microsoft Online.
        #>
        (Get-MsolUser -All).where({$_.UserPrincipalName -notlike "*#EXT#*"})
    }


    Function Format-Size($SizeInBytes, $Unit, $PlacesAfterDecimal)
    {
        <#
            .SYNOPSIS
            Formats bytes into the specified unit.
        #>
        [math]::round($SizeInBytes / "1$Unit", $PlacesAfterDecimal)
    }


    # Get all of the users stored in Office 365.  We will exclude external users.
    Write-Warning -Message 'Getting users stored in Office 365...'
    #$allUsers = Get-MsolUser -All | Where-Object {$_.UserPrincipalName -notlike "*#EXT#*"}
    $allUsers = Get-AllNonExternalMsolUsers

    # Get all of the provisioned One Drive sites
    $oneDriveSplat = @{
        IncludePersonalSite = $true
        Limit = 'all'
        Filter = "Url -like '-my.sharepoint.com/personal'"
    }
    Write-Warning -Message 'Getting OneDrive sites...'
    $oneDriveSites = Get-SPOSite @oneDriveSplat

    if ($allUsers -and $oneDriveSites)
    {
        # Loop though Office 365 users returning infomraiton
        # about that user's OneDrive.
        $allUsers | ForEach-Object {
            $upn = $PSItem.UserPrincipalName
            $splat = @{
                SpoSite = $oneDriveSites
                UserPrincipalName = $upn
            }

            # Setup the object to be returned
            $object = [PSCustomObject]@{
                Owner                   = $PSItem.DisplayName
                UserPrincipalName       = $upn
                IsLicensed              = $PSItem.IsLicensed
                HasOneDrive             = $null
                LastContentModifiedDate = $null
                'StorageQuotaGB'        = $null
                "StorageUsage$Unit"     = $null
            }

            # The user has a OneDrive.
            if (Test-HasOneDrive @splat)
            {
                # Save the user's OneDrive
                $oneDrive = Get-UsersOneDrive @splat

                # The last time the OneDrive had a modification
                $lastModified = $oneDrive.LastContentModifiedDate

                # Save the size of the OneDrive.  The size is reported in MB
                # so we convert it to bytes.  If a unit was specified as a
                # parameter to this scrip will will pass it though the Format-Size
                # function
                $storageUsage = $oneDrive.StorageUsageCurrent * 1024 * 1024
                if ($PSBoundParameters.ContainsKey('Unit'))
                {
                    $storageUsage = Format-Size -SizeInBytes $storageUsage -Unit $Unit -PlacesAfterDecimal 2
                }
                
                # Update and return the object.
                $object.Owner = $PSItem.DisplayName
                $object.UserPrincipalName = $upn
                $object.IsLicensed = $PSItem.IsLicensed
                $object.HasOneDrive = $true
                $object.LastContentModifiedDate = $lastModified
                $object.StorageQuotaGB = $oneDrive.StorageQuota
                $object."StorageUsage$Unit" = $storageUsage
            }
            $object
        }
    }
    else
    {
        Write-Error -Message "Failed to get user and or OneDrives."    
    }
} # Get-OneDriveReport