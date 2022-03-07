#Requires -Modules VMware.VimAutomation.Core

Function Enable-VmCBT
{
    <#
        .SYNOPSIS
        Set-VmCBT can be used to enable/disable change block tracking on VMware virtual machines.

        .DESCRIPTION
        Set-VmCBT can be used to enable/disable change block tracking on VMware virtual machines.

        .PARAMETER Name
        The name of the virtual machine.

        .PARAMETER Force
        If the force parameter is used you will not have to confirm the enable CBT operation.

        .EXAMPLE
        Enable-VmCBT -Name 'myvm'
        Enable CBT on myvm.

        .EXAMPLE
        Get-VM | Enable-VmCBT -Force
        Enable CBT on all virtual machines.  Confirmation will be supressed.

        .INPUTS
        The Name parameter accepts input from the pipeline

        .OUTPUTS
        Enable-VmCBT does not produce any output.

        .LINK
        Get-VmCBT

        .LINK
        Disable-VmCBT
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('VMName')]
        [string[]]$Name,

        [switch]$Force
    )
    BEGIN
    {
        $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $vmConfigSpec.changeTrackingEnabled = $true
    }
    PROCESS
    {
        foreach ($item in $Name)
        {
            try
            {
                $vm = Get-VM -Name $item -ErrorAction 'Stop'
                if (-not ($vm.ExtensionData.Config.ChangeTrackingEnabled))
                {
                    if ($Force -or $PSCmdlet.ShouldContinue($vm.name, 'Enable CBT'))
                    {
                        $view = $vm | Get-View
                        $view.reconfigvm($vmConfigSpec)
                    }
                }
                else
                {
                    Write-Warning -Message "CBT is already enabled for vm: $($vm.name)"    
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
} # Enable-VmCBT