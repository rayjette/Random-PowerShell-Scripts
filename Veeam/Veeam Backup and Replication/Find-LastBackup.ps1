#Requires -Modules Veeam.Backup.PowerShell

Function Find-LastBackup
{
    <#
        .SYNOPSIS
        Finds the latest restore point in Veeam Backup and Replication
        for a given asset.

        .DESCRIPTION
        Finds the latest restore point in Veeam Backup and Replication
        for a given asset.

        An object is returned for every item in name even if a restore point
        does not exist.  This is to make it easy to identify things from name
        which are not getting backed up.

        .PARAMETER All
        Returns information about all of the latest restore points.

        .PARAMETER Name
        The name of one or more virtual machine or computer.

        .EXAMPLE
        Find-LastBackup -All
        Get the latest restore point information from all assets.

        .EXAMPLE
        Find-LastBackup -Name 'vm-00'
        Get the latest restore point information from 'vm-00'

        .EXAMPLE
        Get-VM | Find-LastBackup
        Get the latest restore point information from all virtual machines in vCenter/ESXi.

        .INPUTS
        String.  The name parameter accepts input via the pipeline

        .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName='All', Mandatory)]
        [switch]$All,

        [Parameter(ParameterSetName='Name', Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )
    begin
    {
        Function Get-LatestRestorePoint
        {
            <#
                .SYNOPSIS
                A helper function that returns a hash table contaning the name, creationtime, and type of
                the latest restore point for each asset being backed up.
            #>
            $restorePoint = Get-VBRRestorePoint | Sort-Object -Property CreationTime | Group-Object -Property Name -AsHashTable
            foreach ($rp in $restorePoint.GetEnumerator())
            {
                [PSCustomObject]@{
                    Name         = $rp.value[-1].name
                    CreationTime = $rp.value[-1].creationtime
                    Type         = $rp.value[-1].type
                }
            }
        } # Get-LatestRestorePoint

        # Save information on the latest restore points.
        $latestRP = Get-LatestRestorePoint
    }
    process
    {
        # If the All parameter is specified we will return all of the restore point information.
        if ($PSBoundParameters.ContainsKey('All'))
        {
            $latestRP 
        }
        else
        {
            foreach ($item in $Name)
            {
                # The current item has a restore point.  Return it's information.
                if ($rp = $latestRP | Where-Object {$_.name -like $item})
                {
                    $rp
                }
                # We do not have a restore point for item.  We will return an empty object.
                else
                {
                    [PSCustomObject]@{
                        Name         = $item
                        CreationTime = $null
                        Type         = $null
                    }
                }
            }
        }
    }
} # Find-LastBackup