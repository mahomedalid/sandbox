# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
  [string]
  [Parameter(mandatory = $False)]
  $ApplicationName,

  [string]
  [Parameter(mandatory=$False)]
  $ClusterName = '',

  [string]
  [Parameter(mandatory=$False)]
  $E4KVersion = '0.5.1',

  [string]
  [Parameter(mandatory=$False)]
  $E4KNamespace = 'default',

  [string]
  [Parameter(mandatory=$False)]
  $E4KReleaseTrain = 'private-preview'
)

Import-Module -Name ./modules/text-utils.psm1
Import-Module -Name ./modules/process-utils.psm1
Import-Module -Name ./modules/context-utils.psm1

if ($null -eq (Get-Module -ListAvailable -Name powershell-yaml)) {
  Show-Title("Installing powershell-yaml module")
  Install-Module -Name powershell-yaml -Scope CurrentUser
}

# ------
Show-Title("Trying to load previous context")
$DaefContext = Get-DaefContext

Write-Information ($DaefContext | ConvertTo-Json)

# If $ApplicationName is blank or null then load it from $DaefContext
if ($ApplicationName -eq '') {
  $ApplicationName = $DaefContext.ApplicationName
  $ResourceGroup = $DaefContext.ResourceGroup
} else {
  $ResourceGroup = $ApplicationName
}

Show-Title("Deploying E4K to AKS EE cluster in resource group $ResourceGroup")

$StartTime = Get-Date

if ([string]::IsNullOrEmpty($ClusterName)) {
  Show-Title("Getting name of the cluster on resource group $ApplicationName")

  # TODO: Check if this works or it is a better way
  $ClusterObject = Get-DaefClusterObject $ApplicationName

  $ClusterName = $ClusterObject.name
}

Show-Title "Azure Arc Kubernetes cluster resource name: $ClusterName"

Show-Title "Deploying E4K $E4KVersion [$E4KReleaseTrain] in the namespace $E4KNamespace"

az k8s-extension create --extension-type microsoft.alicesprings.dataplane `
  --version $E4KVersion `
  --release-namespace $E4KNamespace `
  --name e4k-extension `
  --cluster-name $ClusterName `
  --resource-group $ResourceGroup `
  --cluster-type connectedClusters `
  --release-train $E4KReleaseTrain `
  --scope cluster `
  --auto-upgrade-minor-version false `

$DaefContext | Add-Member -MemberType NoteProperty -Name "E4KVersion" -Value $E4KVersion -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "E4KNamespace" -Value $E4KNamespace -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "E4KReleaseTrain" -Value $E4KReleaseTrain -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "ClusterName" -Value $ClusterName -Force

Write-DaefContext $DaefContext

Show-Title "Deploying E4K Broker in the namespace $E4kNamespace"

kubectl apply -f e4k/e4k.yaml

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time E4K to AKS EE cluster deployment: $RunningTime")