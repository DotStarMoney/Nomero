#include "fbpng.bi"
screenres 640,480,32

dim as integer w, h, f
f = freefile
dim as string filename

filename = command(1)
filename = "coversmoke.bmp"

open filename for binary access read as #f
get #f, 19, w
get #f, 23, h
close #f


dim as integer ptr img = imagecreate(w, h)
dim as integer a, col

bload filename, img

dim as integer x, y
for y = 0 to h-1
    for x = 0 to w-1
        a = point(x, y, img) and &hff
        col = a
        col = (rgb(192,192,192) and &h00ffffff) or (a shl 24)
        pset img, (x, y), col
    next x
next y


for y = 0 to h-1
    for x = 0 to w-1
        a = (point(x, y, img) shr 24) and &hff
        col = point(x, y, img) and &hff
        
        col = (col * a) / 255.0
        if col > 255 then col = 255
        
        a = 255 - a
        
 
        col = (rgb(col, col, col) and &h00ffffff) or (a shl 24)
        
        
        pset img, (x, y), col
    next x
next y

png_save(left(filename, len(filename) - 3) & "png", img)
