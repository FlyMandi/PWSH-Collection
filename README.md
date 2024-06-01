# PWSH-Collection
[List of all scripts](scripts/)

When downloading a script, I suggest making a "scripts" folder somewhere safe and then adding that folder to PATH[^1].\
Then, you can just write the name of the script with arguments in your favourite shell.\
Example: `script -f flag1 -t -flag2`\
If not, you will have to call each script either by relative or absolute paths.\
Example: `"C:\users\FlyMandi\Downloads\script.ps1" -f flag1 -t -flag2`

## Fix winget showing out-of-date package version with updated app
[Script to update winget package registry version](scripts/updateWR.ps1), some packages don't update properly (like `Discord.Discord`) and using `winget update` would result in the package being shown as not updated, staying on the version that was first installed. This is a scuffed fix. It will find and update the registry key, but please only use this when you're sure you have the newest version installed and only winget is showing the wrong, outdated version number. 

Example usage:
```shell
updatewr discord.discord
```
[Here it is in action.](images/xample_discord.png)

Limitations: registry key folder must match the name that's displayed via "winget show" or you have to supply the registry folder name.\
Example:
```updatewr jandedobbeleer.ohmyposh```
doesn't work, but
```shell
updatewr jandedobbeleer.ohmyposh -reg "Oh My Posh_is1"
```
does.

to update a steam app that is recognized via `winget` but has an out-of-date or unknown version number, you can utilize the steam app ID, as follows:
```shell
updatewr jagex.oldSchoolRunescape -reg 'steam app 1343370'
```
[Example Image here.](images/xample_elevated.png)

NOTE: to update the ones stuck in `HKEY_LOCAL_MACHINE`, you will need to run this script in an elevated prompt. Please never run scripts off the internet without having read through them. Unfortunately, not everyone is as nice as me. :eye:

If you want to take matters into your own hands, hit `Win+R`, type `regedit`, hit enter & search for the folder yourself in\
```HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall```\
or\
```HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall```\
and look for the Registry Key called `DisplayVersion`, then update it.

## Swap between winfetch configs

[Script to change between made winfetch config files](scripts/winfetchconfig.ps1). I shan't need to say that you need to have winfetch installed. Personally, I've installed it via `scoop install winfetch`. Uninstalling winfetch via `scoop uninstall winfetch` _will not_ get rid of your saved theme configuration files.

I personally use `winfetchconfig` as a way to change up the image being displayed when `winfetch` is called, as I was tired of always manually editing the config file for that. If you want to do that, read below.

Syntax is as follows: ```winfetchconfig operation ThemeName``` ◀️ the order is important! Tip: when no operation is specified, `choose` is the fallback operation.

The location for all your personal configs is in `%UserProfile%\Documents\.personalConfigs\winfetch`.\
You shouldn't need to access this folder unless you desire to change them in a specific text editor instead of with the script.\
At that point, just go and edit the line that says `notepad` in the script yourself.

To save a theme with a name, write:
```shell
winfetchconfig save ThemeName
```
Note: use the `-f` flag to overwrite a saved theme with the same name. Also, I shouldn't need to say this, but always replace `ThemeName` with... your desired name for the theme. :suspect:

To choose a theme, type:
```shell
winfetchconfig choose ThemeName
```
or simply:
```shell
winfetchconfig ThemeName
```

To view a list of all custom themes, write:
```shell
winfetchconfig list
```

To make changes to the current theme, type:
```shell
winfetchconfig edit
```

To make changes to a specific theme, type:
```shell
winfetchconfig edit ThemeName
```

To set a random theme, write:
```shell
winfetchconfig random
```

The default theme is stored as `%UserProfile%\Documents\.personalConfigs\winfetch\default\!default.ps1` and is created the first time you use `winfetchconfig`, but can be adjusted to your liking by setting your current config as the default one. Personally, I recommend letting the default... be the default.

To save current theme to default, write:
```shell
winfetchconfig savedefault
```

To reset theme to (saved) default, write:
```shell
winfetchconfig reset
```

To reset default to default (c'mon now), write:
```shell
winfetch -genconf
winfetchconfig savedefault
```

## Automated backup
[Simple script to compress & back-up a folder with 7zip](scripts/backup.ps1), it will take a source Folder as the -f flag and a destination Folder as the -t flag, copy & compress everything from the source folder and create an aptly named backup. If nothing is specified, it will take the default destination from the folder and the current folder as the folder to be backed up.

Example usage:
```shell
backup -f 'C:\Important Files\' -t 'D:\Backup Folder\'
```
Limitations: can only backup entire folders, does not discriminate between drives

//TODO: Automate rolling backups (delete old files)\
//TODO: config file for number of backups, locations, etc
//TODO: categorize folders by drive

[^1]: Simple tutorial on how to add a folder to PATH [here](https://stackoverflow.com/questions/44272416/how-to-add-a-folder-to-path-environment-variable-in-windows-10-with-screensho).
