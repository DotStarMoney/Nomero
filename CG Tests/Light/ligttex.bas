dim as integer x, y
dim as double rad, light

screenres 512, 512, 32

for y = 0 to 511
    for x = 0 to 511
        rad = Sqr((x - 256)^2 + (y - 256)^2) / 325
        if rad > 1 then rad = 1
        light = 1 - rad
        light = light^18 * 3
        if light > 1 then light = 1
        pset (x, y), rgb(light*255, light*64, light*0)
    next x
next y

bsave "hilight.bmp",0

sleep
