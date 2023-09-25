# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------

# Building and Push Simulated Temperature Sensor and OPC Publisher Modules to ACR
# Pull and Deploy images
Param(
  [string]
  [Parameter(mandatory=$False)]
  $ApplicationName,

  [bool]
  [Parameter(mandatory=$False)]
  $Override
)

Import-Module -Name ./modules/text-utils.psm1
Import-Module -Name ./modules/process-utils.psm1
Import-Module -Name ./modules/context-utils.psm1

if ($Null -eq (Get-Module -ListAvailable -Name powershell-yaml)) {
  Show-Title("Installing powershell-yaml module")
  Install-Module -Name powershell-yaml -Scope CurrentUser
}

# ------

$StartTime = Get-Date

Show-Title("Trying to load previous context")
$DaefContext = Get-DaefContext

Write-Information ($DaefContext | ConvertTo-Json)

if ($ApplicationName -eq '') {
    $ApplicationName = $DaefContext.ApplicationName
}

$EventHubName = "telemetry"
$EventHubNamespace = $DaefContext.EventHubNamespace -replace "-", ""
$EventHubResourceGroup = $DaefContext.ApplicationName + "-App"
$EventHubEndpoint = $DaefContext.EventHubNamespaceEndpoint
$EventHubPolicyName = "iot-edge"

$DaefContext | Add-Member -MemberType NoteProperty -Name "EventHubName" -Value $EventHubName -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "EventHubResourceGroup" -Value $EventHubResourceGroup -Force
$DaefContext | Add-Member -MemberType NoteProperty -Name "EventHubPolicyName" -Value $EventHubPolicyName -Force

Write-DaefContext $DaefContext

# -----Creating EventHub Secret
Show-Title "Creating EventHub Secret"
$EventHubKey = (az eventhubs eventhub authorization-rule keys list --resource-group $EventHubResourceGroup --namespace-name $EventHubNamespace --eventhub-name $EventHubName --name $EventHubPolicyName --query primaryConnectionString -o tsv)

$SecretName = "eh-secret"
$SecretExists = kubectl get secret $SecretName -o json --ignore-not-found=true
$CreateSecret = $True

if ($SecretExists) {
  if ($Override) {
    Write-Output "EventHub Secret already exists, overriding it"
    # Deletes secret first using kubectl
    kubectl delete secret $SecretName
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Failed to delete EventHub Secret $SecretName. Manually delete the secret and try again."
      Exit 1
    }
  } else {
    Write-Output "EventHub Secret already exists skipping creation"
    $CreateSecret = $False
  }
}

if ($CreateSecret) {
    kubectl create secret generic $SecretName `
    --from-literal=username='$ConnectionString' `
    --from-literal=password=$EventHubKey
}

# -----Installing OPC UA Broker
helm upgrade -i e4i oci://e4ipreview.azurecr.io/helm/az-e4i `
    --version 0.5.1 `
    --namespace e4i-runtime `
    --create-namespace `
    --set mqttBroker.authenticationMethod="serviceAccountToken" `
    --set mqttBroker.name="azedge-dmqtt-frontend" `
    --set mqttBroker.namespace="default" `
    --set opcPlcSimulation.deploy=true `
    --wait

# -----Installing OPC UA Connector
helm upgrade -i opcua oci://e4ipreview.azurecr.io/helm/az-e4i-opcua-connector `
    --version 0.5.1 `
    --namespace opcua `
    --create-namespace `
    --set payloadCompression="none" `
    --set opcUaConnector.settings.discoveryUrl="opc.tcp://opcplc.e4i-runtime:50000" `
    --set opcUaConnector.settings.autoAcceptUntrustedCertificates=true `
    --set mqttBroker.name="azedge-dmqtt-frontend" `
    --set mqttBroker.namespace="default" `
    --set mqttBroker.authenticationMethod="serviceAccountToken" `
    --wait

# -----Installing Helm and OPC PLC demo assets
helm install opcua-demo-assets oci://e4ipreview.azurecr.io/helm/az-e4i-demo-assets `
    --version 0.5.1 `
    --namespace opcua `
    --wait

# -----Installing Event Hub Connector
Show-Title "Installing Event Hub Connector"

$E4kValuesFile = "./e4k/values.yaml"
$Values = Get-Content $E4kValuesFile | ConvertFrom-yaml
$Values.kafka.endpoint = $EventHubEndpoint
$Values | ConvertTo-yaml | Out-File $E4kValuesFile

helm install eh-connector oci://alicesprings.azurecr.io/helm/e4kconnector --version 0.5.0 -f e4k/values.yaml

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time OPC UA Broker and Server, E4K Connectors installing: $RunningTime")
