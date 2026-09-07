
function update_all
{
    $folders | ForEach-Object -Parallel {
        if(-Not(Test-Path $_ -PathType Container))
        {
            echo "Already up to date."
            return;
        }

        cd $_

        if(-Not(Get-Item ".git" -Force))
        {
            echo "Already up to date."
            return;
        }

        git fetch
        git pull

        if($LASTEXITCODE -ne 0)
        {
            Write-Host "^^^^^^ $_`n"
        }
    }
}

$folders=@(
"C:\repository\aphelion-engine\",
"C:\repository\bash-collection\",
"C:\repository\blazeterm\",
"C:\repository\dotfiles\",
"C:\repository\dropfetch\",
"C:\repository\flushback\",
"C:\repository\fontflow\",
"C:\repository\gitfluss\",
"C:\repository\imgsurf\",
"C:\repository\islescape\",
"C:\repository\marino\",
"C:\repository\puddle\",
"C:\repository\PWSH-Collection\",
"C:\repository\river2D\",
"C:\repository\river2D_mapedit\",
"C:\repository\river3D\",
"C:\repository\vertstream\",

"C:\repository\gitfluss\vendor\puddle\",
"C:\repository\imgsurf\vendor\puddle\",
"C:\repository\blazeterm\vendor\fontflow\",
"C:\repository\river2D\vendor\fontflow\",
"C:\repository\river2D\vendor\imgsurf\",
"C:\repository\river3D\vendor\imgsurf\",
"C:\repository\river3D\vendor\vertstream\",
"C:\repository\marino\vendor\river2D\",
"C:\repository\marino\vendor\fontflow\",
"C:\repository\islescape\vendor\river2D\",
"C:\repository\river2D_mapedit\vendor\river2D\",

"C:\repository\marino\vendor\river2D\vendor\imgsurf\",
"C:\repository\islescape\vendor\river2D\vendor\imgsurf\",
"C:\repository\river2D_mapedit\vendor\river2D\vendor\imgsurf\",

"C:\repository\river2D\vendor\imgsurf\vendor\datasurf\vendor\puddle\",
"C:\repository\river3D\vendor\imgsurf\vendor\datasurf\vendor\puddle\",
"C:\repository\marino\vendor\river2D\vendor\imgsurf\vendor\datasurf\",
"C:\repository\islescape\vendor\river2D\vendor\imgsurf\vendor\datasurf\",
"C:\repository\river2D_mapedit\vendor\river2D\vendor\imgsurf\vendor\datasurf\",

"C:\repository\marino\vendor\river2D\vendor\imgsurf\vendor\datasurf\vendor\puddle\",
"C:\repository\islescape\vendor\river2D\vendor\imgsurf\vendor\datasurf\vendor\puddle\",
"C:\repository\river2D_mapedit\vendor\river2D\vendor\imgsurf\vendor\datasurf\vendor\puddle\")

update_all
