# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
    [string]
    [Parameter(mandatory=$True)]
    $ApplicationName,

    [bool]
    [Parameter(mandatory=$False)]
    $NoWait = $True
)

# Import text utilities module.
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\text-utils.psm1")

Show-Title("Start removal of platform resources: ACR, EventHub, Storage Account, App Resource Group")
$StartTime = Get-Date

$PlatformResourceGroup = "$ApplicationName-App"

# Remove app Resource Groups
# If you would like to wait for deletion of each Resource group to be completed before continuing, simply remove the --no-wait parameter
Show-Title("Removing $PlatformResourceGroup without waiting for confirmation")

if ($NoWait)
{
    az group delete --name $PlatformResourceGroup -y --no-wait
}
else
{
    az group delete --name $PlatformResourceGroup -y
}

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time platform resources removal:" + $RunningTime.ToString())
