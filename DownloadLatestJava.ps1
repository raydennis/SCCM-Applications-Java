<#	
	===========================================================================
	 Created on:   	9/1/2017 1:47 PM
	 Created by:   	Ray Dennis
     Seed taken from:  http://servertechs.info/automating-java-download-and-deployment-with-powershell-and-sccm/
	 Filename:     	DownloadLatestJava.ps1
	 Purpose:		This script will download the latest version of Java
	-------------------------------------------------------------------------
	 Script Name: Download Latest Java
	===========================================================================
#>

#region DownloadLatestJava
<#
.SYNOPSIS
	This function returns true if any version of java is istalled

.EXAMPLE
	PS C:\> Get-Java

.NOTES

#>
#region Function CheckHistory
<#
.SYNOPSIS
	Function to check script history

.EXAMPLE
	PS C:\> CheckHistory $fileurl

.NOTES

#>

Import-Module $PSScriptRoot..\..\..\Logging\SCCM-Logging\CMInstallerLogging.psm1

$TempDownloadLocation = "C:\Temp\Temp"

#Function to check script history
Function CheckHistory ($fileurl){
    $history=Get-Content "$TempDownloadLocation\javahistorylog.log"
    Foreach ($historicurl in $history){

        if ($historicurl -eq $fileurl){
            Write-Host "Historic download for $historicurl found. Skipping download." -ForegroundColor Red
            Return $true
        }
    }
    return $false
    
}

Start-Log

$Links=$(Invoke-WebRequest http://www.java.com/en/download/manual.jsp -UserAgent "Mozilla/5.0 (Windows NT 6.1; wow64)").links | where innerHTML -like "Windows Offline*" | select href, innerHTML

#Loop round each link from java page
foreach($Link in $Links){

    #Check if we already have this version downloaded if yes skip
    $check = $false
    $check=CheckHistory $Link.href
    If($check){continue}

    Write-Log -Message "Downloading:$Link.href"
     
    #Download to temp file
    $TempFileName = "tempinstaller$(get-date -Format yyddMMhhmmssmm).exe"
    Write-Log -Message "Temp download file: $TempFileName"
    Invoke-WebRequest $Link.href -OutFile "$TempDownloadLocation\$TempFileName" -ev $DLErr
    if($DLErr)
    {
        Write-Log -Message "Download Failed" -LogLevel 3
        Write-Log -Message "Error: $DLErr" -LogLevel 3
        Write-Log -Message "Skipping file" -LogLevel 3
        Continue
    }
    Write-Log -Message "Getting Java Version"
    $fileversion=get-item "$TempDownloadLocation\$TempFileName" | select -ExpandProperty versioninfo | select -ExpandProperty productversion
    $JavaVersion=$fileversion
    Write-Log -Message "Java Version: $fileversion"
    Write-Log -Message "Getting architecture"
    if ($Link.innerHTML -like "*64*")
    {
        $fileversion = $fileversion+"_x64"
        Write-Log -Message "Architecture: x64"
    }
    else 
    {
        $fileversion = $fileversion+"_x86"
        Write-Log -Message "Architecture: x86"
    }
    
    #check if file already exsist, if so add to history file and skip to the next link
    Write-Log -Message "Check if file already exsists"
    if(Test-Path -path "$TempDownloadLocation\$fileversion.exe")
    {
        Write-Log -Message "File ($fileversion.exe) already exists, skipping file"
        Remove-Item "$TempDownloadLocation\$TempFileName"
        add-content "$TempDownloadLocation\javahistorylog.log" $Link.href
        $NewPackages= $NewPackages + $fileversion
        write-host "1"
        continue
    }
    
    #Rename from temp name + add to history file
    Write-Log -Message "Rename temp file:$TempFileName to $fileversion.exe"
    Rename-Item -Path "$TempDownloadLocation\$TempFileName" -NewName "$fileversion.exe"
    Write-Log -Message "Update history file"
    if(Test-Path -path "$TempDownloadLocation\$fileversion.exe"){add-content "$TempDownloadLocation\javahistorylog.log" $Link.href}
    if(Test-Path -Path "$TempDownloadLocation\$TempFileName"){Remove-Item "$TempDownloadLocation\$TempFileName"}
    Write-Log -Message "Add file to array for further processing"
    $NewPackages= $NewPackages + $fileversion
}