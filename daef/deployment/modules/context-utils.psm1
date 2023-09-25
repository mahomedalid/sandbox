# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------

#.Description
# Function to get context path
Function Get-DaefContextPath {
    if ([string]::IsNullOrEmpty($Env:DAEF_CONTEXT_PATH)) {
        # Get home directory of user
        if ([string]::IsNullOrEmpty($Env:USERPROFILE)) {
            $HomeDir = "~"
        } else {
            $HomeDir = $Env:USERPROFILE
        }

        $DefaultDir = ".daef"
        $DefaultFile = "default.json"

        $DaefDirectory = Join-Path -Path $HomeDir -ChildPath $DefaultDir
        $ContextPath =  Join-Path -Path $DaefDirectory -ChildPath $DefaultFile

        return $ContextPath
    } else {
        return $Env:DAEF_CONTEXT_PATH
    }
}

#.Description
# Function to get current context config
Function Get-DaefContext {
    $ContextPath = Get-DaefContextPath
    if (Test-Path -Path $ContextPath -PathType Leaf) {
        $ContextObject = Get-Content $ContextPath | ConvertFrom-Json
    } else {
        $ContextObject = @{
            "ApplicationName" = ""
            "ResourceGroup" = ""
            "Location" = ""
            "ClusterName" = ""
        }
    }

    return $ContextObject
}

#.Description
# Function to write current context
Function Write-DaefContext([object]$ContextObject) {
    $ContextPath = Get-DaefContextPath

    # Extracts the directory from the $ContextPath and set it to $DaefDirectory
    $DaefDirectory = Split-Path -Path $ContextPath -Parent

    # Check if the .daef directory exists otherwise create the directory
    if (!(Test-Path -Path $DaefDirectory -PathType Container)) {
        New-Item -Path $DaefDirectory -ItemType Directory
    }

    $ContextObject | ConvertTo-Json | Out-File $ContextPath
}

#.Description
# Function to get cluster object from context
Function Get-DaefClusterObject([string]$ApplicationName){
    $ClusterObject =  (az connectedk8s list -g $ApplicationName --output json | ConvertFrom-Json | Select-Object -First 1)

    return $ClusterObject
}

Export-ModuleMember -Function Get-DaefContext
Export-ModuleMember -Function Get-DaefContextPath
Export-ModuleMember -Function Write-DaefContext
Export-ModuleMember -Function Get-DaefClusterObject
