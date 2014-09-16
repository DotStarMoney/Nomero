
#define SCRX 640
#define SCRY 480

screenres 640,480,32


sub drawMode7(dstPxls as integer ptr, srcPxls as integer ptr,_
              xOff as double, zOff as double,_
              flags as integer = 3, s as double = 1, horiz as integer = 0, fov as integer = 1000)
    
    dim as integer d_offset, offset
    dim as integer x, y
    dim as double  sx, ipz, v
    dim as integer hw, hh
    dim as integer yStart, yEnd, col
    
    hw = SCRX * 0.5
    hh = SCRY * 0.5

    d_offset = 0
    if flags = 1 then
        yStart = (-hh - horiz - fov)
        yEnd = -fov
    elseif flags = 2 then
        yStart = -horiz - fov
        yEnd = (hh - horiz - fov)
        d_offset = SCRY * 0.5 * SCRX
    elseif flags = 3 then
        yStart = (-hh - horiz - fov)
        yEnd = (hh - horiz - fov)
    end if

    for y = yStart to yEnd - 1
        if (y + fov) <> 0 then
            ipz = 1.0 / (y + fov)
            offset = (int((y * ipz + zOff) * s) and 255) shl 8
            sx = (-hw * ipz + xOff) * s
            ipz *= s
            v = -10 + abs(ipz * 10)
            if v < 1 then v = 1
            for x = -hw to hw - 1
                col = srcPxls[offset + (int(sx) and 255)]
                
                col = ((col and &hff) / v) or ((((col shr 8) and &hff) / v) shl 8) or ((((col shr 16) and &hff) / v) shl 16)
                
                dstPxls[d_offset] = dstPxls[d_offset] or col
                d_offset += 1
                sx += ipz
            next x
        else
            d_offset += SCRX
        end if
    next y
        
              
end sub


dim as integer ptr tex = imagecreate(256,256), img = imagecreate(640,480)
bload "aurora.bmp", tex
bload "stars.bmp", img
dim as double x

do
    screenlock
    put (0,0), img, (0,0)-(SCRX-1, SCRY-1), PSET
    drawMode7 screenptr, @(tex[8]), x, x, 1, 30,-100,256
    'line (0,SCRY*0.5)-(SCRX-1,SCRY-1), rgb(16,32,16),BF
    screenunlock
    x += 0.01
    sleep 10
loop until multikey(1)

sleep
end





