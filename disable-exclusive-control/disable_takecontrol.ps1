# ==========================================
# Script Name: disable_takecontrol
# Author: Matthew Bernardin
# Date: 2026-01-23
# Version 0.3
# Description: Disables Take Exclusive Control setting for Headset devices and grants all apps microphone permissions
# ==========================================

# Install AudioDeviceCmdlet powershell module - https://github.com/frgnca/AudioDeviceCmdlets

if (-not (Get-Module -ListAvailable -Name AudioDeviceCmdlets)) {
    Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Repository PSGallery -Force
}
Import-Module AudioDeviceCmdlets

$key = "b3f8fa53-0004-438e-9003-51a46e139bfc" # {b3f8fa53-0004-438e-9003-51a46e139bfc} is the registry key for "DeviceState_Flags" which controls the "Take Exclusive Control" setting for audio devices

# Retrieve Audio Device GUID's and assign them to a variable for use in the registry key path and remove the leading part of the GUID path to get just the device ID for use in the registry path
$Default_AD_Playback = (Get-AudioDevice -Playback).Id
$Default_AD_Playback -replace "^.*." 
$Default_AD_Recording = (Get-AudioDevice -Recording).Id
$Default_AD_Recording -replace "^.*."
$Default_CD_Playback = (Get-AudioDevice -PlaybackCommunication).Id
$Default_CD_Playback -replace "^.*." 
$Default_CD_Recording = (Get-AudioDevice -RecordingCommunication).Id
$Default_CD_Recording -replace "^.*."

# Create an array of registry paths (playback and recording) for both the default audio device and the default communication device.
# Each path points to the "Properties" subkey where the "Take Exclusive Control" setting is stored.

$paths = @(
    # "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Playback\$($Default_AD_Playback)\Properties",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture\$($Default_AD_Recording)\Properties",
    # "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Playback\$($Default_CD_Playback)\Properties",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture\$($Default_CD_Recording)\Properties"
)

# Loop through each registry path and set the "Take Exclusive Control" setting to 0 (disabled) for each default audio device

foreach ($regPath in $paths) {
    New-ItemProperty -Path $regPath -Name $key -Value 0 -PropertyType DWORD -Force
}

# Allow all applications to access the microphone by setting the "Value" registry key to "Allow" in the "ConsentStore\microphone" registry path. 
# This will grant all applications permission to access the microphone without prompting the user for consent.
# This is designed to combat Windows 11 disabling microphone access after an update, which is a common issue that can occur when the "Take Exclusive Control" setting is enabled for audio devices. 
# By disabling this setting and granting all applications microphone permissions, users can ensure that their microphone continues to function properly after Windows updates.

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v Value /t REG_SZ /d Allow /f
