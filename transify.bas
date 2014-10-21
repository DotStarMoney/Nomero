#include "fbpng.bi"
screenres 640,480,32

dim as integer w, h, f
f = freefile

open command(1) for binary access read as #f
get #f, 19, w
get #f, 23, h
close #f


dim as integer ptr img = imagecreate(w, h)

bload command(1), img

dim as integer x, y
for y = 0 to h-1
    for x = 0 to w-1
        pset img, (x, y), ((point(x, y, img) and &hff) shl 24) or &h00ffffff
    next x
next y

png_save(left(command(1), len(command(1)) - 3) & "png", img)
