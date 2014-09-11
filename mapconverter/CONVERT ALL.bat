@ECHO off
echo Converting all .lua files in directory...
FOR /r %%F in ("*.lua") DO MAPCONVERT ^"%%~nF.lua^"
echo Conversion complete!