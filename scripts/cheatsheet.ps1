param(
    [Parameter(Mandatory = $false, position = 0)]
    $inputLang,
    [Parameter(Mandatory = $false, position = 1)]
    $inputTopic
)

if (-Not([string]::IsNullOrEmpty($inputLang))){ $language = $inputLang }
else { $language = (&curl -s "cht.sh/:list" | fzf) }

if (-Not([string]::IsNullOrEmpty($inputTopic))){ $topic = $inputTopic }
else { $topic = (&curl -s "cht.sh/$language/:list" | fzf) }

if ([string]::IsNullOrEmpty($topic)){
    if ($language -match "./") { throw "ERROR: language $language has no default info page." }
    $query = curl -s "cht.sh/$language`?style=rrt"
}
else { $query = curl -s "cht.sh/$language/$topic`?style=rrt" }

#TODO: fix assembly/, has no default page

$query | less -R
