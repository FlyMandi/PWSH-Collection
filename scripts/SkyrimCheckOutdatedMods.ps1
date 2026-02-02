#TODO: get all file change times, then take the newest one
    # if it's a config file (.toml), (.ini), (.txt) and there's other files, ignore this filetime, recurse
    # if all of the other files are also config (.toml), (.ini), (.txt) (.yaml) then return the newest (.txt), (.ini), (.toml), (.yaml) filetime (in that order of priorities.)
    # if there's a .dll, then take that filetime, ignore all others.
        # try implementing "mode" recognition, there's:
        # a .dll-only mod (.dll)
            # if there is no .dll, confidence score 0.
            # if only .dll and config, then score 100, take off 1 point for each file that isn't a .dll or config file.
        # a textures-only mod (.dds)
        # a .nif replacer mod (.nif)
        # an expansion (.fuz or .wav, .dds, .nif, .pex, .seq) all together OR (.bsa and .esm/.esp/.esl)
        # a config mod (unlikely) (just configs, .xml, .toml, .txt or .ini)
        # an animations-only mod (.hkx)
        # interface-mod (.swf)
        # simple plugin (only .esp/.esl)
        # important master plugin! (.esm)
    # switch case with recognition, give confidence scores and then choose the ones with the highest confidence score.
        # when storing the likely winner, just store it in a set, name and score, and:
            # if new score > old score, replace set
            # otherwise, check next mod
            # have a list of priorities decided by ease/speed of checking. (always .dll first, simple plugin next, then rest)
            # if any of these reach 100, skip the entire checking process (because we're sure)
#TODO: give back the parent folder (in the folder where we wanted to check) of the file as a probably outdated mod.
#TODO: standard operation: list amount of probably outdated mods (older than a year) and the amount at the bottom. 
    # add probably VERY outdated, like older than 5 years.
    # optional prompt for file time to check against
    # finetune default date based on personal results

#TODO: add in foldermanip.psm1, Get-NewestFileTimeinFolderNoConfig
#TODO: add in foldermanip.psm1, Test-IsConfigFileFormat

param(
    $folder
)

$outdated = @()
$cutoffDate = ''

foreach ($subfolder in (Get-ChildItem $folder)){
   $current = [PSCustomObject]@{ Folderpath = $subfolder; LastFileTime = (Get-NewestFileTimeinFolderNoConfig $subfolder) } #TODO: add the friggen function hehe
   if ($current.LastFileTime -lt $cutoffDate){ $outdated += $current }
}

Write-Host $outdated
