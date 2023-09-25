# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------

#.Description
# Function that shows inputted text with predefined format
Function Show-Title ([string]$Text) {
    $Width = (Get-Host).UI.RawUI.WindowSize.Width
    $Title = ""
    if($Text.length -ne 0)
    {
        $Title = "=[ " + $Text + " ]="
    }

    Write-Host $Title.PadRight($Width, "=") -ForegroundColor green
}

#.Description
# Function that returns decoded token
Function Get-DecodedToken([string]$Path)
{
    $TokenB64 = Get-Content -Path $Path
    $DecodedToken = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($TokenB64))))

    return $DecodedToken
}

Export-ModuleMember -Function Show-Title
Export-ModuleMember -Function Get-DecodedToken