Function Get-UnavailableBackupFiles
{
    <#
    
        .SYNOPSIS
            Find restore points that are unavilable.
        
        .DESCRIPTION
            Find restore points that are unavailable.  These restore points would have their storage either offline or the
            files missing.

        .OUTPUTS
            Selected.Veeam.Backup.Core.CStorage

        .EXAMPLE
            Get-UnavailableBackupFiles
    #>
    [CmdletBinding()]
    Param ()

    $properties = 'FilePath', 'CreationTime', 'IsAvilable'
    $restorePoints = Get-VBRRestorePoint
    $restorePoints.GetStorage() | Where-Object {-not $_.IsAvailable} | Select-Object -Property $properties
}