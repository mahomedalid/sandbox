Function Check-Helm {
    try {
        $helmVersion = helm version --short
        Write-Host "Helm is installed (Version: $helmVersion)"
        return $True
    } catch {
        Write-Error "Helm is not installed."
        return $False
    }
}

Export-ModuleMember -Function Check-Helm

$helmInstalled = Check-Helm()

if (!$helmInstalled) {
    exit 1
}