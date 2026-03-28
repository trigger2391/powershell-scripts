# Disable Exclusive Control

This script is meant to disable the windows setting for allow apps to take exclusive control of audio devices.

The script has the following workflow.

1. Install Dependencies (Completed)
2. Pull GUID of current Default Audio Device and Default Communications Device (Completed)
3. Store the GUID into a variable (Completed)
5. Use the variable to apply the regkey setting to the Playback and Capture settings for the device (Completed)

Packaging (After testing has confirmed script works reliably)
1. Write Auto_logon Script (WIP)
2. Package disable_takecontrol and Auto_logon into .intunewin application (WIP)
3. Test Deployment
4. Full Deployment


