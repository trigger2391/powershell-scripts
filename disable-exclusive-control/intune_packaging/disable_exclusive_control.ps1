# ==========================================
# Script Name: disable_takecontrol
# Author: Matthew Bernardin
# Version: 0.4 (Intune-ready)
# ==========================================

# Ensure PSGallery is trusted (prevents prompts)
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

try {
    $Default_AD_Playback = (Get-AudioDevice -Playback).Id
    $Default_AD_Recording = (Get-AudioDevice -Recording).Id
    $Default_CD_Playback = (Get-AudioDevice -PlaybackCommunication).Id
    $Default_CD_Recording = (Get-AudioDevice -RecordingCommunication).Id
} catch {
    Write-Output "Failed to retrieve audio devices"
    exit 1
}

$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Playback\$($Default_AD_Playback)\Properties",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture\$($Default_AD_Recording)\Properties",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Playback\$($Default_CD_Playback)\Properties",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture\$($Default_CD_Recording)\Properties"
)

foreach ($regPath in $paths) {
    try {
        New-ItemProperty -Path $regPath -Name $key -Value 0 -PropertyType DWORD -Force -ErrorAction Stop
    } catch {
        Write-Output "Failed to set registry at $regPath"
    }
}

# Microphone permission (user context)
try {
    New-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" `
        -Name "Value" `
        -Value "Allow" `
        -PropertyType String `
        -Force
} catch {
    Write-Output "Failed to set microphone permissions"
}

exit 0