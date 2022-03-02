Function ConvertFrom-SmsmeEvent
{
    <#
        .SYNOPSIS
        Converts Application log events from 'Symantec Mail Security for Microsoft 
        Exchange' into PSCustomObjects.  By default the last hour of events will be 
        converted.
 
        .DESCRIPTION
        Converts Application log events from 'Symantec Mail Security for Microsoft 
        Exchange' into PSCustomObjects. By default the last hour of events will be 
        convered. 

        .PARAMETER ServerName
        The name of an Exchange server running 'Symantec Mail Security for Microsoft Exchange'.

        .PARAMETER MaxEvents
        Specifies the maximum number of events returned.  A default value of 2000 is provided.

        .PARAMETER StartTime
        Accepts a System.Datetime.  Specifies the start time for events that will be returned.
        A default value of the past hour is specified.

        .PARAMETER EndTime
        Accepts a System.Datetime.  Specifies the end time for evnets that will be returned.

        .EXAMPLE
        ConvertFrom-SmsmeEvent -ServerName exch-ht-00
        Converts and outputs the last hour of events.  At most 2000 events will be returned.

        .EXAMPLE
        ConvertFrom-SmsmeEvent -ServerName exch-ht-00
        Converts and outputs the last hour of events.  5000 events will be returned.

        .EXAMPLE
        ConvertFrom-SmsmeEvent -ServerName exch-ht-00 -StartTime (Get-Date).AddHours(-5)
        Converts and outputs events from the last 5 hours.  2000 events will be converted by default.

        .OUTPUTS
        System.Management.Automation.PSCustomObject

        .INPUTS
        None.  ConvertFrom-SMSMEEvent does not accept objects from the pipeline.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param (
        # ServerName
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'An Exchange server running Symantec Mail Security for Microsoft Exchange'
        )]
        [ValidateScript({Test-Connection -ComputerName $PSItem -Quiet -Count 1 -InformationAction Ignore })]
        [String]$ServerName,

        # MaxEvents
        [int64]$MaxEvents = 2000,

        # StartTime
        [DateTime]$StartTime = (Get-Date).AddHours(-1),

        # EndTime
        [DateTime]$EndTime = (Get-Date)
    )
    Set-StrictMode -Version 2.0
    
    try {

        $events = (Get-WinEvent -ComputerName $ServerName -MaxEvents $MaxEvents -FilterHashTable @{
            ProviderName = 'Symantec Mail Security for Microsoft Exchange'
            LogName = 'Application'
            ID = 381
            StartTime = $StartTime
            EndTime = $EndTime
        })

        foreach ($event in $events) {

            $eventXML = [xml]$event.ToXML()
            $eventData = $eventXML.Event.EventData.Data 
            $eventData -match 'Message classified as: (.*) Message Details: Connecting IP: (.*) MAIL FROM: (.*) RCPT TO: (.*) Message-ID: (.*) Subject: (.*) \.  (.*)' | Out-Null

            [PSCustomObject]@{
                LoggedTime     = ($event.TimeCreated.ToString())
                Classification = "$($matches[1] -Replace '\.','')"
                ConnectingIP   = ($matches[2].Trim().ToString())
                MailFrom       = ($matches[3].Trim().ToString())
                MailTo         = ($matches[4].Trim().ToString())
                MessageId      = ($matches[5].Trim().ToString())
                Subject        = ($matches[6].Trim().ToString())
                Action         = ($matches[7].Trim().ToString())
            }
        }
    } catch {write-error $_.Exception.Message}
} # ConvertFrom-SmsmeEvent