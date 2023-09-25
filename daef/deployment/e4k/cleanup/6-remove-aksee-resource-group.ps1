# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
    [string]
    [Parameter(mandatory=$True)]
    $ResourceGroup,

    [bool]
    [Parameter(mandatory=$False)]
    $NoWait = $true
)

# Import text utilities module.
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\text-utils.psm1")

Show-Title("Start removal of AKSEE Resource Group")
$StartTime = Get-Date

# Remove app Resource Groups
# If you would like to wait for deletion of each Resource group to be completed before continuing, simply remove the --no-wait parameter
Show-Title("Removing $ResourceGroup without waiting for confirmation")

if ($NoWait)
{
    az group delete --name $ResourceGroup -y --no-wait
}
else
{
    az group delete --name $ResourceGroup -y
}

# Remove Service Principals

Show-Title("Delete AKS EE Service Principal, app registration will be suspended for 30 days")

$AksServicePrincipal = az ad sp list --filter ("displayname eq '$ResourceGroup'") | ConvertFrom-Json

Show-Title("AKS Service Principal: " + $AksServicePrincipal.appId)

az ad sp delete --id $AksServicePrincipal.appId

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time aksee resources removal:" + $RunningTime.ToString())
