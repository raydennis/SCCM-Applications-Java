<#	
	===========================================================================
	 Created on:   	9/1/2017 1:47 PM
	 Created by:   	Ray Dennis
	 Filename:     	RemoveJava.ps1
	 Purpose:		This module is meant to be used with SCCM to uninstall Java
	-------------------------------------------------------------------------
	 Requirements:  C:\Users\raditsvc\OneDrive\PowerShell\SCCM\GetJava.psm1
                    C:\Users\raditsvc\OneDrive\PowerShell\SCCM\CMInstallerLogging.psm1
	===========================================================================
#>

#region Write-Log
<#
.SYNOPSIS
	This function removes all installed java versions and writes logs to C:\Windows\Temp\RemoveJava.log

.EXAMPLE

.NOTES

#>

Import-Module C:\Users\raditsvc\OneDrive\PowerShell\SCCM\GetJava.psm1
Import-Module C:\Users\raditsvc\OneDrive\PowerShell\SCCM\CMInstallerLogging.psm1

Start-Log
Write-Log -Message "Attemping to remove java"

if(get-java)
{
    $javaDetails = Get-JavaDetails

    Write-Log -Message "Removing Java"
    Write-Log -Message $javaDetails

    $javaInstallerLocation = $javaDetails | Select -ExpandProperty LocalPackage
    foreach($localPackage in $javaInstallerLocation)
    {
        Start-Process 'msiexec.exe' -ArgumentList "/x $localPackage /qn" -Wait -NoNewWindow
    }

    if(get-java)
    {
        Write-Log "Java failed to uninstall" -LogLevel 3
    }
    else
    {
        Write-Log "Java uninstall succeeded" -LogLevel 1
    }

}
else
{
    Write-Log "No Java Found" -LogLevel 2
}


