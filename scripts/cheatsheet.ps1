param(
    [Parameter(Mandatory = $false, position = 0)]
    $inputLang,
    [Parameter(Mandatory = $false, position = 1)]
    $inputTopic
)

if(-Not([string]::IsNullOrEmpty($inputLang))){ $language = $inputLang }
else{ $language = (&curl -s "cht.sh/:list" | fzf) }

$topicList = (&curl -s "cht.sh/$language/:list")

if(-Not([string]::IsNullOrEmpty($inputTopic))){ $topic = $inputTopic }
elseIf([string]::IsNullOrEmpty($topicList)) { $topic = $null }
else { $topic = ($topicList | fzf) }

if([string]::IsNullOrEmpty($topic)){
    if ($language -match "./") { throw "ERROR: language $language has no default info page." }
    $query = &curl -s "cht.sh/$language`?style=rrt"
}
else{ $query = &curl -s "cht.sh/$language/$topic`?style=rrt" }

$query | less -R
