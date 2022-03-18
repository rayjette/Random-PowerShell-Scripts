Function Test-RegPath($Path)
{
    <#
        .SYNOPSIS
        Test if a registry path exists.
    #>
    Test-Path -Path $Path
}


Function Test-RegValue($path, $name) # this does not work if the value of the property is 0
{
    <#
        .SYNOPSIS
        Tests if a registry value exists.
    #>
    $values = Get-Item -Path $path
    $values.property -contains $name
}


Function New-RegKey($Path, $Key)
{
    <#
        .SYNOPSIS
        Adds a new registry key.  Path must exist of New-RegKey will fail.
    #>
    # If path exists and key does not add key else return an error indicating such.
    if (Test-RegPath -Path $Path)
    {
        # If the key does not exist in path create it otherwise output a warning.
        if (-not (Test-RegPath -Path (Join-Path $Path $Key)))
        {
            New-Item -Path $Path -Name $Key | Out-Null
        }
        else
        {
            Write-Warning -Message "Key: $key already exists in path $path"    
        }
    }
    else
    {
        Write-Error -Message "Path does not exist: $($Path)"
    }
} # New-RegKey


Function New-RegValue($RegPath, $ValueName, $ValueData, $ValueType)
{
    $valueExists = Test-RegValue -path $RegPath -name $ValueName
    $oldValueData = Get-RegValue -Path $RegPath -Name $ValueName

    # If the registry value does not exist or it exists and the new
    # data differs from the original data we set the value.
    if ((-not ($valueExists)) -or ($oldValueData -ne $ValueData))
    {
        Write-Warning -Message "Setting value $($ValueName) to $($ValueData)"
        New-ItemProperty -Path $RegPath -Name $ValueName -Value $ValueData -PropertyType $ValueType -Force | Out-Null
    } 
} # New-RegValue


Function Get-RegValue($path, $name)
{
   <#
        .SYNOPSIS
        Gets the data stored in a registry value.
   #> 
   $values = Get-ItemProperty -Path $path
   $values.$name
}