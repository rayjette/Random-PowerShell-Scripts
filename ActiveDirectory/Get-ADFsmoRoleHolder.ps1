#Requires -Modules ActiveDirectory

Function Get-ADFsmoRoleHolder
{
    <#
        .SYNOPSIS
        Find what DC(s) the FSMO roles are running on.

        .DESCRIPTION
        Find what DC(s) the FSMO roles are running on.

        .EXAMPLE
        Get-ADFsmoRoleHolder
        Find what DC(s) the FSMO roles are running on.

        .INPUTS
        None.  Get-ADFsmoRoleHolder does not accept input from the pipeline.

        .OUTPUTS
        System.Management.Automation.PSCustomObject.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(

    )
    # Get forest wide Active Directory FSMO roles
    Write-Verbose -Message 'Getting forest roles...'
    $ForestRoles = Get-ADForest -ErrorAction 'Stop'

    # Get domain wide Active Directory FSMO roles
    Write-Verbose -Message 'Getting domain roles...'
    $DomainRoles = Get-ADDomain -ErrorAction 'Stop'

    # Create and return a PSCustomObject contaning all of the FSMO roles
    [PSCustomObject]@{
        SchemaMaster         = $ForestRoles.SchemaMaster
        DomainNamingMaster   = $ForestRoles.DomainNamingMaster
        InfrastructureMaster = $DomainRoles.InfrastructureMaster
        RIDMaster            = $DomainRoles.RIDMaster
        PDCEmulator          = $DomainRoles.PDCEmulator
    }
} # Get-ADFsmoRoleHolder