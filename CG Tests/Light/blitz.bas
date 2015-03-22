
function intLog2(x as integer) as integer
    asm
        mov     eax,        [x]
        bsr     eax,        eax
        mov     [function], eax
    end asm
end function

function mulmixColors(col1 as integer, col2 as integer) as integer
    dim as double r1, g1, b1, a1
    dim as double r2, g2, b2, a2
    dim as integer res
    
    b1 = col1 and &hff
    g1 = (col1 shr  8) and &hff
    r1 = (col1 shr 16) and &hff
    a1 = (col1 shr 24) and &hff

    b2 = col2 and &hff
    g2 = (col2 shr  8) and &hff
    r2 = (col2 shr 16) and &hff
    a2 = (col2 shr 24) and &hff
    
    r2 /= 255.0
    g2 /= 255.0
    b2 /= 255.0
    a2 /= 255.0
    
    r1 *= r2
    g1 *= g2
    b1 *= b2
    a1 *= a2
    
    res = (cint(b1) and &hff) or ((cint(g1) and &hff) shl 8) or ((cint(r1) and &hff) shl 16) or ((cint(a1) and &hff) shl 24)

    return res
end function

function addsatColors(col1 as integer, col2 as integer) as integer
    dim as double r1, g1, b1, a1
    dim as double r2, g2, b2, a2
    dim as integer res
    
    b1 = col1 and &hff
    g1 = (col1 shr  8) and &hff
    r1 = (col1 shr 16) and &hff
    a1 = (col1 shr 24) and &hff

    b2 = col2 and &hff
    g2 = (col2 shr  8) and &hff
    r2 = (col2 shr 16) and &hff
    a2 = (col2 shr 24) and &hff
    
    r1 += r2
    g1 += g2
    b1 += b2
    a1 += a2
    
    if r1 > 255 then r1 = 255
    if g1 > 255 then g1 = 255
    if b1 > 255 then b1 = 255
    if a1 > 255 then a1 = 255
    
    res = (cint(b1) and &hff) or ((cint(g1) and &hff) shl 8) or ((cint(r1) and &hff) shl 16) or ((cint(a1) and &hff) shl 24)

    return res
end function



sub transBumpDiffSpecBlit2(dest as any ptr, posx as integer, posy as integer,_
                          src as any ptr, nrmSrc as any ptr,_
                          x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                          ambientLight as integer,_
                          lightX1 as integer, lightY1 as integer,_
                          diffSrc1 as any ptr, specSrc1 as any ptr,_
                          lightX2 as integer, lightY2 as integer,_
                          diffSrc2 as any ptr, specSrc2 as any ptr)
                          
    dim as integer ptr fbDest, fbSrc, fbNrmSrc
    
    dim as integer ptr fbDiffSrc1, fbSpecSrc1
    dim as integer lpDifX1, lpDifY1, lightW1, lightH1
    dim as integer lightWMask1, lightHMask1
    dim as integer shiftLightW1
    
    dim as integer ptr fbDiffSrc2, fbSpecSrc2
    dim as integer lpDifX2, lpDifY2, lightW2, lightH2
    dim as integer lightWMask2, lightHMask2
    dim as integer shiftLightW2   
    
    dim as integer destW, destH, srcW, srcH, lightPLoc
    dim as integer destStride, srcStride
    dim as integer xp, yp, yDest, xDest, lightCol
    dim as integer lvx, lvy, lv, normCol, hicol, scol, pcol, startX
    dim as integer destPos, destOffset, srcOffset, wCount
    
    imageinfo dest, destW, destH,, destStride, fbDest
    imageinfo src,,,,srcStride, fbSrc
    imageinfo nrmSrc,,,,,fbNrmSrc
    
    imageinfo diffSrc1, lightW1, lightH1,,,fbDiffSrc1
    imageinfo specSrc1,,,,,fbSpecSrc1
    
    imageinfo diffSrc2, lightW2, lightH2,,,fbDiffSrc2
    imageinfo specSrc2,,,,,fbSpecSrc2
       
    srcW = x1 - x0 + 1
    srcH = y1 - y0 + 1
    
    destStride shr= 2
    srcStride shr= 2
    destOffset = destStride*posy + posx
    srcOffset = srcStride*y0 + x0
    destStride -= srcW
    srcStride -= srcW
    
    lightWMask1 = not (lightW1 - 1)
    lightHMask1 = not (lightH1 - 1)
    lpDifX1 = -lightX1 - 128 + lightW1 shr 1
    lpDifY1 = -lightY1 - 128 + lightH1 shr 1
    shiftLightW1 = intLog2(lightW1)
    
    lightWMask2 = not (lightW2 - 1)
    lightHMask2 = not (lightH2 - 1)
    lpDifX2 = -lightX2 - 128 + lightW2 shr 1
    lpDifY2 = -lightY2 - 128 + lightH2 shr 1
    shiftLightW2 = intLog2(lightW2)
    
    yDest = posy + srcH
    xDest = posx + srcW
    startX = posx
    yp = posy
    do
        xp = startX
        do
 
            if fbSrc[srcOffset] <> &hffff00ff then
                scol = fbSrc[srcOffset]
                lv = fbNrmSrc[srcOffset]                 
                
                normCol = ambientLight
                hiCol = 0
                
                lvx = (lv and &hff) + xp + lpDifX1
                lvy = ((lv shr 8) and &hff) + yp + lpDifY1
                if ((lvx and lightWMask1) or (lvy and lightHMask1)) = 0 then
                    lightPLoc = lvy shl shiftLightW1 + lvx
                    normCol = addsatColors(fbDiffSrc1[lightPLoc], normCol)
                    hiCol = addsatColors(fbSpecSrc1[lightPLoc], hiCol)
                end if
                
                lvx = (lv and &hff) + xp + lpDifX2
                lvy = ((lv shr 8) and &hff) + yp + lpDifY2
                if ((lvx and lightWMask2) or (lvy and lightHMask2)) = 0 then
                    lightPLoc = lvy shl shiftLightW2 + lvx
                    normCol = addsatColors(fbDiffSrc2[lightPLoc], normCol)
                    hiCol = addsatColors(fbSpecSrc2[lightPLoc], hiCol)
                end if

                pcol = addsatColors(mulmixColors(scol, normCol), hiCol)
                
                fbDest[destOffset] = pcol
            
            end if
                 
            destOffset += 1
            srcOffset += 1
            xp += 1
        loop while xp < xDest
        destOffset += destStride
        srcOffset += srcStride
        yp += 1
    loop while yp < yDest
   
end sub

'light dimensions must be power of 2
sub transBumpDiffSpecBlit(dest as any ptr, posx as integer, posy as integer,_
                          src as any ptr, nrmSrc as any ptr,_
                          x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                          ambientLight as integer, lightX as integer, lightY as integer,_
                          diffSrc as any ptr, specSrc as any ptr, flags as integer)
    dim as integer ptr fbDest, fbSrc, fbNrmSrc, fbDiffSrc, fbSpecSrc
    dim as integer lightW, lightH, destW, destH, srcW, srcH, lightPLoc
    dim as integer destStride, srcStride
    dim as integer xp, yp, yDest, xDest, lightCol, shiftLightW
    dim as integer lpDifX, lpDifY, lvx, lvy, lv, normCol, hicol, scol, pcol, startX
    dim as integer destPos, destOffset, srcOffset, wCount, lightWMask, lightHMask
    imageinfo dest, destW, destH,, destStride, fbDest
    imageinfo src,,,,srcStride, fbSrc
    imageinfo nrmSrc,,,,,fbNrmSrc
    imageinfo diffSrc, lightW, lightH,,,fbDiffSrc
    imageinfo specSrc,,,,,fbSpecSrc
    srcW = x1 - x0 + 1
    srcH = y1 - y0 + 1
    
    destStride shr= 2
    srcStride shr= 2
    destOffset = destStride*posy + posx
    srcOffset = srcStride*y0 + x0
    destStride -= srcW
    srcStride -= srcW
    lightWMask = not (lightW - 1)
    lightHMask = not (lightH - 1)
    lpDifX = -lightX - 128 + lightW shr 1
    lpDifY = -lightY - 128 + lightH shr 1
    shiftLightW = intLog2(lightW)
    yDest = posy + srcH + lpDifY
    xDest = posx + srcW + lpDifX
    startX = posx + lpDifX
    
    yp = posy + lpDifY
    do
        xp = startX
        do
 
           
            if fbSrc[srcOffset] <> &hffff00ff then
                scol = fbSrc[srcOffset]
                lv = fbNrmSrc[srcOffset]                        
                lvx = (lv and &hff) + xp
                lvy = ((lv shr 8) and &hff) + yp
                
                if ((lvx and lightWMask) or (lvy and lightHMask)) = 0 then
                    lightPLoc = lvy shl shiftLightW + lvx
                    normCol = fbDiffSrc[lightPLoc]
                    hiCol = fbSpecSrc[lightPLoc]
                    
                    lightCol = addsatColors(normCol, ambientLight)
                    pcol = addsatColors(mulmixColors(scol, lightCol), hiCol)
                else
                    pcol = mulmixColors(scol, ambientLight)
                end if
                
                
                fbDest[destOffset] = pcol
            
            end if
            
            
            
            destOffset += 1
            srcOffset += 1
            xp += 1
        loop while xp < xDest
        destOffset += destStride
        srcOffset += srcStride
        yp += 1
    loop while yp < yDest
    
    
end sub

screenres 320,240,32
dim as integer ptr img = imagecreate(32, 64), _
                   img2 = imagecreate(32, 64), _
                   buffer = imagecreate(320,240,0), _
                   light = imagecreate(256, 256), _
                   hilight = imagecreate(256, 256)
bload "asd.bmp", img
bload "asdnrm_norm.bmp", img2
bload "light.bmp", light
bload "hilight.bmp", hilight

dim as integer mx, my
setmouse ,,0
do
    line buffer, (0,0)-(319,239),0,BF
    getmouse mx, my
    transBumpDiffSpecBlit buffer, 200,64,img, img2, 0, 0, 31, 63, rgb(0,0,128), mx, my, light, hilight, 0
    pset buffer, (mx, my)
    put (0,0), buffer, pSEt
    
loop



sleep

end


