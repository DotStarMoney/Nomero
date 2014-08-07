'-exx list.bas hashtable.bas vector2d.bas

dim as double i
dim as integer c
dim as integer frames = 7

screenres 128*frames,128,32

dim as integer ptr radar = imagecreate(128*frames, 128)

c = rgb(160, 200, 255)
line (0,0)-(128*frames-1, 127), &hff00ff, BF
for i = 0 to frames-1
    circle (63.5 + i * 128, 63.5), (i+1) * int(64/frames), c,,,,F
    circle (63.5 + i * 128, 63.5), (i+0.3) * 68.2/frames, &hff00ff,,,,F
    
next i
get (0,0)-(128*frames-1,127), radar
bsave "radarping.bmp", radar

sleep
end
