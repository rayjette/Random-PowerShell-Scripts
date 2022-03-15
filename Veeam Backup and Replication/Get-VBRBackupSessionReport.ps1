Function Get-VBRBackupSessionReport
{
    <#
        .SYNOPSIS
        Gets information about backup sessions.

        .DESCRIPTION
        Gets information about backup sessions.

        .PARAMETER JobName
        Report on sessions from the specified job.

        .PARAMETER VMName
        Report only on the following VM's.

        .PARAMETER StartTime
        Only sessions created at or after this time are considered. A default value of the last 7
        days is provided if not specified.

        .PARAMETER EndTime
        Only sessions created before or at this time are considered.  

        .PARAMETER Unit
        The conversion unit used to output size.  A default of GB is provided.

        .EXAMPLE
        Get-VBRBackupSessionReport
        Reports on all sessions within the last 7 days.

        .EXAMPLE
        Get-VBRBackupSessionReport -JobName backup-windows_vms-1
        Reports on sessions, within the last 7 days, for the backup-windows_vms-1 job.

        .EXAMPLE
        Get-VBRBackupSessionReport -VMName 'dc-1'
        Reports on session for the vm dc-1 from within the last 7 days.

        .EXAMPLE
        Get-VBRBackupSessionReport -JobName backup-windows_vms-1 -VMName dc-1
    
        .EXAMPLE
        Get-VBRBackupSessionReport -StartTime (Get-Date).AddDays(-7) -EndTime (Get-Date)

        .INPUTS
        None.  Get-VBRBackupSessionReport does not accept input from the pipeline.
        
        .OUTPUTS
        [System.Management.Automation.PSCustomObject]

        .NOTES
        Get-VBRBackupSessionReport only reports on backup session and will not have any information
        about Syntethic full's.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'Job')]
        [Parameter(ParameterSetName = 'VM')]
        [string]$JobName,

        [Parameter(Mandatory, ParameterSetName = 'VM')]
        [string]$VMName,

        [DateTime]$StartTime = (Get-Date).AddDays(-7),

        [DateTime]$EndTime = (Get-Date),

        [ValidateSet('KB', 'MB', 'GB', 'TB')]
        $Unit = 'GB'
    )

    # Setup our parameters for Get-VBRJob
    $vbrJobSplat = @{}
    if ($PSBoundParameters.ContainsKey('JobName'))
    {
        $vbrJobSplat.add('Name', $JobName)
    }

    # Get Veeam Backup and Recovery backup jobs.
    $backupJobs = Get-VBRJob @vbrJobSplat

    foreach ($backupJob in $backupJobs)
    {
        $filter = {$_.CreationTime -ge $StartTime -and $_.CreationTime -le $EndTime}
        $jobSession = [veeam.backup.core.cbackupsession]::GetByJob($backupJob.Id) | Where-Object -FilterScript $filter
        # Get the task session for each session
        foreach ($session in $jobSession)
        {
            $taskSession = $session | Get-VBRTaskSession
            if ($PSBoundParameters.ContainsKey('VMName'))
            {
                $taskSession = $taskSession | Where-Object {$_.name -eq $VMName}
            }

            # Return information about each task in the task session.
            foreach ($task in $taskSession)
            {
                [PSCustomObject]@{
                    Name = $task.name
                    JobName = $task.JobSess.JobName
                    Status    = $task.Status
                    StartTime = $task.Progress.StartTimeLocal
                    StopTime  = $task.Progress.StopTimeLocal
                    Duration  = $task.Progress.Duration
                    AvgSpeed  = $task.Progress.AvgSpeed
                    IsFull    = $session.IsFullMode
                    "SizeTransfered($Unit)" = $task.Progress.TransferedSize / "1$Unit"
                }
            }
        }
    }
} # Get-VBRBackupSessionReport