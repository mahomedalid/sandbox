# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
    [string]
    [Parameter(mandatory=$True)]
    $ResourceGroup
)

# Import text utilities module.
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\text-utils.psm1")

Show-Title("Start removal of E4K Broker")
$StartTime = Get-Date

# Remove E4K deployment
Show-Title "Removing E4K deployment"
kubectl delete -f (Join-Path -Path $ScriptDirectory -ChildPath "..\e4k.yaml")

$ClusterName = az resource list `
    --resource-group $ResourceGroup `
    --resource-type "Microsoft.Kubernetes/connectedClusters" `
    --query "[?contains(name, '$ResourceGroup')].name" --output tsv

if (-not $ClusterName) {
    Write-Error "Could not retrieve cluster name  (Microsoft.Kubernetes/connectedClusters ) from the resource group $Resourcegroup"
    exit 1
}

Show-Title "Deleting K8sExtension from cluster $ClusterName in resource group $ResourceGroup"
az k8s-extension delete --name e4k-extension --resource-group $ResourceGroup --cluster-name $ClusterName --cluster-type connectedClusters --yes

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time e4k broker removal:" + $RunningTime.ToString())
