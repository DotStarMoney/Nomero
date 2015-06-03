
#define SCRX 640
#define SCRY 480

screenres 640,480,32


sub drawMode7(dstPxls as integer ptr, srcPxls as integer ptr,_
              xOff as double, zOff as double,_
              horiz as integer = -200, s as double = 30, fov as integer = 256)
    
    dim as integer d_offset, offset
    dim as integer x, y, colR, colG, colB
    dim as double  sx, ipz, v, vdiv, nvdiv
    dim as integer hw, hh
    dim as integer yStart, yEnd, col
    
    hw = SCRX * 0.5
    hh = SCRY * 0.5

    d_offset = (hh + 30) * SCRX 
    yStart = -fov
    yEnd = -fov + hh - 1 - 30
    
    for y = yStart to yEnd - 1
        if (y + fov) <> 0 then
            ipz = 1.0 / (y + fov)
            offset = (int((y * ipz + zOff) * s) and 255) shl 8
            sx = (-hw * ipz + xOff) * s
            ipz *= s
            v = (-1 + abs(ipz))
            if v < 1 then v = 1
            vdiv = 1 / sqr(v)
            for x = -hw to hw - 1
                col = srcPxls[offset + (int(sx) and 255)]
                dstPxls[d_offset] = col
                d_offset += 1
                sx += ipz
            next x
        else
            d_offset += SCRX
        end if
    next y
end sub


dim as integer ptr tex = imagecreate(256,256), img = imagecreate(640,480)
bload "base.bmp", tex
bload "stars.bmp", img
dim as double x

do
    screenlock
    put (0,0), img, (0,0)-(SCRX-1, SCRY-1), PSET
    drawMode7 screenptr, @(tex[8]), x, x, -100, 130
    'line (0,SCRY*0.5)-(SCRX-1,SCRY-1), rgb(16,32,16),BF
    screenunlock
    x += 0.01
    sleep 10
loop until multikey(1)

sleep
end





