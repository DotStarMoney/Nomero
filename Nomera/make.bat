del "Nomera.exe"

py compileobjects.py

rem fbc -s gui -x Nomera.exe -m main *.bas

fbc -s gui -x Nomera.exe shape2d.bas vector2d.bas utility.bas
