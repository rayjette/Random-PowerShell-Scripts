Function Get-ESXiVibs
{
    <#
        .SYNOPSIS
        Returns information about the VIB's installed on ESXi hosts.

        .DESCRIPTION
        Returns information about the VIB's installed on ESXi hosts.

        .PARAMETER VMHost

        .PARAMETER Name
        The name of one or more VIB's to look for.

        .EXAMPLE
        Get-VMHost | Get-ESXiVibs
        Returns information about all VIB's installed on all esxi hosts in vCenter.

        .EXAMPLE
        Get-VMHost | Get-ESXiVibs -Name esx-ui
        Returns information from all esxi hosts in vCenter about the esx-ui vib if it's installed.
        If it's not installed nothing will be returned.

    #>
    [OutputType([VMware.Vim.SoftwarePackage])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
        $VMHost,

        [string[]]$Name
    )
    process
    {
        foreach ($esxiHost in $VMHost)
        {
            $imageManager = Get-View ($esxiHost.ExtensionData.ConfigManager.ImageConfigManager)
            $installedVibs = $imageManager.fetchSoftwarePackages()
            if ($PSBoundParameters.ContainsKey('Name'))
            {
                foreach ($item in $Name)
                {
                    $installedVibs | Where-Object {$_.name -match $item} | Add-Member -Name 'VMHost' -Value $esxiHost -MemberType NoteProperty -PassThru
                }
            }
            else
            {
                $installedVibs | Add-Member -Name 'VMHost' -Value $esxiHost.name -MemberType NoteProperty -PassThru
            }
        }
    }
} # Get-ESXiVibs