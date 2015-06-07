'-exx list.bas hashtable.bas vector2d.bas

dim as double i
dim as integer c
dim as integer frames = 5

screenres 32*frames,32,32

dim as integer ptr radar = imagecreate(32*frames, 32)

c = rgb(255,0,0)
line (0,0)-(32*frames-1, 32), &hffff00ff, BF
for i = 0 to frames-1
    circle (16 + i * 32, 16), (i+1) * int(16/frames), c,,,,F  
        circle (16 + i * 32, 16), 0.7*(i+1) * int(16/frames) + i*0.3, &hffff00ff,,,,F    

next i
get (0,0)-(32*frames-1, 31), radar
bsave "radarping.bmp", radar

sleep
end
