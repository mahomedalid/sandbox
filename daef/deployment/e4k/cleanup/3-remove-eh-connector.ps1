# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------

# Import text utilities module.
$scriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $scriptDirectory -ChildPath "..\..\modules\text-utils.psm1")

Show-Title("Start removal of EventHub Connector")
$startTime = Get-Date

# -----Deleting Event Hub Secret
$SecretName = "eh-secret"
$SecretExists = kubectl get secret $SecretName -o json
if ($SecretExists) {
    kubectl delete secret $SecretName
}

$HelmList = helm list

if ($HelmList | Select-String -Pattern "eh-connector") {
    helm uninstall eh-connector
}
# -----Unstalling Event Hub Connector

Show-Title "Event Hub Connector removed successfully"

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time EventHub Connector removal:" + $RunningTime.ToString())
