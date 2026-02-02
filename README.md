# PWSH-Collection

[Simple script to compress & back-up a folder with 7zip](https://github.com/FlyMandi/PWSH-Collection/blob/main/backup.ps1), it will take a source Folder as the -f flag and a destination Folder as the -t flag, copy & compress everything from the source folder and create an aptly named backup. If nothing is specified, it will take the default destination from the folder and the current folder as the folder to be backed up.

Example usage: ```backup -f "C:\Important Files\" -t "D:\Backup Folder\"```

//TODO: Automate rolling backups (delete old files)
//TODO: config file for rar.exe path and/or backup folder