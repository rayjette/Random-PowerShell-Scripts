#Requires -Modules ExchangeOnlineManagement

<#
    .SYNOPSIS
    Find's mailboxes being forwarded.

    .DESCRIPTION
    Find's mailboxes being forwarded.  Find-MailboxForwarding looks at both mailbox and rule forwarding.

    .PARAMETER MailboxForwarding
    Only look for mailboxes being forwarded at the mailbox level.

    .PARAMETER RuleForwarding
    Only look for rules forwarding mail.

    .EXAMPLE
    .\Find-MailboxForwarding
    Find mailboxes being forwarded at the mailbox level and mailboxes with rules forwarding mail to other smtp addresses.

    .EXAMPLE
    .\Find-MailboxForwarding -MailboxForwarding
    Find mailboxes being forwarded at the mailbox level.

    .EXAMPLE
    .\Find-MailboxForwarding -RuleForwarding
    Find mailboxes which have rules forwarding messages to other smtp addresses.

    .INPUTS
    None.  Find-MailboxForwarding does not accept input from the pipeline.

    .OUTPUTS
    System.Management.Automation.PSCustomObject

#>
[OutputType([System.Management.Automation.PSCustomObject])]
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(Mandatory, ParameterSetName = 'MailboxForwarding')]
    [switch]$MailboxForwarding,

    [Parameter(Mandatory, ParameterSetName = 'RuleForwarding')]
    [switch]$RuleForwarding
)


Function Find-MailboxLevelForwarding
{
    <#
        .SYNOPSIS
        A helper function to find mailboxes being fowarded at the mailbox level.
    #>
    param
    (
        [ValidateNotNullOrEmpty()]
        $Mailbox
    )
    # A counter for the progress bar
    $count = 0

    # The number of mailboxes in Mailbox
    $mbxCount = $mailbox.count

    foreach ($mbx in $mailbox)
    {
        # Increment the progress bar counter
        $count++
        
        # Output a progress bar indicating what mailbox number we are on out of the total number of mailboxes.
        $splat = @{
            Activity = 'Looking for mailboxes being forwarded at the mailbox level...'
            Status = "Checking mailbox $count of $mbxCount)"
            PercentComplete = (($count / $mbxCount))
        }
        Write-Progress @splat

        # If the current mailbox is being forwarded output information about such.
        if ($mbx.forwardingsmtpaddress)
        {
            [PSCustomObject]@{
                Name = $mbx.DisplayName
                ForwardType = 'Mailbox'
                ForwardInfo = @{
                    DeliverToMailboxAndForward = $mbx.DeliverToMailboxAndForward
                    ForwardTo = $mbx.ForwardingSmtpAddress -replace 'smtp:'
                }
            }
        }
    }
} # Find-MailboxLevelForwarding


Function Find-ForwardingViaRule
{
    <#
        .SYNOPSIS
        A helper function to find mailboxes which have rules that forward mailbox elsewhere.
    #>
    param
    (
        [ValidateNotNullOrEmpty()]
        $Mailbox
    )

    # A counter for the progress bar
    $count = 0

    # The number of mailboxes in Mailbox
    $mbxCount = $mailbox.count

    foreach ($mbx in $mailbox)
    {
        # Increment the progress bar counter
        $count++

        $rules = Get-InboxRule -Mailbox $mbx.UserPrincipalName | Where-Object {$_.Enabled -eq $true}
        foreach ($rule in $rules)
        {
            # Output a progress bar indicating what mailbox number we are on out of the total number of mailboxes.
            $splat = @{
                Activity = 'Looking for mailboxes that have rules forwarding mail...'
                Status = "Checking mailbox $count of $mbxCount)"
                PercentComplete = (($count / $mbxCount))
            }
            Write-Progress @splat

            $result = [PSCustomObject]@{
                Name = $mbx.DisplayName
                ForwardType = 'Rule'
                ForwardInfo = @{
                    RuleName = $rule.name
                    ForwardFrom = $null
                    ForwardTo = $null
                }
            }

            if ($rule.ForwardAsAttachment)
            {
                $result.ForwardInfo.ForwardTo = $rule.ForwardAsAttachment
                $result.ForwardInfo.ForwardFrom = $rule.from
                $result
            }
            elseif ($rule.ForwardTo)
            {
                $result.ForwardInfo.ForwardTo = $rule.forwardto
                $result.ForwardInfo.ForwardFrom = $rule.forwardfrom
                $result
            }
            elseif ($rule.RedirectTo)
            {
                $result.ForwardInfo.ForwardTo = $rule.forwardto
                $result.ForwardInfo.ForwardFrom = $rule.from
                $result
            }
        }
    }
} # Find-ForwardingViaRule


# Get all shared and user mailboxes from Exchange Online using the ExchangeOnlineManagement module.
Write-Verbose -Message 'Getting mailboxes from ExchangeOnline.'
$recipientTypeDetails = 'UserMailbox', 'SharedMailbox'
$properties = 'DeliverToMailboxAndForward', 'ForwardingAddress', 'ForwardingSMTPAddress'
$splat = @{
    ResultSize = 'unlimited'
    RecipientTypeDetails = $recipientTypeDetails
    Properties = $properties
}
$mailbox = Get-ExoMailbox @splat

# Find and output information about all mailboxes being forwarding at the mailbox level.
if (-not ($PSBoundParameters.ContainsKey('RuleForwarding')))
{
    Write-Verbose -Message "Looking for mailboxes being forwarded at the mailbox level..."
    Find-MailboxLevelForwarding -Mailbox $mailbox
}

# Find and output information about mailboxes with rules forwarding message elsewhere.
if (-not ($PSBoundParameters.ContainsKey('MailboxForwarding')))
{
    Write-Verbose -Message "Checking rules for forwarding..."
    Find-ForwardingViaRule -Mailbox $mailbox
}