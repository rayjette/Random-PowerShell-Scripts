Function Get-DiskUsageByDirectory
{
    <#
        .SYNOPSIS
        Retrieves information about the size of the specified directory.

        .DESCRIPTION
        Retrieves information about the size of the specified directory.
        By default any folder under the specified directory will be reported.
        The size will represent the size of the directory and it's subdirectories.

        If the -Recurse parameter is specified this retrieves information about
        the size of the specified directory and it's subdirectories.  The size
        will represent the size of the directory and not include the size
        of it's subdirectories.

        .PARAMETER Path
        The path to get size information from.

        .EXAMPLE
        Get-DiskUsage
        For each directory in path this will output the size of the directory including it's subdirectories.

        .EXAMPLE
        Get-DiskUsage -Recurse
        For each directory in path this will output the size of the directory and the subdirectories.  The size
        of the subdirectory is not included in the size of the directory as the subdirectory is also output.
    #>
    [CmdletBinding()]
    param (
        ## switch to include subdirectories in the size of each directory
        [switch] $Recurse,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $Path
    )


    if ($PSBoundParameters.ContainsKey('Recurse'))
    {
        Get-ChildItem -Directory -Path $Path -Recurse | ForEach-Object {
            [PSCustomObject]@{
                Name = $PSItem.FullName
                Size = ($PSItem | Get-ChildItem -ErrorAction 'SilentlyContinue' | Measure-Object -Sum Length -ErrorAction 'SilentlyContinue').Sum
            }
        }
    }
    else
    {
        Get-ChildItem -Directory -Path $Path | ForEach-Object {
            [PSCustomObject]@{
                Name = $PSItem.FullName
                Size = ($PSItem | Get-ChildItem -Recurse -ErrorAction 'SilentlyContinue' | Measure-Object -Sum Length -ErrorAction 'SilentlyContinue').Sum
            }
        }
    }
}
