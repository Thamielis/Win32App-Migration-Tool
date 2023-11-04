<#
.Synopsis
Created on:   31/10/2023
Created by:   Ben Whitmore
Filename:     Get-ContentFiles.ps1

.Description
Function to get content from the content source folder for the deployment type and copy it to the content destination folder

.PARAMETER LogId
The component (script name) passed as LogID to the 'Write-Log' function. 
This parameter is built from the line number of the call from the function up the

.PARAMETER Source
The source folder to copy content from

.PARAMETER Destination
The destination folder to copy content to
#>
function Get-ContentFiles {
    param (
        [Parameter(Mandatory = $false, ValuefromPipeline = $false, HelpMessage = "The component (script name) passed as LogID to the 'Write-Log' function")]
        [string]$LogId = $($MyInvocation.MyCommand).Name,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 0, HelpMessage = 'Content path for intent to install')]
        [string]$InstallContent,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 1, HelpMessage = 'Content path for intent to uninstall')]
        [string]$UninstallContent,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 2, HelpMessage = 'The id of the application for the deployment type to get content for')]
        [string]$ApplicationId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 3, HelpMessage = 'The logical name of the deployment type to get content for')]
        [string]$DeploymentTypeLogicalName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 4, HelpMessage = 'The name of the deployment type to get content for')]
        [string]$DeploymentTypeName
    )

    Write-Log -Message "Function: Get-ContentFiles was called" -LogId $LogId

    # Add padding to the source and destination paths
    Write-Log -Message ("Padding '{0}' in case content path has spaces. Note: Robocopy demands space at end of source string" -f $Source) -LogId $LogId
    $sourcePadded = "`"" + $Source + " `""

    Write-Log -Message ("Padding '{0}' in case content path has spaces. Note: Robocopy demands space at end of source string" -f $Destination) -LogId $LogId
    $DestinationPadded = "`"" + $Destination + " `""

    try {
        Write-Log -Message ("Invoking robocopy.exe '{0}' '{1}' /MIR /E /Z /R:5 /W:1 /NDL /NJH /NJS /NC /NS /NP /V /TEE  /UNILOG+:'{2}'" -f $sourcePadded, $destinationPadded, $uniLog)-LogId $LogId 
        
        $args = @(
            $SourcePadded
            $DestinationPadded
            /MIR
            /E
            /Z
            /R:5
            /W:1
            /NDL
            /NJH
            /NJS
            /NC
            /NS
            /NP
            /V
            /TEE
            /UNILOG+:$uniLog
        )

        # Invoke robocopy.exe
        Start-Process Robocopy.exe -ArgumentList $args -Wait -NoNewWindow -PassThru 

        if ((Get-ChildItem -Path $destination | Measure-Object).Count -eq 0 ) {

            Write-Log -Message ("Error: Could not transfer content from '{0}' to '{1}'" -f $source, $destination) -LogId $LogId
            Write-Warning -Message ("Error: Could not transfer content from '{0}' to '{1}'" -f $source, $destination)
        }
    }
    catch {
        Write-Log -Message ("Error: Could not transfer content from '{0}' to '{1}'" -f $source, $destination) -LogId $LogId
        Write-Warning -Message ("Error: Could not transfer content from '{0}' to '{1}'" -f $source, $destination)
    }
}