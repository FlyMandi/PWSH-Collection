$language = (&curl -s "cht.sh/:list" | fzf)

$topic = (&curl -s "cht.sh/$language/:list" | fzf)

if ([string]::IsNullOrEmpty($topic)){ &curl -s "cht.sh/$language`?style=rrt" | less -R }
else { &curl -s "cht.sh/$language/$topic`?style=rrt" | less -R }
