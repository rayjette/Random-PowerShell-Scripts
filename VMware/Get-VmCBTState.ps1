#Requires -Modules VMware.VimAutomation.Core

Function Get-VmCBTState
{
    <#
        .SYNOPSIS
        Returns if CBT is enabled or not for the given vm.

        .DESCRIPTION
        Returns if CBT is enabled or not for the given vm.

        .PARAMETER Name
        The virtual machine name.

        .EXAMPLE
        Get-VmCBTState -vm myvm

        .EXAMPLE
        Get-VM | Get-VmGBTState

        .INPUTS
        The name parameter accepts input from the pipeline.

        .OUTPUTS
        System.Management.Automation.PSCustomObject

        .LINK
        Disable-VmCBT
        
        .Link
        Enable-VmCBT
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('VMName')]
        [string[]]$Name
    )
    PROCESS
    {
        foreach ($item in $Name)
        {
            try
            {
                $vm = Get-VM -Name $item -ErrorAction 'Stop'
                if ($vm)
                {
                    [PSCustomObject]@{
                        Name = $vm.name
                        CBT  = $vm.ExtensionData.Config.ChangeTrackingEnabled
                    }
                }
            }
            catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException]
            {
                Write-Error -Message 'Run Connect-VIServer to connect for vCenter/ESXi before running Get-VmCBTState.'
            }
            catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]
            {
                Write-Warning "Failed to get vm: $item"
            }
        }
    }
} # Get-VmCBTState