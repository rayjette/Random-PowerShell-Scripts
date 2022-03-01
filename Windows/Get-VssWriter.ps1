#Requires -RunAsAdministrator

Function Get-VssWriter
{
    <#
        .SYNOPSIS
        Gets VSS Writer information.

        .DESCRIPTION
        Get-VssWriter is a wraper around vssadmin list writers.  It's used to get VSS Writer information.

        .EXAMPLE
        Get-VssWriter

        .INPUTS
        None.  Get-VssWriter does not accept input from the pipeline.

        .OUTPUTS
        System.Management.Automation.PSCustomObject.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param()

    $vssWriterInfo = Invoke-Command -ScriptBlock {vssadmin.exe list writers}
    $vssWriterInfo = $vssWriterInfo | Select-String 'Writer name:.*' -Context 0, 4
    foreach ($writer in $vssWriterInfo)
    {
        [PSCustomObject]@{
            Name        = $writer.matches.value -replace 'Writer name:\s+' -replace "'"
            Id          = $writer.context.postcontext[0] -replace '\s+Writer Id:\s+'
            InstanceId  = $writer.context.postcontext[1] -replace '\s+Writer Instance Id:\s+'
            State       = $writer.context.postcontext[2] -replace '\s+State:\s+'
            LastError   = $writer.context.postcontext[3] -replace '\s+Last error:\s+'
        }
    }
} # Get-VssWriter