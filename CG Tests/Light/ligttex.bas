dim as integer x, y
dim as double rad, light

screenres 650, 650, 32

for y = 0 to 649
    for x = 0 to 649
        rad = Sqr((x - 325)^2 + (y - 325)^2) / 325
        if rad > 1 then rad = 1
        light = 1 - rad
        light = light*light * 1.25
        if light > 1 then light = 1
        pset (x, y), rgb(light*255, light*128, light*128)
    next x
next y

bsave "light.bmp",0

sleep
