# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------

# Import text utilities module.
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\text-utils.psm1")

Show-Title("This stops messages from being sent from the thermostat")

$HelmList = helm list

if ($HelmList | Select-String -Pattern "opcua-demo-assets") {
    helm uninstall opcua-demo-assets --namespace opcua
}

Show-Title "OPC PLC Demo Assets removed successfully"