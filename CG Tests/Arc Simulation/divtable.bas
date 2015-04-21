
dim as integer f, pl
dim as string fstr
f = freefile
open "table.txt" for output as #f

dim as double values
pl = 0
fstr = ""
for values = 0 to 255
    fstr += str(int(values / 5.0)) + ", "

    pl += 1
    if pl = 16 then
        pl = 0
        print #f, fstr+"_"
        fstr = ""
    end if
next values

close #f





