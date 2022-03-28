#Requires -Modules ExchangeOnlineManagement

Function Find-UnifiedGroupsWithNoOwner
{
    <#
        .SYNOPSIS
        Find groups in Office 365 that do not have an owner defined.
    #>
    # Make sure Exchange Online cmdlets are loaded
    if (-not (Get-Command Get-UnifiedGroup -ErrorAction 'SilentlyContinue'))
    {
        throw 'Make sure you are connected to ExchangeOnline by using Connect-ExchangeOnline and then re-run this script..'
    }

    # Save groups to variable
    $groups = Get-UnifiedGroup -ResultSize 'unlimited'

    # Return groups with out an owner
    $groups.where({-not $PSItem.ManagedBy})
}