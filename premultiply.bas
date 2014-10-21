#include "fbpng.bi"

dim as integer ptr image, pxls


if command(1) = "" then end

screenres 640, 480, 32

image = png_load(command(1))

dim as integer x, y, w, h, r, g, b, a
imageinfo image, w, h,,,pxls

for x = 0 to w*h-1
    a = (pxls[x] shr 24) and &hff
    r = (pxls[x] shr 16) and &hff
    g = (pxls[x] shr 08) and &hff
    b = (pxls[x] shr 00) and &hff
    r = (r * a) shr 8
    g = (g * a) shr 8
    b = (b * a) shr 8
    pxls[x] = (pxls[x] and &hff000000) or (r shl 16) or (g shl 8) or b
next x

png_save command(1), image