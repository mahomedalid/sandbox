# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
    [string]
    [Parameter(mandatory=$True)]
    $ApplicationName
)

Function Confirm-HelmInstalled {
    try {
        $HelmVersion = helm version --short
        Show-Title "Helm is installed (Version: $HelmVersion)"
        return $True
    } catch {
        Write-Error "Helm is not installed."
        return $False
    }
}

Function Confirm-KubeCtlInstalled {
    try {
        $Null -eq (kubectl version --client)
        Show-Title "Kubectl is installed"
        return $True
    } catch {
        Show-Title "Kubectl is not installed"
        return $False
    }
}

Function Confirm-ClusterConnection {
    $CurrentContext = (kubectl config current-context)
    Show-Title "Checking connection to the cluster. Using context $CurrentContext."
    try {
        kubectl cluster-info
        if (!$?) {
            exit 1
        }
    } catch {
        Show-Title "Failing to connect to cluster. Using context "
        return $False
    }
}

# Import text utilities module.
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\text-utils.psm1")
#Import-Module -Name (Join-Path -Path $ScriptDirectory -ChildPath "..\..\modules\check-prereqs.psm1")

Show-Title("Checking pre-reqs")

if (!(Confirm-HelmInstalled)) {
    exit 1
}

if (!(Confirm-KubeCtlInstalled)) {
    exit 1
}

if (!(Confirm-ClusterConnection)) {
    exit 1
}

Show-Title("Start removal of E4K Azure Resources: OPC UA, EventHub Connector, E4K Broker")
$StartTime = Get-Date

#=======================
# This script deletes the resource groups and service principal in the default developer environment setup (one AKS deployment and one app)
# Service Principal registration will be suspended for 30 days, but not permanently deleted.
# This means that your Azure AD quota is not released automatically.
# If you'd like to enforce permanent deletion of suspended app registrations you can use the following PowerShell script:

# Get-AzureADUser -ObjectId <your-email> |Get-AzureADUserCreatedObject -All:1| ? deletionTimestamp |% { Remove-AzureADMSDeletedDirectoryObject -Id $_.ObjectId }

#=======================

# Remove OPC UA Broker, Connector and Demo Assets
& (Join-Path -Path $ScriptDirectory -ChildPath "2-remove-opcua.ps1")

Show-Title "Waiting for 10 seconds to allow the pods to be deleted"
Start-Sleep -s 10

# Remove EventHub Connector
& (Join-Path -Path $ScriptDirectory -ChildPath "3-remove-eh-connector.ps1")

Show-Title "Waiting for 10 seconds to allow the pods to be deleted"
Start-Sleep -s 10

# Remove E4K Broker
& (Join-Path -Path $ScriptDirectory -ChildPath "4-remove-e4k-broker.ps1") -ResourceGroup $ApplicationName

#=======================

Show-Title("Deletion commands have been triggered, it might take some time before all resources are deleted. ")

$RunningTime = New-TimeSpan -Start $StartTime
Show-Title("Running time resources removal:" + $RunningTime.ToString())
