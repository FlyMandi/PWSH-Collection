# PWSH-Collection

### Fix winget showing out-of-date package version with updated app
[Simple script to update winget package registry version](https://github.com/FlyMandi/PWSH-Collection/blob/main/updateWR.ps1), some packages don't update properly (like `Discord.Discord`) and using `winget update` would result in the package being shown as not updated, staying on the version that was first installed. This is a scuffed fix. It will find and update the registry key, but please only use this when you're sure you have the newest version installed and only winget is showing the wrong, outdated version number. Example usage: ```updatewr discord.discord"``` [Here it is in action.](https://github.com/FlyMandi/PWSH-Collection/blob/main/image.png)

Limitations: registry key folder must match the name that's displayed via "winget show" or you have to supply the registry folder name.
Example: ```updatewr jandedobbeleer.ohmyposh``` doesn't work, but ```updatewr jandedobbeleer.ohmyposh -reg "Oh My Posh_is1"``` does.

### Automated backup
[Simple script to compress & back-up a folder with 7zip](https://github.com/FlyMandi/PWSH-Collection/blob/main/backup.ps1), it will take a source Folder as the -f flag and a destination Folder as the -t flag, copy & compress everything from the source folder and create an aptly named backup. If nothing is specified, it will take the default destination from the folder and the current folder as the folder to be backed up. Example usage: ```backup -f "C:\Important Files\" -t "D:\Backup Folder\"```

Limitations: can only backup entire folders, does not discriminate between drives

//TODO: Automate rolling backups (delete old files)
//TODO: config file for rar.exe path and/or backup folder
//TODO: categorize folders by drive