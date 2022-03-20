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

        .PARAMETER Unit
        The unit size will be reported as.  Accepted values are TB, GB, MB, and KB.

        .EXAMPLE
        Get-DiskUsage -Path C:\
        For each directory in path this will output the size of the directory including it's subdirectories.

        .EXAMPLE
        Get-DiskUsage -Path C:\ -Recurse
        For each directory in path this will output the size of the directory and the subdirectories.  The size
        of the subdirectory is not included in the size of the directory as the subdirectory is also output.
    #>
    [CmdletBinding()]
    param (
        ## switch to include subdirectories in the size of each directory
        [switch] $Recurse,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $Path,

        [ValidateSet('TB', 'GB', 'MB', 'KB')]
        [string] $Unit
    )

    Function Format-Size($Size, $Unit, $PlacesAfterDecimal)
    {
        <#
            .SYNOPSIS
            Converts Bytes into the specified unit
        #>
        [math]::round($Size / "1$Unit", $PlacesAfterDecimal)
    }

    # Setup parameter for Get-ChildItem
    $GetChildItemSplat = @{
        Directory = $true
        Path      = $Path
    }
    $GetChildItemSizeSplat = @{
        ErrorAction = 'SilentlyContinue'
    }

    # If the recurse parameter was specified we add recurse to the Get-ChildItem to get the directories
    # in path.  If the recurse parameter was not specified we add recurse to the Get-ChildItem used to
    # get the disk space so we can account for the space used by subdirectories.
    if ($PSBoundParameters.ContainsKey('Recurse'))
    {
        $GetChildItemSplat.add('Recurse', $true)
    }
    else
    {
        $GetChildItemSizeSplat.add('Recurse', $true)
    }

    # Get size of directories in path.
    Get-ChildItem @GetChildItemSplat | ForEach-Object {
        Write-Progress -Activity "Getting Size for $($PSItem.FullName)"
        $Size = ($PSItem | Get-ChildItem @GetChildItemSizeSplat | Measure-Object -Sum Length -ErrorAction 'SilentlyContinue').Sum
        if ($PSBoundParameters.ContainsKey('Unit'))
        {
            $Size = Format-Size -Size $Size -Unit $Unit -PlacesAfterDecimal 2
        }
        [PSCustomObject]@{
            Directory = $PSItem.FullName
            "Size$Unit" = $Size
        }
    }
}