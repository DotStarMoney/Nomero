#include "fbpng.bi"
screenres 640,480,32

dim as integer w, h, f, r, g, b, col
f = freefile


open "colorcomb3.bmp" for binary access read as #f
get #f, 19, w
get #f, 23, h
close #f


dim as integer ptr img1 = imagecreate(w, h)
dim as integer ptr img2 = imagecreate(w, h)

bload "colorcomb3.bmp", img1
bload "mrspy2.bmp", img2

dim as integer x, y
for y = 0 to h-1
    for x = 0 to w-1
        col = (point(x, y, img1) and &h00FFFFFF) or ((point(x, y, img2) shl 24) and &hff000000)
        pset img1, (x, y), col
    next x
next y



png_save("new.png", img1)
