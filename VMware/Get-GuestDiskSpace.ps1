#Requires -Modules VMware.VimAutomation.Core

Function Get-GuestDiskSpace
{
    <#
        .SYNOPSIS
        Get disk space information from running virtual machines.
        
        .DESCRIPTION
        Get disk space information from running virtual machines.

        .PARAMETER VMName
        The name of one or more virtual machines to get disk space for.

        .EXAMPLE
        Get-VM | Get-GuestDiskSpace
        Get disk space information from all running guests returned by the Get-VM cmdlet.

        .EXAMPLE
        Get-GuestDiskSpace -VMName 'vm1', 'vm2'
        Get disk space information from vm1 and vm2.

        .INPUTS
        String.  The VMName parameter takes the name of the virtual machines via the pipeline.
        
        .OUTPUTS
        System.Management.Automation.PSCustomObject

    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )
    PROCESS
    {
        $guests = Get-VM -Name $Name | Get-VMGuest
        foreach ($guest in $guests)
        {
            if ($guest.State -eq 'Running')
            {
                Write-Verbose -Message "Getting disk space information for guest: $($guest.VMName)"
                foreach ($disk in $guest.Disks)
                {
                    [PSCustomObject]@{
                        VMName = $guest.VMName
                        CapacityGB = [math]::round($disk.CapacityGB, 2)
                        FreeSpaceGB = [math]::round($disk.FreeSpaceGB, 2)
                        Path = $disk.Path
                    }
                }
            }
            else 
            {
                Write-Verbose -Message "$($guest.VMName) is not running and will be skipped."
            }
        } 
    }
} # Get-GuestDiskSpace