# PWSH-Collection

[Simple script to compress & back-up a folder with winRAR](https://github.com/FlyMandi/PWSH-Collection/blob/main/backup.ps1), it will take a source Folder as the -f flag and a destination Folder as the -t flag, copy & compress everything from the source folder and create an aptly named backup.

Example usage: ```backup -f "C:\Important Files\" -t "D:\Backup Folder\"```

//TODO: Automate rolling backups (delete old files)
//TODO: config file for rar.exe path and/or backup folder
//TODO: test if 7zip is better suited