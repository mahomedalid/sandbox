# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Import-Module -Name ./modules/text-utils.psm1
Import-Module -Name ./modules/context-utils.psm1

# run the proxy for the cluster
Show-Title("Trying to load previous context")
$DaefContext = Get-DaefContext

if ([string]::IsNullOrEmpty($DaefContext.ClusterName)) {
    Show-Title("Getting name of the cluster on resource group $DaefContext.ApplicationName")

    $ClusterObject = Get-DaefClusterObject $DaefContext.ApplicationName

    $DaefContext | Add-Member -MemberType NoteProperty -Name "ClusterName" -Value $ClusterObject.name -Force
    $DaefContext | Add-Member -MemberType NoteProperty -Name "ClusterLocation" -Value $ClusterObject.location -Force
    Write-DaefContext $DaefContext
}

az config set extension.use_dynamic_install=yes_without_prompt
az connectedk8s proxy -n $DaefContext.ClusterName -g $DaefContext.ResourceGroup