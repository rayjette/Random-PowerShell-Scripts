Function Find-EmptyFiles
{
    <#
        .SYNOPSIS
        Finds empty files.

        .DESCRIPTION
        Finds empty files.  A file is considered empty if it has a size of 0 bytes.

        .PARAMETER Path
        The location to check for empty files.

        .PARAMETER Recurse
        If the recurse parameter is set we will check subdirectories for empty files as well.

        .EXAMPLE
        Find-EmptyFiles -Path C:
        Finds empty files in C:.

        .EXAMPLE
        Find-EmptyFiles -Path C: -Recurse
        Finds empty files in C: or any of it's subdirectories.

        .INPUTS
        None.  Find-EmptyFiles does not accept input from the pipeline.

        .OUTPUTS
        String.
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Recurse
    )

    # Parameters to Get-ChildItem
    $splat = @{
        Path = $Path
        File = $true
    } 
    if ($PSBoundParameters.ContainsKey('Recurse'))
    {
        $splat.add('Recurse', $true)
    }

    # Find files with a length of 0 and output a string contaning the full path to the file. 
    Get-ChildItem @splat | Where-Object -FilterScript {$_.Length -eq 0} | Select-Object -ExpandProperty FullName
} # Find-EmptyFiles