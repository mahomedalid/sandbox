# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
  [string]
  [Parameter(mandatory = $True)]
  $ApplicationName,

  [SecureString]
  [Parameter(mandatory = $True)]
  $VmAdminPassword,

  [string]
  [Parameter(mandatory=$False)]
  $Location = 'eastus2'
)

Import-Module -Name ./modules/context-utils.psm1 -Force
Import-Module -Name ./modules/text-utils.psm1 -Force
Import-Module -Name ./modules/process-utils.psm1 -Force

Show-Title("Install Module powershell-yaml if not yet available")
if ($null -eq (Get-Module -ListAvailable -Name powershell-yaml)) {
  Show-Title("Installing powershell-yaml module")
  Install-Module -Name powershell-yaml -Scope CurrentUser
}

# ------

Show-Title("Checking for existing context config")
$DaefContext = Get-DaefContext

# If $DaefContext.ApplicationName has some value, then ask the user if they want to continue
if ($DaefContext.ApplicationName -ne '') {
  $CurrentApplicationName = $DaefContext.ApplicationName
  Show-Title("Found existing context config for app $CurrentApplicationName.")
  $Continue = Read-Host -Prompt "If you continue will overwrite the current context config. Do you want to continue? (y/n)"
  if ($Continue -ne "y") {
    Show-Title("Exiting")
    Exit 0
  }
}

$DaefContext = @{
    "ApplicationName" = ""
}

$DaefContext.ApplicationName = $ApplicationName
$DaefContext.Location = $Location

Write-DaefContext $DaefContext

Show-Title("Start Deploying Core Infrastructure")
$StartTime = Get-Date
$DeploymentId = Get-Random

# ----- Create AKS EE Service Principals
$AkseeServicePrincipalName = $ApplicationName
$SubscriptionId = (az account show --query id -o tsv)

Show-Title("Create AKS EE Service Principals: $AkseeServicePrincipalName")

$SpResult = (az ad sp create-for-rbac -n $AkseeServicePrincipalName --role "Contributor" --scopes /subscriptions/$SubscriptionId --only-show-errors)

if (!$?) {
    Write-Error "Error creating Service Principal on Subscription $SubscriptionId"
    Exit 1
}

$AkseeServicePrincipal = $SpResult | ConvertFrom-Json

# Sleep to allow SP to be replicated across AAD instances.
# TODO: Update this to be more deterministic.
Start-Sleep -s 30

$AkseeClientId = $AkseeServicePrincipal.appId
$AkseeClientSecret = $AkseeServicePrincipal.password
$AkseeTenantId = $AkseeServicePrincipal.tenant

Show-Title("Create Resource Group $ApplicationName")

az group create --name $ApplicationName --location $Location

# ----- Deploy ARM Template
Show-Title("Deploy AKS EE ARM Template using appId {$AkseeClientId} in {$Location}")

$DeploymentName = "core-$DeploymentId"

$DaefContext.TenantId = $AkseeTenantId
$DaefContext.ResourceGroup = $ApplicationName
$DaefContext.DeploymentName = $DeploymentName

Write-DaefContext $DaefContext

$R = (az deployment group create `
    --resource-group $ApplicationName `
    --name $DeploymentName `
    --template-file ./aksee/azuredeploy.json `
    --parameters ./aksee/azuredeploy.parameters.json `
    --parameters appId="$AkseeClientId" password="$AkseeClientSecret" tenantId="$AkseeTenantId" location="$Location" adminPassword="$VmAdminPassword"`
) | ConvertFrom-Json

if ($R.properties.provisioningState -ne "Succeeded") {
    Write-Error "Deployment failed with error message: $($R.properties.error.message)"
    Exit 1
}

Show-Title "Core Infrastructure Deployment Id: $DeploymentId"

$RunningTime = New-TimeSpan -Start $StartTime

Show-Title("Running time core infra: $RunningTime")

return $DaefContext