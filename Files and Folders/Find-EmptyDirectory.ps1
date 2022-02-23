Function Find-EmptyDirectory
{
    <#
    .SYNOPSIS
    Find empty directories

    .DESCRIPTION
    Find empty directories.

    .PARAMETER Path
    This is the path to start the search from.  This will not work if Path itself is empty.  Nothing will be output.

    .PARAMETER Recurse
    Causes the search to look at all subdirectories below path.

    .EXAMPLE
    Find-EmptyDirectory -Path C:\MyData
    Look in C:\MyData for empty directories at the current level.

    .EXAMPLE
    Find-EmptyDirectory -Path C:\MyData -Recurse
    Look for empty folders in C:\MyData and any subdirectories encountered.

    .INPUTS
    None.  Find-EmptyDirectory does not accept input from the pipeline.

    .OUTPUTS
    System.IO.DirectoryInfo
    #>
    [OutputType([System.IO.DirectoryInfo])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Recurse
    )
    # These are the parameter to Get-ChildItem
    $splat = @{
        Path = $Path
        Directory = $true
    }
    if ($PSBoundParameters.ContainsKey('Recurse'))
    {
        $splat.add('Recurse', $true)
    }

    # Loop though each directory returned by Get-ChildItem looking for those which are empty.
    foreach ($item in (Get-ChildItem @splat))
    {
        if (-not (Get-ChildItem $item.FullName))
        {
            $item
        }
    }
} # Find-EmptyDirectory