# ==========================================
# Script Name: disable_takecontrol
# Author: Matthew Bernardin
# Version: 0.8 - Release Candidate 2
# ==========================================

#Requires -RunAsAdministrator

# Ensure PSGallery is trusted
Set-PSRepository `
    -Name "PSGallery" `
    -InstallationPolicy Trusted `
    -ErrorAction SilentlyContinue

# Exact Windows 11 registry property name
$propertyName = "{b3f8fa53-0004-438e-9003-51a46e139bfc},0"

# Base registry paths
$basePaths = @{
    Playback = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Playback"
    Capture  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"
}

$allDevicePaths = @()

# Enumerate all playback and recording devices
foreach ($type in $basePaths.Keys) {
    $basePath = $basePaths[$type]

    try {
        $devices = Get-ChildItem -Path $basePath -ErrorAction Stop

        foreach ($device in $devices) {
            $propertiesPath = Join-Path -Path $device.PSPath -ChildPath "Properties"

            if (Test-Path -LiteralPath $propertiesPath) {
                $allDevicePaths += $propertiesPath
            }
        }
    }
    catch {
        Write-Output "Failed to enumerate $type devices: $($_.Exception.Message)"
    }
}

# Remove duplicates
$allDevicePaths = $allDevicePaths | Select-Object -Unique

# Apply the setting to all devices
foreach ($regPath in $allDevicePaths) {
    try {
        New-ItemProperty `
            -LiteralPath $regPath `
            -Name $propertyName `
            -Value 0 `
            -PropertyType DWord `
            -Force `
            -ErrorAction Stop | Out-Null

        Write-Output "Updated: $regPath"
    }
    catch {
        Write-Output "Failed: $regPath — $($_.Exception.Message)"
    }
}

# Set microphone permission for Windows 365
$PFN = "MicrosoftCorporationII.Windows365_8wekyb3d8bbwe"

$BasePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
$AppPath  = Join-Path -Path $BasePath -ChildPath $PFN

try {
    if (-not (Test-Path -LiteralPath $AppPath)) {
        New-Item -Path $AppPath -Force -ErrorAction Stop | Out-Null
    }

    New-ItemProperty `
        -LiteralPath $AppPath `
        -Name "Value" `
        -Value "Allow" `
        -PropertyType String `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-Output "Windows 365 microphone permission set to Allow."
}
catch {
    Write-Output "Failed to set Windows 365 microphone permission: $($_.Exception.Message)"
    exit 1
}
