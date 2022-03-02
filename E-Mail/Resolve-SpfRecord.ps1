Function Resolve-SPFRecord()
{
    <#
        .SYNOPSIS
        Outputs the SPF record for the given domain as well as the SPF record for any redirect's and or include's.

        .DESCRIPTION 
        Outputs the SPF record for the given domain as well as the SPF record for any redirect's and or include's.

        .PARAMETER DomainName
        The domain to get an SPF record for.

        .PARAMETER ServerName
        You can specify what DNS server you would like to use

        .EXAMPLE
        Resolve-SPF -DomainName myDomain.com

        .EXAMPLE
        Resolve-SPF -DomainName myDomain.com -ServerName myDnsServer

        .INPUTS
        None.  Resolve-SpfRecord does not accept pipeline input.

        .OUTPUTS
        Selected.Microsoft.DnsClient.Commands.DnsRecord_TXT.
    #>
    [CmdletBinding()]
    Param (
        # Domain Name
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$DomainName,

        # Server Name
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$ServerName
    )

    Function Resolve-SpfRecursion([String[]]$DomainName, [String]$ServerName, [String[]]$DomainsSeen = $null, [int16]$Depth = 0)
    {
        $Depth++

        $Splatting = @{Type = 'txt'}
        if ($PSBoundParameters['ServerName']) {$Splatting.add('Server', $ServerName)}

        foreach ($domain in $DomainName) {

            $queryResult = (Resolve-DnsName -Name $domain @Splatting).Where({$_.Strings -like "v=spf1*"}).Where({$DomainsSeen -notcontains $_})
            if ($Depth -eq 1) {$DomainsSeen += $domain} else {$DomainsSeen += $domainList}
            $DomainsSeen += $domain

            foreach ($result in $queryResult) {
                # base case: if there are no includes or redirects
                if (($result.Strings -notlike '*redirect=*') -and ($result.Strings -notlike '*include:*')) {
                    $result | Select-Object @{Name = 'Depth'; Expression = {$Depth}}, Name, @{Name = 'Strings'; Expression = {$_.Strings | out-string}}
                } else {
                    $result | Select-Object @{Name ='Depth'; Expression = {$Depth}}, Name, @{Name = 'Strings'; Expression = {$_.Strings | out-string}}
                    $domainList = ([regex]::split($result.Strings, ' ').Where({($_ -like "*include:*") -or ($_ -like "*redirect=*")}) -replace 'include:' -replace 'redirect=').Where({$DomainsSeen -notcontains $_})
                    Resolve-SpfRecursion -DomainName $domainList -Depth $Depth -DomainsSeen $DomainsSeen @Splatting
               }
            }
        }
        $Depth--
    } # Resolve-SpfRecursion 

    Resolve-SpfRecursion -DomainName $DomainName -ServerName $ServerName

} # Resolve-SPF