﻿<#
.Synopsis
Created on:   14/03/2021
Updated on:   06/11/2023
Created by:   Ben Whitmore
Filename:     New-Win32App.ps1

The Win32 App Migration Tool is designed to inventory ConfigMgr Applications and Deployment Types, build .intunewin files and create Win3Apps in The Intune Admin Center.

.Description
**Version 1.103.12.01 - 12/03/2022 - BETA**  
- Added UTF8 Encoding for CSV Exports https://github.com/byteben/Win32App-Migration-Tool/issues/6
- Added option to exclude PMPC apps https://github.com/byteben/Win32App-Migration-Tool/issues/5
- Added option to exclude specific apps using a filter

**Version 1.08.29.02 - 29/08/2021 - BETA**  
- Fixed an issue where logos were not being exported
- Fixed an issue where the Localized Display Name was not outputed correctly

**Version 1.08.29.01 - 29/08/2021 - BETA**  
- Default to not copy content locally.
- Use -DownloadContent switch to copy content to local working folder
- Fixed an issue when the source content folder has a space in the path

**Version 1.03.27.02 - 27/03/2021 - BETA**  
- Fixed a grammar issue when creating the Working Folders

**Version 1.03.25.01 - 25/03/2021 - BETA**  
- Removed duplicate name in message for successful .intunewin creation
- Added a new switch "-NoOGV" which will suppress the Out-Grid view. Thanks @philschwan
- Fixed an issue where the -ResetLog parameter was not working

**Version 1.03.23.01 - 23/03/2021 - BETA**  
- Error handling improved when connecting to the Site Server and passing a Null app name

**Version 1.03.22.01 - 22/03/2021 - BETA**  
- Updates Manifest to only export New-Win32App Function

**Version 1.03.21.03 - 21/03/2021 - BETA**  
- Fixed RootModule issue in psm1

**Version 1.03.21.03 - 21/03/2021 - BETA**  
- Fixed Function error for New-Win32App

**Version 1.03.21.01 - 21/03/2021 - BETA**  
- Added to PSGallery and converted to Module

**Version 1.03.20.01 - 20/03/2021 - BETA**  
- Added support for .vbs script installers  
- Fixed logic error for string matching  
    
**Version 1.03.19.01 - 19/03/2021 - BETA**    
- Added Function Get-ScriptEnd  
  
**Version 1.03.18.03 - 18/03/2021 - BETA**   
- Fixed an issue where Intunewin SetupFile was being detected as an .exe when msiexec was present in the install command  
  
**Version 1.03.18.02 - 18/03/2021 - BETA**   
- Removed the character " from SetupFile command when an install command is wrapped in double quotes  
  
**Version 1.03.18.01 - 18/03/2021  - BETA**  
- Robocopy for content now padding Source and Destination variables if content path has white space  
- Deployment Type Count was failing from the SDMPackageXML. Using the measure tool to check if Deployment Types exist for an Application  
- Removed " from SetupFile command if install commands are in double quotes  
  
**Version 1.03.18 - 18/03/2021  - BETA**
- Release for Testing  
- Logging Added  

**Version 1.0 - 14/03/2021 - DEV**  
- DEV Release  

.PARAMETER LogId
The component (script name) passed as LogID to the 'Write-Log' function.

.PARAMETER AppName
Pass a string to the toll to search for applications in ConfigMgr

.PARAMETER DownloadContent
When passed, the content for the deployment type is saved locally to the working folder "Content"

.PARAMETER SiteCode
Specify the Sitecode you wish to connect to

.PARAMETER ProviderMachineName
Specify the Site Server to connect to

.PARAMETER ExportIcon
When passed, the Application icon is decoded from base64 and saved to the Logos folder

.PARAMETER WorkingFolder
This is the working folder for the Win32AppMigration Tool. 
Note: Care should be given when specifying the working folder because downloaded content can increase the working folder size considerably

.PARAMETER PackageApps
Pass this parameter to package selected apps in the .intunewin format

.PARAMETER CreateApps
Pass this parameter to create the Win32apps in Intune

.PARAMETER ResetLog
Pass this parameter to reset the log file

.PARAMETER ExcludePMPC
Pass this parameter to exclude apps created by PMPC from the results. Filter is applied to Application "Comments". String can be modified in Get-AppList Function

.PARAMETER ExcludeFilter
Pass this parameter to exclude specific apps from the results. String value that accepts wildcards e.g. "Microsoft*"

.PARAMETER Win32ContentPrepToolUri
URI for Win32 Content Prep Tool

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *"

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -DownloadContent

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps -CreateApps

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps -CreateApps -ResetLog

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps -CreateApps -ResetLog -ExcludePMPC

.EXAMPLE
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps -CreateApps -ResetLog -ExcludePMPC -ExcludeFilter "Microsoft*"
#>
function New-Win32App {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValuefromPipeline = $false, HelpMessage = "The component (script name) passed as LogID to the 'Write-Log' function")]
        [string]$LogId = $($MyInvocation.MyCommand).Name,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 0, HelpMessage = 'The Site Code of the ConfigMgr Site')]
        [ValidatePattern('(?##The Site Code must be only 3 alphanumeric characters##)^[a-zA-Z0-9]{3}$')]
        [String]$SiteCode,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 1, HelpMessage = 'Server name that has an SMS Provider site system role')]
        [String]$ProviderMachineName,  
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 2, HelpMessage = 'The name of the application to search for. Accepts wildcards *')]
        [String]$AppName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = 'DownloadContent: When passed, the content for the deployment type is saved locally to the working folder "Content"')]
        [Switch]$DownloadContent,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = 'ExportLogo: When passed, the Application icon is decoded from base64 and saved to the Logos folder')]
        [Switch]$ExportIcon,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 3, HelpMessage = 'The working folder for the Win32AppMigration Tool. Care should be given when specifying the working folder because downloaded content can increase the working folder size considerably')]
        [String]$workingFolder = "C:\Win32AppMigrationTool",
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = 'PackageApps: Pass this parameter to package selected apps in the .intunewin format')]
        [Switch]$PackageApps,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = 'CreateApps: Pass this parameter to create the Win32apps in Intune')]
        [Switch]$CreateApps,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = 'ResetLog: Pass this parameter to reset the log file')]
        [Switch]$ResetLog,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = 'ExcludePMPC: Pass this parameter to exclude apps created by PMPC from the results. Filter is applied to Application "Comments". String can be modified in Get-AppList Function')]
        [Switch]$ExcludePMPC,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 4, HelpMessage = 'ExcludeFilter: Pass this parameter to exclude specific apps from the results. String value that accepts wildcards e.g. "Microsoft*"')]
        [String]$ExcludeFilter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = 'NoOGV: When passed, the Out-Gridview is suppressed')]
        [Switch]$NoOgv,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 5, HelpMessage = 'URI for Win32 Content Prep Tool')]
        [String]$Win32ContentPrepToolUri = 'https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe'
    )

    # Create global variable(s) 
    $global:workingFolder_Root = $workingFolder

    #region Prepare_Workspace
    # Initialize folders to prepare workspace for logging
    Write-Host "Initializing required folders..." -ForegroundColor Cyan

    foreach ($folder in $workingFolder_Root, "$workingFolder_Root\Logs") {
        if (-not (Test-Path -Path $folder)) {
            Write-Host ("Working folder root does not exist at '{0}'. Creating environemnt..." -f $folder) -ForegroundColor Cyan
            New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        else {
            Write-Host ("Folder '{0}' already exists. Skipping folder creation" -f $folder) -ForegroundColor Yellow
        }
    }

    # Rest the log file if the -ResetLog parameter is passed
    if ($ResetLog -and (Test-Path -Path "$workingFolder_Root\Logs") ) {
        Write-Log -Message $null -ResetLogFile
    }
    #endregion

    # Begin Script
    New-VerboseRegion -Message 'Start Win32AppMigrationTool' -ForegroundColor 'Gray'

    $ScriptRoot = $PSScriptRoot
    Write-Log -Message ("ScriptRoot is '{0}'" -f $ScriptRoot) -LogId $LogId

    # Connect to Site Server
    Connect-SiteServer -SiteCode  $SiteCode -ProviderMachineName $ProviderMachineName

    # Check the folder structure for the working directory and create if necessary
    New-VerboseRegion -Message 'Checking Win32AppMigrationTool folder structure' -ForegroundColor 'Gray'

    #region Create_Folders
    Write-Host "Creating additionl folders..." -ForegroundColor Cyan
    Write-Log -Message ("New-FolderToCreate -Root '{0}' -FolderNames @('Icons', 'Content', 'ContentPrepTool', 'Details', 'Win32Apps')" -f $workingFolder_Root) -LogId $LogId
    New-FolderToCreate -Root $workingFolder_Root -FolderNames @('Icons', 'Content', 'ContentPrepTool', 'Details', 'Win32Apps')
    #endRegion

    #region Get_Content_Tool
    New-VerboseRegion -Message 'Checking if the Win32contentpreptool is required' -ForegroundColor 'Gray'

    # Download the Win32 Content Prep Tool if the PackageApps parameter is passed
    if ($PackageApps) {
        Write-Host "Downloading the Win32contentpreptool..." -ForegroundColor Cyan
        if (Test-Path (Join-Path -Path "$workingFolder_Root\ContentPrepTool" -ChildPath "IntuneWinAppUtil.exe")) {
            Write-Log -Message ("Information: IntuneWinAppUtil.exe already exists at '{0}'. Skipping download" -f "$workingFolder_Root\ContentPrepTool") -LogId $LogId -Severity 2
            Write-Host ("Information: IntuneWinAppUtil.exe already exists at '{0}'. Skipping download" -f "$workingFolder_Root\ContentPrepTool") -ForegroundColor Yellow
        }
        else {
            Write-Log -Message ("Get-FileFromInternet -URI '{0} -Destination {1}" -f $Win32ContentPrepToolUri, "$workingFolder_Root\ContentPrepTool") -LogId $LogId
            Get-FileFromInternet -Uri $Win32ContentPrepToolUri -Destination "$workingFolder_Root\ContentPrepTool"
        }
    } 
    else {
        Write-Log -Message "The 'PackageApps' parameter was not passed. Skipping downloading of the Win32 Content Prep Tool" -LogId $LogId -Severity 2
        Write-Host "The 'PackageApps' parameter was not passed. Skipping downloading of the Win32 Content Prep Tool" -ForegroundColor Yellow
    }
    #endRegion


    #region Display_Application_Results
    New-VerboseRegion -Message 'Filtering application results' -ForegroundColor 'Gray'

    # Build a hash table of switch parameters to pass to the Get-AppList function
    $paramsToPassApp = @{}
    if ($ExcludePMPC) {
        $paramsToPassApp.Add('ExcludePMPC', $true) 
        Write-Log -Message "The ExcludePMPC parameter was passed. Ignoring all PMPC created applications" -LogId $LogId -Severity 2
        Write-Host "The ExcludePMPC parameter was passed. Ignoring all PMPC created applications" -ForegroundColor Cyan
    }
    if ($ExcludeFilter) {
        $paramsToPassApp.Add('ExcludeFilter', $ExcludeFilter) 
        Write-Log -Message ("The 'ExcludeFilter' parameter was passed. Ignoring applications that match '{0}'" -f $ExcludeFilter) -LogId $LogId -Severity 2
        Write-Host ("The 'ExcludeFilter' parameter was passed. Ignoring applications that match '{0}'" -f $ExcludeFilter) -ForegroundColor Cyan
    }
    if ($NoOGV) {
        $paramsToPassApp.Add('NoOGV', $true) 
        Write-Log -Message "The 'NoOgv' parameter was passed. Suppressing Out-GridView" -LogId $LogId -Severity 2   
        Write-Host "The 'NoOgv' parameter was passed. Suppressing Out-GridView" -ForegroundColor Cyan
    }

    Write-Log -Message ("Running function 'Get-AppList' -AppName '{0}'" -f $AppName) -LogId $LogId
    Write-Host ("Running function 'Get-AppList' -AppName '{0}'" -f $AppName) -ForegroundColor Cyan

    $applicationName = Get-AppList -AppName $AppName @paramsToPassApp
 
    # ApplicationName(s) returned from the Get-AppList function
    if ($applicationName) {
        Write-Log -Message "The Win32App Migration Tool will process the following applications:" -LogId $LogId
        Write-Host "The Win32App Migration Tool will process the following applications:" -ForegroundColor Cyan
        
        foreach ($application in $ApplicationName) {
            Write-Log -Message ("Id = '{0}', Name = '{1}'" -f $application.Id, $application.LocalizedDisplayName) -LogId $LogId
            Write-Host ("Id = '{0}', Name = '{1}'" -f $application.Id, $application.LocalizedDisplayName) -ForegroundColor Green
        }
    }
    else {
        Write-Log -Message ("There were no applications found that match the crieria '{0}' or the Out-GrideView was closed with no selection made. Cannot continue" -f $AppName) -LogId $LogId -Severity 3
        Write-Warning -Message ("There were no applications found that match the crieria '{0}' or the Out-GrideView was closed with no selection made. Cannot continue" -f $AppName)
        Get-ScriptEnd
    }
        
    #endRegion

    #region Get_App_Details
    New-VerboseRegion -Message 'Getting application details' -ForegroundColor 'Gray'

    # Calling function to grab application details
    Write-Log -Message "Calling 'Get-AppInfo' function to grab application details" -LogId $LogId
    Write-Host "Calling 'Get-AppInfo' function to grab application details" -ForegroundColor Cyan

    $app_Array = Get-AppInfo -ApplicationName $applicationName
    #endregion

    #region Get_DeploymentType_Details
    New-VerboseRegion -Message 'Getting deployment type details' -ForegroundColor 'Gray'

    # Calling function to grab deployment types details
    Write-Log -Message "Calling 'Get-DeploymentTypeInfo' function to grab deployment type details" -LogId $LogId
    Write-Host "Calling 'Get-DeploymentTypeInfo' function to grab deployment type details" -ForegroundColor Cyan
    
    $deploymentTypes_Array = foreach ($app in $app_Array) { Get-DeploymentTypeInfo -ApplicationId $app.Id }
    #endregion

    #region Get_DeploymentType_Content
    New-VerboseRegion -Message 'Getting deployment type content information' -ForegroundColor 'Gray'
  
    # Calling function to grab deployment type content information
    Write-Log -Message "Calling 'Get-ContentFiles' function to grab deployment type content" -LogId $LogId
    Write-Host "Calling 'Get-ContentFiles' function to grab deployment type content" -ForegroundColor Cyan
            
    $content_Array = foreach ($deploymentType in $deploymentTypes_Array) { 
    
        # Build or reset a hash table of switch parameters to pass to the Get-ContentFiles function
        $paramsToPassContent = @{}
    
        if ($deploymentType.InstallContent) { $paramsToPassContent.Add('InstallContent', $deploymentType.InstallContent) }
        $paramsToPassContent.Add('UninstallSetting', $deploymentType.UninstallSetting)
        if ($deploymentType.UninstallContent) { $paramsToPassContent.Add('UninstallContent', $deploymentType.UninstallContent) }
        $paramsToPassContent.Add('ApplicationId', $deploymentType.Application_Id)
        $paramsToPassContent.Add('ApplicationName', $deploymentType.ApplicationName)
        $paramsToPassContent.Add('DeploymentTypeLogicalName', $deploymentType.LogicalName)
        $paramsToPassContent.Add('DeploymentTypeName', $deploymentType.Name)
    
        # If we have content, call the Get-ContentInfo function
        if ($deploymentType.InstallContent -or $deploymentType.UninstallContent) { Get-ContentInfo @paramsToPassContent }
    }

    # If $DownloadContent was passed, download content to the working folder
    New-VerboseRegion -Message 'Copying content files' -ForegroundColor 'Gray'

    if ($DownloadContent) {
        Write-Log -Message "The 'DownloadContent' parameter passed" -LogId $LogId

        foreach ($content in $content_Array) {
            Get-ContentFiles -Source $content.Install_Source -Destination $content.Install_Destination

            # If the uninstall content is different to the install content, copy that too
            if ($content.Uninstall_Setting -eq 'Different') {
                Get-ContentFiles -Source $content.Uninstall_Source -Destination $content.Uninstall_Destination -Flags 'UninstallDifferent'
            }
        }  
    }
    else {
        Write-Log -Message "The 'DownloadContent' parameter was not passed. Skipping content download" -LogId $LogId -Severity 2
        Write-Host "The 'DownloadContent' parameter was not passed. Skipping content download" -ForegroundColor Yellow
    }
    #endregion
    
    #region Exporting_Csv data
    # Export $DeploymentTypes to CSV for reference
    New-VerboseRegion -Message 'Exporting collected data to Csv' -ForegroundColor 'Gray'
    $detailsFolder = (Join-Path -Path $workingFolder_Root -ChildPath 'Details')

    Write-Log -Message ("Destination folder will be '{0}\Details" -f $workingFolder_Root) -LogId $LogId -Severity 2
    Write-Host ("Destination folder will be '{0}\Details" -f $workingFolder_Root) -ForegroundColor Cyan

    # Export application information to CSV for reference
    Export-CsvDetails -Name 'Applications' -Data $app_Array -Path $detailsFolder

    # Export deployment type information to CSV for reference
    Export-CsvDetails -Name 'DeploymentTypes' -Data $deploymentTypes_Array -Path $detailsFolder

    # Export content information to CSV for reference
    Export-CsvDetails -Name 'Content' -Data $content_Array -Path $detailsFolder
    #endregion

    #region Exporting_Logos
    # Export icon(s) for the applications
    New-VerboseRegion -Message 'Exporting icon(s)' -ForegroundColor 'Gray'

    if ($ExportIcon) {
        Write-Log -Message "The 'ExportIcon' parameter passed" -LogId $LogId

        foreach ($applicationIcon in $app_Array) {
            Write-Log -Message ("Exporting icon for '{0}' to '{1}'" -f $applicationIcon.Name, $applicationIcon.IconPath) -Logid $LogId
            Write-Host ("Exporting icon for '{0}' to '{1}'" -f $applicationIcon.Name, $applicationIcon.IconPath) -ForegroundColor Cyan

            Export-Icon -AppName $applicationIcon.Name -IconPath $applicationIcon.IconPath -IconData $applicationIcon.IconData
        }
    }
    else {
        Write-Log -Message "The 'ExportIcon' parameter was not passed. Skipping icon export" -LogId $LogId -Severity 2
        Write-Host "The 'ExportIcon' parameter was not passed. Skipping icon export" -ForegroundColor Yellow
    }
    #endregion

    #region Package_Apps
    # If the $PackageApps parameter was passed. Use the Win32Content Prep Tool to build Intune.win files
    New-VerboseRegion -Message 'Creating folders(s) for intunewin files' -ForegroundColor 'Gray'

    if ($PackageApps) {

        # Creating folders for IntuneWin files
        Write-Log -Message "The 'PackageApps' Parameter passed" -LogId $LogId

        foreach ($deploymentTypeWin in $deploymentTypes_Array) {
            $intuneWinPath = Join-Path -Path 'Win32Apps' -ChildPath (Join-Path -Path $deploymentTypeWin.ApplicationName -ChildPath $deploymentTypeWin.Name)

            if (-not (Test-Path -Path (Join-Path -Path $workingFolder_Root -ChildPath $intuneWinPath) ) ) {
                New-FolderToCreate -Root $WorkingFolder_Root -FolderNames $intuneWinPath
            }
break
            # Create intunewin files
            New-VerboseRegion -Message 'Creating intunewin files' -ForegroundColor 'Gray'
            Write-Log -Message ("Creating intunewin file for '{0}'" -f $deploymentTypeWin.Name) -LogId $LogId
            Write-Host ("Creating intunewin file for '{0}'" -f $deploymentTypeWin.Name) -ForegroundColor Cyan
            
            New-IntuneWin -ContentFolder $ContentFolder -OutputFolder (Join-Path -Path $workingFolder_Root -ChildPath $intuneWinPath) -SetupFile $SetupFile
        }

    }
    else {
        Write-Log -Message "The 'PackageApps' parameter was not passed. Intunewin files will not be created" -LogId $LogId -Severity 2
        Write-Host "The 'PackageApps' parameter was not passed. Intunewin files will not be created" -ForegroundColor Yellow
    }
    #endRegion

    Get-ScriptEnd
}