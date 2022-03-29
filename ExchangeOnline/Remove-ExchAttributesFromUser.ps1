Function Remove-ExchAttributesFromUser
{
    <#
        .SYNOPSIS
        Remove Exchange related attributes from an Active Directory account.
    #>
    [CmdletBinding()]
    param (
        [alias('id', 'user')]
        [string]$samAccountName,

        [switch]$force
    )
    begin {
        $attributes = $(
            'msExchMailboxGuid',
            'msExchhomeServername',
            'LegacyExchangeDN',
            'mail',
            'mailnickname',
            'msexchPoliciesIncluded',
            'msexchRecipientDisplayType',
            'msexchRecipientTypeDetails',
            'msexchumdtmfmap',
            'msexchuseraccountcontrol',
            'msexchversion'
            'msExchRemoteRecipientType'
        )
    }
    process {
        if ($force -or $PSCmdlet.ShouldContinue($samAccountName, "Remove Exchange Attributes?")) {
            try {
                Set-AdUser -Identity $samAccountName -Clear $attributes
            } catch {
                Write-Error -Message $_.Exception.Message
            }
        }
    }
} # Remove-ExchAttributesFromUser
