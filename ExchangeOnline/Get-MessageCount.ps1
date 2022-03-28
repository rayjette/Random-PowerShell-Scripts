#Requires -Modules ExchangeOnlineManagement

Function Get-MessageCount
{
    <#
        .SYNOPSIS
        Returns a count of the number of messages sent and received from/by one or more email addresses.

        .DESCRIPTION
        Returns a count of the number of messages sent and received from/by one or more email addresses.

        .PARAMETER EmailAddress
        One or more e-mail addresses.

        .PARAMETER StartDate
        The count will include messages sent/received starting from this date/time.  A default value of 10
        days ago is provided.  This is the longest amount of time Office 365 will also us to go back.

        .PARAMETER EndDate
        The count will stop at this date.  A default value of right now is specified.

        .PARAMETER ExcludeSpam
        Only messages which have been delivered to the user's mailbox will be counted.

        .EXAMPLE
        Get-MessageCount -EmailAddress user@domain.com
        Returns a count of the number of e-mails sent and received from user@domain.com.

        .EXAMPLE
        (Get-ADUser  -Filter * -Properties proxyaddresses).proxyaddresses -clike "SMTP:*" -replace 'SMTP:' | Get-MessageCount
        Get a message count for all users in Active Directory.

        .EXAMPLE 
        Get-MessageCount -EmailAddress user@domain.com -ExcludeSpam
        Return the count of messages sent and received from/by user@domain.com.  Only messages delivered to the users mailbox will be counted.

        .INPUTS
        string[].  The EmailAddress parameter of Get-MessageCount takes strings via the pipeline.

        .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress,

        [DateTime]$StartDate = (Get-Date).AddDays(-10),

        [DateTime]$EndDate = (Get-Date),

        [switch]$ExcludeSpam
    )
    begin
    {
        # These are the parameters to be passed to Get-MessageTrace
        $splat = @{
            StartDate = $StartDate
            EndDate   = $EndDate
        }
    }
    process
    {
        # Loop over each e-mail address outputting the count of messages sent and messages received
        foreach ($address in $EmailAddress)
        {
            Write-Progress -Activity "Running message trace on $address"
            $messagesSent = Get-MessageTrace -SenderAddress $address @splat
            $messagesReceived = Get-MessageTrace -RecipientAddress $address @splat

            # If the ExcludeSpam parameter is set we will remove anything that was not delivered to the users mailbox.
            if ($PSBoundParameters.ContainsKey('ExcludeSpam'))
            {
                $filter = {$_.Status -eq 'Delivered'}
                $messagesReceived = $messagesReceived | Where-Object -FilterScript $filter
            }

            # Return the message count for the address
            [PSCustomObject]@{
                EmailAddress = $address
                SentCount    = ($messagesSent | Measure-Object).count
                ReceivedCount = ($messagesReceived | Measure-Object).count
            }
        }
    }
} # Get-MessageCount