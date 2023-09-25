# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------

Show-Title("Start removal of OPC UA Broker, Connector and Demo Assets")

# Import text utilities module.
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\text-utils.psm1")

# Remove OPC PLC Demo Assets
& (Join-Path -Path $ScriptDirectory -ChildPath "2a-remove-opcplc-demo-assets.ps1")

$HelmList = helm list

if ($HelmList | Select-String -Pattern "opcua") {
    helm uninstall opcua --namespace opcua
}

if ($HelmList | Select-String -Pattern "e4i-runtime") {
    helm uninstall e4i --namespace e4i-runtime
}

$NamespaceList = kubectl get namespaces

if ($NamespaceList | Select-String -Pattern "opcua") {
    kubectl delete namespace opcua
}

if ($NamespaceList | Select-String -Pattern "e4i-runtime") {
    kubectl delete namespace e4i-runtime
}

Show-Title "Waiting for 10 seconds to allow the releases and namespaces to be deleted"
Start-Sleep -s 10

Show-Title "OPC UA Broker and Connector removed successfully"