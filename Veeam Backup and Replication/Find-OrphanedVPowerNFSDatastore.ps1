#Requires -Modules VMware.VimAutomation.Core

Function Find-OrphanedVPowerNFSDatastore
{
    <#
        .SYNOPSIS
        Find's orphaned vPower NFS datastores in VMware.

        .DESCRIPTION
        Find's orphaned vPower NFS datastores in VMware.

        .EXAMPLE
        Find-OrphanedVPowerNFSDatastore
        Find orphaned vPower NFS datastores.

        .INPUTS
        None.  Find-OrphanedVPowerNFSDatastores does not accept input from the pipeline.

        .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param (
        
    )
    # Get VMware ESXi Hypervisors
    $vmHosts = Get-VMHost

    # Get orphaned Veeam vPower NFS datastores
    $filter = {($_.Name -like "VeeamBackup_*") -and ($_.State -eq 'Unavailable') -and ($_.type -eq 'NFS')}
    $datastores = $vmHosts | Get-Datastore | Where-Object -FilterScript $filter | Sort-Object -Unique

    # Find out what hosts have the orphaned datastore present.
    foreach ($datastore in $datastores)
    {
        $mountedOnHost = foreach ($vmHost in $vmHosts)
        {
            if ($vmHost | Get-Datastore -Name $datastore.name -ErrorAction 'SilentlyContinue')
            {
                $vmHost.name
            }
        }
        # Return a PSCustomObject with the name of the datastore and the hosts it is mounted on.
        [PSCustomObject]@{
            Name = $datastore.name
            VMHosts = $mountedOnHost -join ' ,'
        }
    }
} # Find-OrphanedVPowerNFSDatastore