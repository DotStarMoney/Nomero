screenres 640,480,32

dim as integer w, h, f, lrgV
dim as integer xdif, ydif, x, y
dim as double scale
f = freefile

if command(1) = "" then end

open command(1) for binary access read as #f
get #f, 19, w
get #f, 23, h
close #f


dim as integer ptr img = imagecreate(w, h), dataX, dataY
bload command(1), img


dataX = allocate(sizeof(integer)*w*h)
dataY = allocate(sizeof(integer)*w*h)

lrgV = 0
for y = 0 to h-1
    for x = 0 to w-1
      
        if x = 0 then
            xdif = 128 - (point(1, y, img) and &hff)
        elseif x = (w-1) then
            xdif = (point(w-2, y, img) and &hff) - 128
        else
            xdif = (point(x+1, y, img) and &hff) - (point(x-1, y, img) and &hff)
        end if
    
        if y = 0 then
            ydif = 128 - (point(x, 1, img) and &hff)
        elseif y = (h-1) then
            ydif = (point(x, h-2, img) and &hff) - 128
        else
            ydif = (point(x, y+1, img) and &hff) - (point(x, y-1, img) and &hff)
        end if
        
        if point(x, y, img) = &hffff00ff then 
            xdif = 0
            ydif = 0
        end if
        
        dataX[y*w+x] = -xdif
        dataY[y*w+x] = -ydif
        if abs(xdif) > lrgV then lrgV = abs(xdif)
        if abs(ydif) > lrgV then lrgV = abs(ydif)
 
    next x
next y

scale = (128.0 / cdbl(lrgV))
for y = 0 to h-1
    for x = 0 to w-1

        xdif = dataX[y*w+x] * scale
        ydif = dataY[y*w+x] * scale
        pset (x, y), rgb(0, ydif + 128, xdif + 128)
 
    next x
next y

sleep

get (0,0)-(w-1,h-1), img
bsave left(command(1), len(command(1))-4) + "_norm.bmp", img

