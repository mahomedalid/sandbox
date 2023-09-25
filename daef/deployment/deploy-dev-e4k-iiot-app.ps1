# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------

# Deploys ACR, Eventhub, and Storage Accounts
Param(
  [string]
  [Parameter(mandatory = $False)]
  $ApplicationName,

  [string]
  [Parameter(mandatory = $False)]
  $ClusterName = ''
)

Import-Module -Name ./modules/text-utils.psm1
Import-Module -Name ./modules/process-utils.psm1
Import-Module -Name ./modules/context-utils.psm1

Show-Title("Deploying ACR, EventHub, Storage Account")

if ($Null -eq (Get-Module -ListAvailable -Name powershell-yaml)) {
  Show-Title("Installing powershell-yaml module")
  Install-Module -Name powershell-yaml -Scope CurrentUser
}

# ------
$StartTime = Get-Date
$DeploymentId = Get-Random

# ------
Show-Title("Trying to load previous context")
$DaefContext = Get-DaefContext

Write-Information ($DaefContext | ConvertTo-Json)

if ($ApplicationName -eq '') {
    $ApplicationName = $DaefContext.ApplicationName
}

if ($ClusterName -eq '') {
    $ClusterName = $DaefContext.ClusterName
}

$ClusterLocation = $DaefContext.Location

if ([string]::IsNullOrEmpty($ClusterName)) {
    Show-Title("Getting name of the cluster on resource group $ApplicationName")

    $ClusterObject = Get-DaefClusterObject

    $ClusterName = $ClusterObject.name
}

# ----- Create AKS ACR Service Principals
$AcrServicePrincipalName = $ApplicationName
$SubscriptionId = (az account show --query id -o tsv)

Show-Title("Create AKS EE Service Principals: $AcrServicePrincipalName")

$SpResult = (az ad sp create-for-rbac -n $AcrServicePrincipalName --role "Contributor" --scopes /subscriptions/$SubscriptionId --only-show-errors)

if (!$?) {
    Write-Error "Error creating Service Principal on Subscription $SubscriptionId"
    Exit 1
}

$AcrServicePrincipal = $SpResult | ConvertFrom-Json

# Sleep to allow SP to be replicated across AAD instances.
# TODO: Update this to be more deterministic.
Start-Sleep -s 30

$AcrClientId = $AcrServicePrincipal.appId

# -----Deploying IIOT App Resources: ACR, EventHub, Storage Account
Show-Title "Deploying IIOT App Resources for $ApplicationName"
Show-Title "AKS ACR Service Principal Object Id: $AcrClientId"

az deployment sub create `
    --location $ClusterLocation `
    --template-file ./bicep/iiot-app.bicep `
    --parameters applicationName=$ApplicationName aksObjectId=$AcrClientId acrCreate=true location=$ClusterLocation `
    --name "dep-$DeploymentId" -o json

Show-Title "Container Deployment Id: $DeploymentId"

$EventHubNamespace = "evh" + $ApplicationName
$EventHubNamespaceEndpoint = $EventHubNamespace + ".servicebus.windows.net:9093"

$DaefContext | Add-Member -MemberType NoteProperty -Name "EventHubNamespace" -Value $EventHubNamespace -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "EventHubNamespaceEndpoint" -Value $EventHubNamespaceEndpoint -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "ClusterName" -Value $ClusterName -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "ClusterLocation" -Value $ClusterLocation -Force

Write-DaefContext $DaefContext

$RunningTime = New-TimeSpan -Start $StartTime

Show-Title("Running time ACR, Eventhub, and Storage Accounts deployment: $RunningTime")
