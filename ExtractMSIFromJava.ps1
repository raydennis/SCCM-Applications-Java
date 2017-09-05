#Extract-MSI-From-Java
Import-Module $PSScriptRoot..\..\..\Logging\SCCM-Logging\CMInstallerLogging.psm1

Function Extract-JavaMSI()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [string]$ExePath,
	    [Parameter(Mandatory=$True)]
        [string]$ProcessName,
        [Parameter(Mandatory=$True)]
        [string]$SCCMPackageSourcePath
    )


    $JavaExtractParent = "$ENV:UserProfile\appdata\LocalLow\Oracle\Java\"
    remove-item -Path $JavaExtractParent -Recurse -Force

    #Check if SCCM source Location exsists if not create
    if (!(Test-path -Path $SCCMPackageSourcePath))
    {
        #Directory not found, attempting to create.
        New-Item -Path $SCCMPackageSourcePath -Force -ItemType Directory -ErrorVariable $SDR
        if ($SDR)
        {
            Write-Log -Message "Failed to create temp dir $SCCMPackageSourcePath - exiting script" -LogLevel 3
            Write-Log -Message "Error: $CDR" -LogLevel 3 
            exit
        }
    }

    $ProcRunTime = Get-Date -format yyyyMMddhhmmss
    if($ExtractedDirsDate){Clear-Variable -Name ExtractedDirsDate}
    Write-Log -Message "Extracting MSI"
    start-process -FilePath $ExePath -PassThru
    Write-Log -Message "Checking for extracted MSI" 
    while ($ExtractedDirsDate -lt $procruntime)
    {
        Write-Log -Message "Still Not extracted - Wait 5s" 
        Start-sleep 5
        Write-Log -Message "Checking for extracted MSI" 
        if (Test-path -Path $JavaExtractParent)
        {
            $ExtractedDirsDate=get-date($(get-childitem -Path $JavaExtractParent | Where-Object {$_.PSIsContainer} | Sort-Object LastWriteTime -Descending | Select-Object -First 1).lastwritetime) -format yyyyMMddhhmmss
        
        }
    }
    start-sleep 3
    $ExtractedLocation = $(get-childitem -Path "$ENV:UserProfile\appdata\LocalLow\Oracle\Java\" | Where-Object {$_.PSIsContainer} | Sort-Object LastWriteTime -Descending | Select-Object -First 1).fullname
    Write-Log -Message "Extracted MSI found: $ExtractedLocation"
    Write-Log -Message "Start file copy to SCCM source location: $SCCMPackageSourcePath"    
    Copy-Item -Path "$ExtractedLocation\*.*" -Destination $SCCMPackageSourcePath -Recurse -Force
    get-process -name $ProcessName | stop-process
    Write-Log -Message "File Copy complete"  
}

If(!($NewPackages)){
Write-CMtraceLOG -logfile $LogFile -LogComponent "JavaAuto" -LogText "No new packages to download. Script will now exit."
exit
}

#Extract MSI
$ExtractedMSIs=@()
foreach ($NewPackage in $NewPackages)
{
    Write-CMtraceLOG -logfile $LogFile -LogComponent "Extract-JavaMSI" -LogText "Extract MSI"
    Extract-JavaMSI -ExePath "$TempDownloadLocation\$NewPackage.exe" -SCCMPackageSourcePath $SCCMContentLocationUNCPath\$NewPackage -ProcessName $NewPackage


    $ExtractedMSIs = $ExtractedMSIs + $(Get-ChildItem $SCCMContentLocationUNCPath\$NewPackage -Filter "*.msi*").fullname


}
Write-CMtraceLOG -logfile $LogFile -LogComponent "Extract-JavaMSI" -LogText "MSI('s) Extracted"
