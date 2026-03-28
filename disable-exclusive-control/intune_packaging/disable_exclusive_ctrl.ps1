# ==========================================
# Script Name: disable_takecontrol
# Author: Matthew Bernardin
# Version: 0.5 (Multi-device safe)
# ==========================================

# Ensure PSGallery is trusted
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue

# Install module if missing
if (-not (Get-Module -ListAvailable -Name AudioDeviceCmdlets)) {
    try {
        Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
        Write-Output "Failed to install AudioDeviceCmdlets"
        exit 1
    }
}

Import-Module AudioDeviceCmdlets -ErrorAction Stop

$key = "b3f8fa53-0004-438e-9003-51a46e139bfc"

# Base registry paths
$basePaths = @{
    Playback = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Playback"
    Capture  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"
}

$allDevicePaths = @()

# Enumerate ALL devices (Playback + Recording)
foreach ($type in $basePaths.Keys) {
    $basePath = $basePaths[$type]

    try {
        $devices = Get-ChildItem -Path $basePath -ErrorAction Stop

        foreach ($device in $devices) {
            $propertiesPath = Join-Path $device.PSPath "Properties"
            $allDevicePaths += $propertiesPath
        }

    } catch {
        Write-Output "Failed to enumerate $type devices"
    }
}

# Remove duplicates (just in case)
$allDevicePaths = $allDevicePaths | Select-Object -Unique

# Apply setting to ALL devices
foreach ($regPath in $allDevicePaths) {
    try {
        New-ItemProperty `
            -Path $regPath `
            -Name $key `
            -Value 0 `
            -PropertyType DWORD `
            -Force `
            -ErrorAction Stop

        Write-Output "Updated: $regPath"

    } catch {
        Write-Output "Failed: $regPath"
    }
}

# Set microphone permissions (HKCU)
try {
    $micPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"

    if (-not (Test-Path $micPath)) {
        New-Item -Path $micPath -Force | Out-Null
    }

    New-ItemProperty `
        -Path $micPath `
        -Name "Value" `
        -Value "Allow" `
        -PropertyType String `
        -Force

    Write-Output "Microphone access set to Allow"

} catch {
    Write-Output "Failed to set microphone permissions"
}

exit 0