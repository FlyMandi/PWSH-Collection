# PWSH-Collection
[List of all scripts](scripts/)

When downloading a script, I suggest making a "scripts" folder somewhere safe and then adding that folder to PATH[^1].\
Then, you can just write the name of the script with arguments in your favourite shell.\
Example: `script -f flag1 -t -flag2`\
If not, you will have to call each script either by relative or absolute paths.\
Example: `"C:\users\FlyMandi\Downloads\script.ps1" -f flag1 -t -flag2`

## View Code Documentation with `cht.sh`

Make sure you've installed `less` and `fzf`, both available via scoop.
This streamlines the use of `curl cht.sh/language/topic` like so:

```shell
cheatsheet language topic
```

So, if you've set a `csh` alias for `cheatsheet`, `curl cht.sh/cpp/loops` becomes:
```shell
csh cpp loops
```

You can also open a fuzzy find list of languages:
```shell
csh
```
and topics:
```shell
csh cpp
```

## Set Alarm with mpvnet
[Script to set alarm from CLI](scripts/set-alarm.ps1)

Didn't you always want to set an alarm from your terminal? Well, now you can. First, make sure you've installed `mpvnet`.
```shell
scoop install mpv.net
```

Then, you can set an alarm for any time today. For now, input is limited to `hh:mm:ss` or `hh:mm` within the same day. Specify a file path to then be played.
```shell
Set-Alarm "CatAlarm" 16:09 "~\Videos\Funny Cat Video.mp4"
```

or, alternative syntax:
```shell
Set-Alarm -n "Cattie Cat" -t 16:09:30 -p ~\Videos\Cat.mp4 
```

You can check status and cancel by name with `-s` and `-c`:

To view status:
```shell
Set-Alarm CatAlarm -s
```

To cancel:
```shell
Set-Alarm "Cattie Cat" -c
```

## Get & convert unix time & discord timestamps
[Script to get unix & discord timestamps](scripts/unix.ps1)

I communicate with a lot of people abroad via discord and it's super handy to be able to set a discord timestamp that automatically converts to the reader's timezone. For example, when I set a streaming schedule and want to say "Tuesdays at x time, thursdays at y time" I can't say my time because that's only going to apply to people within my timezone. Here's a quick way to get a formatted discord timestamp from a time of your desire:

### To copy the current unix time to clipboard (without formatting):
Input:
```shell
unix
```
or
```shell
unix get
```
Output:
```
Writing time 06/02/2024 15:02:13 (1717333334) to clipboard.
```

### To convert a unix time to clipboard (without formatting):
Input:
```
unix convert 1717333334
```
or
```shell
unix convert -t 1717333334
```
`02 June 2024 15:02:14` will have been written to your clipboard.

### To convert a unix time to discord timestamp:
`Mode` can be any of the following:
| Mode              | Values                | Result in clipboard   | Format in discord     |
| ---               | ---                   | ---                   | ---                   |
| relative          | `relative` or `r`     | `<t:1717331031:R>`    | `54 minutes ago`      |
| long time         | `longtime` or `lt`    | `<t:1717331031:T>`    | `14:23:51`            |
| short time        | `shorttime` or `st`   | `<t:1717331031:t>`    | `14:23`               |
| long date         | `longdate` or `ld`    | `<t:1717331031:D>`    | `2 June 2024`         |
| short date        | `shortdate` or `sd`   | `<t:1717331031:d>`    | `02/06/2024`          |
| long full         | `longfull` or `lf`    | `<t:1717331031:F>`    | `Sunday, 2 June 14:23`|
| short full        | `shortfull` or `sf`   | `<t:1717331031:f>`    | `2 June 2024 14:23`   |
| default           | blank or invalid      | `<t:1717331031>`      | `2 June 2024 14:23`   |

Usage:
```
unix discord -m Mode -t time
```
Input:
```shell
unix discord -m relative -t 1717333334
```
Output:
```
Writing time 06/02/2024 15:13:45 to clipboard.
Written timestamp with mode : <t:1717333334:R>
```

If you leave out the mode, the mode will fall back to `default` and if you leave out the time, it will use the current unix timestamp.


Limitations: can only work with current or specific unix time (for now)\

## Fix winget showing out-of-date package version with updated app
[Script to update winget package registry version](scripts/updateWR.ps1)

Some packages don't update properly (like `Discord.Discord`) and using `winget update` would result in the package being shown as not updated, staying on the version that was first installed. This is a scuffed fix. It will find and update the registry key, but please only use this when you're sure you have the newest version installed and only winget is showing the wrong, outdated version number. 

Example usage:
```shell
updatewr discord.discord
```

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

NOTE: to update the ones stuck in `HKEY_LOCAL_MACHINE`, you will need to run this script in an elevated prompt. Please never run scripts off the internet without having read through them. Unfortunately, not everyone is as nice as me. :eye:

If you want to take matters into your own hands, hit `Win+R`, type `regedit`, hit enter & search for the folder yourself in\
```HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall```\
or\
```HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall```\
and look for the Registry Key called `DisplayVersion`, then update it.

## Clean unwanted/unused images from Playnite Library
Simply run
```
PlayniteImageCleaner
```
and the script will clean unused Images, specifically leftovers from the BackgroundChanger and CoverStyleSwitcher extensions. 

## Find problematic Skyrim Mods
Simply run
```
SkyrimDiagnostics
```
and the script will warn about outdated mods, as well as indicate which single `.ESP` files are very large, which are both good indicators about possible mod problems.
It features an exclusion list.

## Swap between winfetch configs

[Script to change between made winfetch config files](scripts/winfetchconfig.ps1)

I shan't need to say that you need to have winfetch installed. Personally, I've installed it via `scoop install winfetch`. Uninstalling winfetch via `scoop uninstall winfetch` _will not_ get rid of your saved theme configuration files.

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

### To choose a theme:
```shell
winfetchconfig choose ThemeName
```
or simply:
```shell
winfetchconfig ThemeName
```

### To view a list of all custom themes:
```shell
winfetchconfig list
```

### To make changes to the current theme:
```shell
winfetchconfig edit
```

### To make changes to a specific theme:
```shell
winfetchconfig edit ThemeName
```

### To set a random theme
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

To reset default to very default (c'mon now), write:
```shell
winfetch -genconf
winfetchconfig savedefault
```

I've now also uploaded a version for [fastfetch](https://github.com/fastfetch-cli/fastfetch), which I personally prefer using.
All arguments are analogous.

## config.ps1

[config.ps1](https://github.com/FlyMandi/PWSH-Collection/blob/main/scripts/config.ps1) is a script I personally use to set up new computers. It installs and updates all software that I use on a daily basis.\
I can't recommend you using it, since the software is highly dependant on personal uses and platforms, but certainly have a look at the source code if intrigued.

[^1]: Simple tutorial on how to add a folder to PATH [here](https://stackoverflow.com/questions/44272416/how-to-add-a-folder-to-path-environment-variable-in-windows-10-with-screensho).
