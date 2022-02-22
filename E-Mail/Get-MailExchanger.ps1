Function Get-MailExchanger
{
    <#
        .SYNOPSIS
        Returns the mail exchangers for one or more e-mail addresses or domains.

        .DESCRIPTION
        Returns the mail exchangers for one or more e-mail addresses or domains.

        .PARAMETER Address
        One or more e-mail address or domains.  Accepts input form the pipeline.

        .PARAMETER ServerName
        Takes the name or IP address of an optional DNS server.

        .EXAMPLE
        Get-MailExchanger -Address 'my-email@domain.com'

        .EXAMPLE
        Get-Content .\domainlist.txt | Get-MailExchanger
    
        .INPUTS
        None.  Get-MailExchanger does not accept input via the pipeline.

        .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [String[]]$address,

        [String]$ServerName
    )
    BEGIN
    {
        # Parameters for Resolve-DnsName
        $ResolveDnsNameParams = @{
            Type = 'mx'
            ErrorAction = 'SilentlyContinue'
        }
        if ($PSBoundParameters.ContainsKey('ServerName'))
        {
            $ResolveDnsNameParams.Add('Server', $ServerName)
        }
    }
    PROCESS
    {
        foreach ($item in $address)
        {
            if ($item -like "*@*")
            { 
                $Name = $($item -Split '@')[1] 
            }
            else
            { 
                $Name = $item 
            }
            $mxHost = (Resolve-DnsName -Name $Name @ResolveDnsNameParams).where({ $_.Type -eq 'mx' }).NameExchange
            if ($mxHost)
            {
                [PSCustomObject]@{
                    ExternalEmailAddress = $item
                    MailServer = $mxHost -join ', '
                }
            }
            else
            {
                write-warning -message "Failed to resolve: $($item)"
            }
        }
    }
} # Get-MailExchangerFromAddress