<#	
	===========================================================================
	 Created on:   	9/1/2017 1:47 PM
	 Created by:   	Ray Dennis
	 Filename:     	GetJava.psm1
	 Purpose:		This module is meant to be imported inside an installer script
	-------------------------------------------------------------------------
	 Module Name: GetJava
	===========================================================================
#>

#region Get-Java
<#
.SYNOPSIS
	This function returns true if any version of java is istalled

.EXAMPLE
	PS C:\> Get-Java

.NOTES

#>
#region Get-JavaDetails
<#
.SYNOPSIS
	This function gets installed java versions

.EXAMPLE
	PS C:\> Get-JavaDetails

.NOTES

#>

function Get-Java
{
    if(Get-WmiObject -Namespace 'root\cimv2\sms' -Class SMS_InstalledSoftware | where { $_.ARPDisplayname -imatch 'Java' })
    {
        $true
    }
    else
    {
        $false
    }
}

function Get-JavaDetails
{
    $javaDetails = Get-WmiObject -Namespace 'root\cimv2\sms' -Class SMS_InstalledSoftware | where { $_.ARPDisplayname -imatch 'Java' } | select ProductVersion, InstalledLocation, LocalPackage
    $javaDetails
}

