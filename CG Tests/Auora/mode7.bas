
#define SCRX 640
#define SCRY 480

screenres 640,480,32


sub drawMode7(dst as integer ptr, src as integer ptr,_
              xOff as double, zOff as double,_
              horiz as integer = -200, s as double = 30, fov as integer = 256)
    
    dim as integer d_offset, offset
    dim as integer x, y, vdivInt, destW, destH
    dim as double  sx, ipz, v, vdiv
    dim as integer hw, hh, rowW, ipzInt, sxInt
    dim as integer yStart, yEnd, col, dstStride
    dim as integer ptr srcOffset, dstOffset, dstPxls, srcPxls
    static as short divData(0 to 3)
    
    imageinfo dst, destW, destH,,dstStride,dstPxls
    imageinfo src,,,,,srcPxls
    
    dstStride shr= 2
    
    hw = destW * 0.5
    hh = destH * 0.5

    d_offset = 0
    yStart = (-hh - horiz - fov)
    yEnd = -fov

    for y = yStart to yEnd - 1
        if (y + fov) <> 0 then
            ipz = 1.0 / (y + fov)
            offset = (int((y * ipz + zOff) * s) and 255) shl 8
            sx = (-hw * ipz + xOff) * s
            ipz *= s
            v = -10 + abs(ipz * 10)
            if v < 1 then v = 1
            vdivInt = 255 / v
            
            divData(0) = vdivInt
            divData(1) = vdivInt
            divData(2) = vdivInt
            divData(3) = vdivInt                     
            
            if sx >= 256 then 
                sx = sx - int(sx / 256) * 256
            elseif sx < 0 then
                sx = sx + (int(sx / 256) + 1) * 256
            end if
            rowW = ((hw - 1) + hw) + 1
            sxInt = sx * 4096.0
            ipzInt = ipz * 4096.0
            srcOffset = srcPxls + offset
            dstOffset = dstPxls + d_offset
            
            asm
                
                    mov         ecx,            [rowW]
                    mov         ebx,            [sxInt]
                    mov         edx,            [ipzInt]
                    mov         esi,            [srcOffset]
                    mov         edi,            [dstOffset]
                    movq        mm7,            [divData]
                    pxor        mm6,            mm6
                
                mode7_columnLoop:
                
                    mov         eax,            ebx
                    shr         eax,            12
                    and         eax,            &hff
                    movd        mm0,            [esi+eax*4]
                    punpcklbw   mm0,            mm6
                    pmullw      mm0,            mm7
                    psrlw       mm0,            8
                    packuswb    mm0,            mm6
                    
                    movd        mm1,            [edi]
                    por         mm0,            mm1                    
                    movd        [edi],          mm0
                    
                    add         ebx,            edx
                    add         edi,            4
                    dec         ecx
                    jnz         mode7_columnLoop
                                      
                    emms
            end asm
            d_offset += dstStride
        else
            d_offset += dstStride
        end if
    next y
end sub


dim as integer ptr tex = imagecreate(256,256), img = imagecreate(640,480)
dim as integer ptr buff = imagecreate(640,480)
bload "aurora.bmp", tex
bload "stars.bmp", img
dim as double x

do
    screenlock
    put buff,(0,0), img, (0,0)-(SCRX-1, SCRY-1), PSET
    drawMode7 buff, tex, x, x, 0
    'line (0,SCRY*0.5)-(SCRX-1,SCRY-1), rgb(16,32,16),BF
    put (0,0), buff, PSET
    screenunlock
    x += 0.01
    sleep 10
loop until multikey(1)

sleep
end





