# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
    [string]
    [Parameter(mandatory=$False)]
    $ApplicationName
)

# Import text utilities module.
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\text-utils.psm1")
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\context-utils.psm1")

Show-Title("Start removal of Azure Resources for $ApplicationName")
$StartTime = Get-Date

#=======================
# This script deletes the resource groups and service principal in the default developer environment setup (one AKS deployment and one app)
# Service Principal registration will be suspended for 30 days, but not permanently deleted.
# This means that your Azure AD quota is not released automatically.
# If you'd like to enforce permanent deletion of suspended app registrations you can use the following PowerShell script:

# Get-AzureADUser -ObjectId <your-email> |Get-AzureADUserCreatedObject -All:1| ? deletionTimestamp |% { Remove-AzureADMSDeletedDirectoryObject -Id $_.ObjectId }

#=======================

if ($ApplicationName -eq '') {
    $DaefContext = Get-DaefContext
    $ApplicationName = $DaefContext.ApplicationName
}

Show-Title("Deleting resources of Application $ApplicationName")

# Remove E4K
& (Join-Path -Path $ScriptDirectory -ChildPath "1-remove-all-e4k-resources.ps1") -ApplicationName $ApplicationName

# Remove Platform resources
& (Join-Path -Path $ScriptDirectory -ChildPath "5-remove-platform.ps1") -ApplicationName $ApplicationName

# Remove AKSEE Resource Group
& (Join-Path -Path $ScriptDirectory -ChildPath "6-remove-aksee-resource-group.ps1") -ResourceGroup $ApplicationName

#=======================

Show-Title("Deletion commands have been triggered, it might take some time before all resources are deleted. ")

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time resources removal:" + $RunningTime.ToString())
