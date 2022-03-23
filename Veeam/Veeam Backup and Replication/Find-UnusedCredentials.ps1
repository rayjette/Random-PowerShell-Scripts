#Requires -Modules Veeam.Backup.PowerShell

Function Find-UnusedCredentials
{
    <#
        .SYNOPSIS
        Finds unused saved credentials in Veeam Backup and Replication in a VMware environment.

        .DESCRIPTION
        Compares credentials in use by jobs and compares them to saved credentials and outputs whatever is not in use.
        Find-UnusedCredentials was created for a VMware environment.

        .EXAMPLE
        Find-UnusedCredentials

        .EXAMPLE
        Find-UnusedCredentials | Remove-VBRCredentials

        .INPUTS
        None.  Find-UnusedCredentials does not have any parameters.

        .OUTPUTS
        Veeam.Backup.PowerShell.Infos.CInternalCredentials
    #>
    [OutputType([Veeam.Backup.PowerShell.Infos.CInternalCredentials])]
    [CmdletBinding()]
    param ()

    Function Get-VBRVSSJobCreds
    {
        <#
            .SYNOPSIS
            Returns the credential id's for credentials in use by Veeam
            backup jobs.
        #>

        # This stores the ID's of the credentials that we will return.
        $CredentialIDs = @()

        # Get the credential ID's for Veeam backup jobs.  These are the credentials set
        # at the job level not those that are set for an individual VM.
        $backupJobs = Get-VBRJob | Where-Object {$_.IsBackup}
        $vssOptions = $backupJobs.GetVSSOptions()
        foreach ($item in $vssOptions)
        {
            if ($item.AreLinCredsSet)
            {
                $CredentialIDs += $item.LinCredsId.tostring()
            }
            elseif ($item.AreWinCredsSet)
            {
                $CredentialIDs += $item.WinCredsId.tostring()
            }
        }

        # Find explicit credentials in use not inherited from the job.
        foreach ($job in $backupJobs)
        {
            $vssOptions = $job | Get-VBRJobObject | Get-VBRJobObjectVssOptions
            foreach ($item in $vssOptions)
            {
                if ($item.AreLinCredsSet)
                {
                    $CredentialIDs += $item.LinCredsId.tostring()
                }
                elseif ($item.AreWinCredsSet)
                {
                    $CredentialIDs += $item.WinCredsId.tostring()
                }
            }
        }
        $CredentialIDs | Sort-Object -Unique
    } # Get-VBRVSSJobCreds


    Function Get-VBRBackupRepositoryCreds
    {
        <#
            .SYNOPSIS
            Returns the credential id's for CIFS Shares used as backup repositories.
        #>
        $repo = Get-VBRBackupRepository | Where-Object {$_.IsCifsShareWithCreds()}
        $repo.sharecredsid | ForEach-Object {$_.tostring()} | Sort-Object -Unique
    } # Get-VBRBackupRepositoryCreds


    Function Get-VBRBackupRepoExtentCreds
    {
        <#
            .SYNOPSIS
            Gets the credential id's for Veeam backup repository extents.
        #>
        $BackupRepoExtents = Get-VBRRepositoryExtent -Repository *
        $BackupRepo = $BackupRepoExtents.Repository | Where-Object {$_.IsCifsShareWithCreds()}
        $BackupRepo.ShareCredsId | ForEach-Object {$_.tostring()} | Sort-Object -Unique
    } # Get-VBRBackupRepoExtentCreds


    Function Get-VBRServerCreds
    {
        <#
            .SYNOPSIS
            Get's the credential ID's from servers returned by the Get-VBRServer cmdlet.
            This works with vCenter and ESXi.  I do not have Hyper-v in my environment
            so I did not attempt to make it work with that.
        #>
        $creds = @()
        $servers = Get-VBRServer
        foreach ($server in $servers)
        {
            switch ($server.type)
            {
                Linux
                {
                    $creds +=  $server.GetSshCreds().credsid.tostring()
                    break
                }
                Windows
                {
                    if ($server.hascreds())
                    {
                        $creds += $server.FindCreds().id.tostring()
                    }
                    break
                }
                ESXi
                {
                    $creds += $server.FindSoapCreds().credsid
                    break
                }
                Vc
                {
                    $creds += $server.FindSoapCreds().credsid.tostring()
                    break
                }
            }
        }
        # The value '00000000-0000-0000-0000-000000000000' is used when credentials are not set
        # and since I was not able to determine in advance if credentials were in use on 
        # Windows servers i'll just remove it here.
        $creds = $creds | Where-Object {$_ -ne '00000000-0000-0000-0000-000000000000'}
        $creds | Sort-Object -Unique
    } # Get-VBRServerCreds


    Function Get-VBRNasServerCredentials
    {
        <# 
            .SYNOPSIS
            Returns the credential id's of credentials in use by NASes.

            .PARAMETER CredentialsInUse
            Takes a list of existing credentials.

            The reason for this parameter is because I was unable to determine the
            id of the credentials in use for each NAS without looking it up in the
            results returned by Get-GBRCredentials.

            .EXAMPLE
            $Credentials = Get-VBRCredentials
            Get-VBRNasServerCredentials -CredentialsInUse $Credentials
        #>
        param
        (
            [Object[]]$CredentialsInUse
        )
        $nasServer = Get-VBRNASServer
        foreach ($item in $nasServer)
        {
            $filter = {
                $_.Name -eq $item.AccessCredentials.Name -and
                $_.Description -eq $item.AccessCredentials.Description
            }
            $creds = $CredentialsInUse | Where-Object -FilterScript $filter
            $creds | ForEach-Object {$_.id.tostring()} | Sort-Object -Unique

        }
    } # Get-VBRNasServerCredentials


    Function Get-VBRNotificationCreds
    {
        <#
            .SYNOPSIS
            Gets the credential id for the credential in use by the VBR notification options.

            .PARAMETER CredentialsInUse
            Takes a list of existing credentials.

            The reason for this parameter is because I was unable to determine the
            id of the credentials in use for the notification settings without looking
            it up in the results returned by Get-GBRCredentials.

            .EXAMPLE
            $creds = Get-VBRCredentials
            Get-VBRNotificationCreds -CredentialsInUse $creds
        #>
        param
        (
            [Object[]]$CredentialsInUse
        )
        $notification = Get-VBRMailNotificationConfiguration
        $cred = $CredentialsInUse | Where-Object {
            $_.name -eq $notification.credentials.name -and
            $_.description -eq $notification.credentials.description
        }
        $cred.id.tostring()
    } # Get-VBRNotificationCreds


    Function Get-VBRSavedCreds
    {
        <#
            .SYNOPSIS
            Get's the credentials which are currently saved in Veeam Backup and Replication.
        #>
        Get-VBRCredentials | Where-Object {
            $_.Description -ne 'Helper appliance credentials' -and
            $_.Description -ne 'Tenant-side network extension appliance credentials' -and
            $_.Description -ne 'Azure helper appliance credentials'
        }
    } # Get-VBRSavedCreds


    Function Get-AllCredsNotInUse
    {
        <#
            .SYNOPSIS
            Gets the credentials which are not currently in use in components in Veeam Backup and Replication.
        #>
        $AllCreds = Get-VBRSavedCreds

        $credsInUse = @()
        $credsInUse += Get-VBRVSSJobCreds
        $credsInUse += Get-VBRBackupRepositoryCreds
        $credsInUse += Get-VBRBackupRepoExtentCreds
        $credsInUse += Get-VBRServerCreds
        $credsInUse += Get-VBRNasServerCredentials -CredentialsInUse $AllCreds
        $credsInUse += Get-VBRNotificationCreds -CredentialsInUse $AllCreds
        $credsInUse = $credsInUse | Sort-Object -Unique

        foreach ($cred in $AllCreds)
        {
            if ($credsInUse -notcontains $cred.id)
            {
                $cred
            }
        }
    } # Get-AllCredsNotInUse


    Get-AllCredsNotInUse
} # Find-UnusedCredentials