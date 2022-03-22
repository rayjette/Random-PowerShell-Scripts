Function Invoke-WsusResetId
{
    <#
        .SYNOPSIS
        Resets the WSUS identifiers.  This should be run after cloning or creating a virtual
        machine from template.  If the identifiers are not changed the machine will not
        show up in WSUS.
    #>
    Stop-Service -Name 'wuauserv'
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'
    @('SusClientId', 'SusClientIdValidation') | ForEach-Object {
        try
        {
            Remove-ItemProperty -Path $regPath -Name $_ -ErrorAction 'Stop' 
        }
        catch [System.Management.Automation.PSArgumentException]
        {
            Write-Warning -Message $_.Exception.Message
        }
    }
    Start-Service -Name 'wuauserv'
    Invoke-Command -ScriptBlock { wuauclt.exe /resetauthorization /detectnow }
} # Invoke-WsusResetId