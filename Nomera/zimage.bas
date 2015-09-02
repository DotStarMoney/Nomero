#include "zimage.bi"
#include "fbpng.bi"
#include "utility.bi"
#include "vbcompat.bi"

constructor zimage()
    isEmpty = 1
    diffuse_fbimg = 0
    norm_fbimg = 0 
    hasNorm = 0
    clipX = -1
    clipY = -1
end constructor

constructor zimage(filename as string)
    isEmpty = 1 
    diffuse_fbimg = 0
    norm_fbimg = 0 
    hasNorm = 0
    load(filename)
end constructor 

destructor zimage()

end destructor

sub zimage.flush()
    if diffuse_fbimg then imagedestroy(diffuse_fbimg)
    if norm_fbimg then imagedestroy(norm_fbimg)
end sub


sub zimage.setClip(nx as integer, ny as integer)
    clipX = nx
    clipY = ny
end sub

sub zimage.load(filename as string)
    dim as integer f
    dim as string normalFile
    dim as integer i
    dim as integer ptr normPxls
    dim as integer xv, yv
    if right(filename, 4) = ".png" then 
        isPng = 1
        diffuse_fbimg = png_load(filename)
    elseif right(filename, 4) = ".bmp" then
        isPng = 0
        f = freefile
        open filename for binary access read as #f
        get #f, 19, w
        get #f, 23, h
        close #f
        diffuse_fbimg = imagecreate(w, h)
        bload filename, diffuse_fbimg
    end if
    isEmpty = 0
    imageinfo diffuse_fbimg, w, h
    normalFile = left(filename, len(filename)-4) + "_norm"
    if fileexists(normalFile + ".png") then
        normalFile = normalFile + ".png"
        norm_fbimg = png_load(normalFile)
        hasNorm = 1
    elseif fileexists(normalFile + ".bmp") then
        normalFile = normalFile + ".bmp"
        norm_fbimg = imagecreate(w, h)
        bload normalFile, norm_fbimg
        hasNorm = 1
    end if 

end sub


function zimage.getWidth() as integer
    return w
end function

function zimage.getHeight() as integer
    return h
end function

function zimage.getData() as integer ptr
    return diffuse_fbimg
end function

function zimage.getNorm() as integer ptr
    return norm_fbimg
end function

sub zimage.create(wp as integer, hp as integer, diffuse_ as integer ptr, normal_ as integer ptr)
    isEmpty = 0
    isPng = 0
    if normal_ <> 0 then hasNorm = 1
    diffuse_fbimg = diffuse_
    norm_fbimg = normal_
    w = wp
    h = hp
end sub

sub zimage.putTRANS(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                    x0 as integer, y0 as integer, x1 as integer, y1 as integer)

    if dest_fbimg = 0 then
        dim as integer dw, dh
        imageinfo diffuse_fbimg, dw, dh
        print dw, dh
    end if
    put dest_fbimg, (posX, posY), diffuse_fbimg, (x0, y0)-(x1, y1), TRANS      
end sub


sub zimage.putGLOW(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                   x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                   colOffset as integer = &h00000000)
             
    dim as integer npx, npy
    dim as integer sdx0, sdy0, sdx1, sdy1
        
    pmapFix(posX, posY)
    
    if ScreenClip(posX, posY, x1 - x0 + 1, y1 - y0 + 1, npx, npy, sdx0, sdy0, sdx1, sdy1, clipX, clipY) then 
        sdx0 += x0
        sdy0 += y0
        sdx1 += x0
        sdy1 += y0
        
  
        bitblt_alphaGlow(dest_fbimg, npx, npy, diffuse_fbimg, sdx0, sdy0, sdx1, sdy1, colOffset)
                     
    end if         
end sub

sub zimage.putPREALPHA_TARGET(dest_fbimg as integer ptr, prealphasource_fbimg as integer ptr, _
                              posX as integer, posY as integer,_
                              x0 as integer, y0 as integer, x1 as integer, y1 as integer)    
    dim as integer npx, npy
    dim as integer sdx0, sdy0, sdx1, sdy1
        
    pmapFix(posX, posY)
    
    if ScreenClip(posX, posY, x1 - x0 + 1, y1 - y0 + 1, npx, npy, sdx0, sdy0, sdx1, sdy1, clipX, clipY) then 
        sdx0 += x0
        sdy0 += y0
        sdx1 += x0
        sdy1 += y0
        
  
        bitblt_prealpha_target(dest_fbimg, prealphasource_fbimg, npx, npy, diffuse_fbimg, sdx0, sdy0, sdx1, sdy1)
                     
    end if                                   
                              
end sub

sub zimage.putPREALPHA(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                       x0 as integer, y0 as integer, x1 as integer, y1 as integer)
    dim as integer npx, npy
    dim as integer sdx0, sdy0, sdx1, sdy1
        
    pmapFix(posX, posY)
    
    if ScreenClip(posX, posY, x1 - x0 + 1, y1 - y0 + 1, npx, npy, sdx0, sdy0, sdx1, sdy1, clipX, clipY) then 
        sdx0 += x0
        sdy0 += y0
        sdx1 += x0
        sdy1 += y0
        
        bitblt_prealpha(dest_fbimg, npx, npy, diffuse_fbimg, sdx0, sdy0, sdx1, sdy1)
                     
    end if                                           
                       
end sub
             
sub zimage.putTRANS_0xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                            x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                            ambientLight as integer = &h00000000)  

    dim as integer npx, npy
    dim as integer sdx0, sdy0, sdx1, sdy1
    
    pmapFix(posX, posY)
    
    if ScreenClip(posX, posY, x1 - x0 + 1, y1 - y0 + 1, npx, npy, sdx0, sdy0, sdx1, sdy1, clipX, clipY) then 
        sdx0 += x0
        sdy0 += y0
        sdx1 += x0
        sdy1 += y0
        
        bitblt_transMulMix(dest_fbimg, npx, npy, diffuse_fbimg, sdx0, sdy0, sdx1, sdy1, ambientLight)
           
    end if  

end sub                            
      
sub zimage.putTRANS_1xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                            x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                            ambientLight as integer = &h00000000,_
                            light1 as PointLight)
                               
    #macro MULMIX(XMMA, XMMB)    
        punpcklbw   XMMA,               xmm6
        punpcklbw   XMMB,               xmm6
        pmullw      XMMA,               XMMB
        psrlw		XMMA, 	        	8
        packuswb    XMMA,               XMMA    
    #endmacro
    
    #macro MULMIX_W(XMMA, XMMB)    
        punpcklbw   XMMA,               xmm6
        pmullw      XMMA,               XMMB
        psrlw		XMMA, 	        	8
        packuswb    XMMA,               XMMA    
    #endmacro
    
    #macro ADDSAT(XMMA, XMMB)
        paddusb     XMMA,               XMMB
    #endmacro
     
    dim as integer     npx, npy, opx, opy
    dim as integer     sdx0, sdy0, sdx1, sdy1
    dim as integer ptr fbDest, fbSrc, fbNrmSrc
    
    dim as integer ptr fbDiffSrc1, fbSpecSrc1
    dim as integer lpDifX1, lpDifY1, lightW1, lightH1
    dim as integer lightWMask1, lightHMask1
    dim as integer shiftLightW1
    
    dim as integer destW, destH, srcW, srcH, lightPLoc
    dim as integer destStride, srcStride, xbN, ybN
    dim as integer xp, yp, yDest, xDest, lightCol
    dim as integer lvx, lvy, lv, normCol, hicol, scol, pcol, startX
    dim as integer destPos, destOffset, srcOffset, wCount
        
    if norm_fbimg = 0 then
        putTRANS_0xLight(dest_fbimg, posX, posY,_
                         x0, y0, x1, y1,_
                         ambientLight)
        exit sub
    end if   
   
    opx = posX
    opy = posY
    
    pmapFix(posX, posY)
    
    if ScreenClip(posX, posY, x1 - x0 + 1, y1 - y0 + 1, npx, npy, sdx0, sdy0, sdx1, sdy1, clipX, clipY) then 
        sdx0 += x0
        sdy0 += y0
        sdx1 += x0
        sdy1 += y0
            
        imageinfo dest_fbimg, destW, destH,, destStride, fbDest
        imageinfo diffuse_fbimg,,,,srcStride, fbSrc
        imageinfo norm_fbimg,,,,,fbNrmSrc
        
        imageinfo light1.diffuse_fbimg, lightW1, lightH1,,,fbDiffSrc1
        imageinfo light1.specular_fbimg,,,,,fbSpecSrc1

        srcW = sdx1 - sdx0 + 1
        srcH = sdy1 - sdy0 + 1
    
        destOffset = destStride*npy + npx shl 2
        srcOffset = srcStride*sdy0 + sdx0 shl 2
        destStride -= srcW shl 2
        srcStride -= srcW shl 2
        
        lightWMask1 = not (lightW1 - 1)
        lightHMask1 = not (lightH1 - 1)
        lpDifX1 = -light1.x - 128 + lightW1 shr 1
        lpDifY1 = -light1.y - 128 + lightH1 shr 1
        shiftLightW1 = intLog2(lightW1)
        
        xDest = opx + (sdx0 - x0) + srcW
        yDest = opy + (sdy0 - y0) + srcH
        startX = opx + (sdx0 - x0)
        
        yp = opy + (sdy0 - y0)
        asm
                mov         esi,                [destOffset]
                mov         edi,                [srcOffset]
                movd        xmm7,               [ambientLight]
                pxor        xmm6,               xmm6
            
            zimage_putTRANS_1xLight_rows:
                
                mov         eax,                [startX]
                mov         [xp],               eax
            
            zimage_putTRANS_1xLight_cols:
            
                mov         eax,                [fbSrc]
                cmp         dword ptr[eax+edi], &hffff00ff
                je          zimage_putTRANS_1xLight_endCol
               
                movdqa      xmm1,               xmm7
                pxor        xmm2,               xmm2
                
                movd        xmm0,               [eax+edi]
                mov         eax,                [fbNrmSrc]
                mov         eax,                [eax+edi]
                                             
                movzbl      ebx,                al
                add         ebx,                [xp]
                mov         [xbN],              ebx
                movzbl      ebx,                ah
                add         ebx,                [yp]
                mov         [ybN],              ebx
                shr         eax,                8
                movzbl      ebx,                ah
                movd        xmm5,               ebx
                punpcklbw   xmm5,               xmm6
                pshuflw     xmm5,               xmm5,               &h00
                                
                '----------------------- LIGHT 1 -----------------------------

                mov         eax,                [xbN]
                add         eax,                [lpDifX1]
                mov         ebx,                [ybN]
                add         ebx,                [lpDifY1]
                mov         ecx,                eax
                mov         edx,                ebx
                
                and         eax,                [lightWMask1]
                and         ebx,                [lightHMask1]
                or          eax,                ebx
            
                jnz         zimage_putTRANS_1xLight_light1
                
                mov         eax,                ecx
                mov         ebx,                edx
                mov         cl,                 [shiftLightW1]
                shl         ebx,                cl
                add         eax,                ebx

                mov         ecx,                [fbDiffSrc1]
                movd        xmm3,               [ecx+eax*4]
                mov         ecx,                [fbSpecSrc1]
                movd        xmm4,               [ecx+eax*4]
                 
                ADDSAT(     xmm1,               xmm3)
                ADDSAT(     xmm2,               xmm4)
                
            zimage_putTRANS_1xLight_light1:    

                '--------------------------------------------------------------
                          
                MULMIX(     xmm0,               xmm1)
                
                MULMIX_W(   xmm2,               xmm5)  
                ADDSAT(     xmm0,               xmm2)
                
                mov         eax,                [fbDest]
                movd        [esi+eax],          xmm0

            zimage_putTRANS_1xLight_endCol:    
            
                add         esi,                4
                add         edi,                4
                    
                inc         dword ptr[xp]
                mov         eax,                [xp]
                cmp         eax,                [xDest]
                jl          zimage_putTRANS_1xLight_cols
                    
                add         esi,                [destStride]
                add         edi,                [srcStride]
                inc         dword ptr[yp]
                mov         eax,                [yp]
                cmp         eax,                [yDest]
                jl          zimage_putTRANS_1xLight_rows
        end asm   
    end if             
end sub


sub zimage.putTRANS_2xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                            x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                            ambientLight as integer = &h00000000,_
                            light1 as PointLight, light2 as PointLight)
    
                               
    #macro MULMIX(XMMA, XMMB)    
        punpcklbw   XMMA,               xmm6
        punpcklbw   XMMB,               xmm6
        pmullw      XMMA,               XMMB
        psrlw		XMMA, 	        	8
        packuswb    XMMA,               XMMA    
    #endmacro
    
    #macro MULMIX_W(XMMA, XMMB)    
        punpcklbw   XMMA,               xmm6
        pmullw      XMMA,               XMMB
        psrlw		XMMA, 	        	8
        packuswb    XMMA,               XMMA    
    #endmacro
    
    #macro ADDSAT(XMMA, XMMB)
        paddusb     XMMA,               XMMB
    #endmacro
     
    dim as integer     npx, npy, opx, opy
    dim as integer     sdx0, sdy0, sdx1, sdy1
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
    dim as integer destStride, srcStride, xbN, ybN
    dim as integer xp, yp, yDest, xDest, lightCol
    dim as integer lvx, lvy, lv, normCol, hicol, scol, pcol, startX
    dim as integer destPos, destOffset, srcOffset, wCount
        
    if norm_fbimg = 0 then
        putTRANS_0xLight(dest_fbimg, posX, posY,_
                         x0, y0, x1, y1,_
                         ambientLight)
        exit sub
    end if   
   
    opx = posX
    opy = posY
    
    pmapFix(posX, posY)
    
    if ScreenClip(posX, posY, x1 - x0 + 1, y1 - y0 + 1, npx, npy, sdx0, sdy0, sdx1, sdy1, clipX, clipY) then 
        sdx0 += x0
        sdy0 += y0
        sdx1 += x0
        sdy1 += y0
            
        imageinfo dest_fbimg, destW, destH,, destStride, fbDest
        imageinfo diffuse_fbimg,,,,srcStride, fbSrc
        imageinfo norm_fbimg,,,,,fbNrmSrc
        
        imageinfo light1.diffuse_fbimg, lightW1, lightH1,,,fbDiffSrc1
        imageinfo light1.specular_fbimg,,,,,fbSpecSrc1
        
        imageinfo light2.diffuse_fbimg, lightW2, lightH2,,,fbDiffSrc2
        imageinfo light2.specular_fbimg,,,,,fbSpecSrc2

        srcW = sdx1 - sdx0 + 1
        srcH = sdy1 - sdy0 + 1
    
        destOffset = destStride*npy + npx shl 2
        srcOffset = srcStride*sdy0 + sdx0 shl 2
        destStride -= srcW shl 2
        srcStride -= srcW shl 2
        
        lightWMask1 = not (lightW1 - 1)
        lightHMask1 = not (lightH1 - 1)
        lpDifX1 = -light1.x - 128 + lightW1 shr 1
        lpDifY1 = -light1.y - 128 + lightH1 shr 1
        shiftLightW1 = intLog2(lightW1)
        
        lightWMask2 = not (lightW2 - 1)
        lightHMask2 = not (lightH2 - 1)
        lpDifX2 = -light2.x - 128 + lightW2 shr 1
        lpDifY2 = -light2.y - 128 + lightH2 shr 1
        shiftLightW2 = intLog2(lightW2)
        
        xDest = opx + (sdx0 - x0) + srcW
        yDest = opy + (sdy0 - y0) + srcH
        startX = opx + (sdx0 - x0)
        
        yp = opy + (sdy0 - y0)
        asm
                mov         esi,                [destOffset]
                mov         edi,                [srcOffset]
                movd        xmm7,               [ambientLight]
                pxor        xmm6,               xmm6
            
            zimage_putTRANS_2xLight_rows:
                
                mov         eax,                [startX]
                mov         [xp],               eax
            
            zimage_putTRANS_2xLight_cols:
            
                mov         eax,                [fbSrc]
                cmp         dword ptr[eax+edi], &hffff00ff
                je          zimage_putTRANS_2xLight_endCol
               
                movdqa      xmm1,               xmm7
                pxor        xmm2,               xmm2
                
                movd        xmm0,               [eax+edi]
                mov         eax,                [fbNrmSrc]
                mov         eax,                [eax+edi]
                                             
                movzbl      ebx,                al
                add         ebx,                [xp]
                mov         [xbN],              ebx
                movzbl      ebx,                ah
                add         ebx,                [yp]
                mov         [ybN],              ebx
                shr         eax,                8
                movzbl      ebx,                ah
                movd        xmm5,               ebx
                punpcklbw   xmm5,               xmm6
                pshuflw     xmm5,               xmm5,               &h00
                                
                '----------------------- LIGHT 1 -----------------------------

                mov         eax,                [xbN]
                add         eax,                [lpDifX1]
                mov         ebx,                [ybN]
                add         ebx,                [lpDifY1]
                mov         ecx,                eax
                mov         edx,                ebx
                
                and         eax,                [lightWMask1]
                and         ebx,                [lightHMask1]
                or          eax,                ebx
            
                jnz         zimage_putTRANS_2xLight_light1
                
                mov         eax,                ecx
                mov         ebx,                edx
                mov         cl,                 [shiftLightW1]
                shl         ebx,                cl
                add         eax,                ebx

                mov         ecx,                [fbDiffSrc1]
                movd        xmm3,               [ecx+eax*4]
                mov         ecx,                [fbSpecSrc1]
                movd        xmm4,               [ecx+eax*4]
                 
                ADDSAT(     xmm1,               xmm3)
                ADDSAT(     xmm2,               xmm4)
                
            zimage_putTRANS_2xLight_light1:    

                '--------------------------------------------------------------
                
                '----------------------- LIGHT 2 -----------------------------

                mov         eax,                [xbN]
                add         eax,                [lpDifX2]
                mov         ebx,                [ybN]
                add         ebx,                [lpDifY2]
                mov         ecx,                eax
                mov         edx,                ebx
                
                and         eax,                [lightWMask2]
                and         ebx,                [lightHMask2]
                or          eax,                ebx
            
                jnz         zimage_putTRANS_2xLight_light2
                
                mov         eax,                ecx
                mov         ebx,                edx
                mov         cl,                 [shiftLightW2]
                shl         ebx,                cl
                add         eax,                ebx

                mov         ecx,                [fbDiffSrc2]
                movd        xmm3,               [ecx+eax*4]
                mov         ecx,                [fbSpecSrc2]
                movd        xmm4,               [ecx+eax*4]
                 
                ADDSAT(     xmm1,               xmm3)
                ADDSAT(     xmm2,               xmm4)
                
            zimage_putTRANS_2xLight_light2:    

                '--------------------------------------------------------------
                          
                MULMIX(     xmm0,               xmm1)
                
                MULMIX_W(   xmm2,               xmm5)  
                ADDSAT(     xmm0,               xmm2)
                
                mov         eax,                [fbDest]
                movd        [esi+eax],          xmm0

            zimage_putTRANS_2xLight_endCol:    
            
                add         esi,                4
                add         edi,                4
                    
                inc         dword ptr[xp]
                mov         eax,                [xp]
                cmp         eax,                [xDest]
                jl          zimage_putTRANS_2xLight_cols
                    
                add         esi,                [destStride]
                add         edi,                [srcStride]
                inc         dword ptr[yp]
                mov         eax,                [yp]
                cmp         eax,                [yDest]
                jl          zimage_putTRANS_2xLight_rows
        end asm   
    end if     
end sub                   

sub zimage.putTRANS_3xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                            x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                            ambientLight as integer = &h00000000,_
                            light1 as PointLight, light2 as PointLight, light3 as PointLight)
    
                               
    #macro MULMIX(XMMA, XMMB)    
        punpcklbw   XMMA,               xmm6
        punpcklbw   XMMB,               xmm6
        pmullw      XMMA,               XMMB
        psrlw		XMMA, 	        	8
        packuswb    XMMA,               XMMA    
    #endmacro
    
    #macro MULMIX_W(XMMA, XMMB)    
        punpcklbw   XMMA,               xmm6
        pmullw      XMMA,               XMMB
        psrlw		XMMA, 	        	8
        packuswb    XMMA,               XMMA    
    #endmacro
    
    #macro ADDSAT(XMMA, XMMB)
        paddusb     XMMA,               XMMB
    #endmacro
     
    dim as integer     npx, npy, opx, opy
    dim as integer     sdx0, sdy0, sdx1, sdy1
    dim as integer ptr fbDest, fbSrc, fbNrmSrc
    
    dim as integer ptr fbDiffSrc1, fbSpecSrc1
    dim as integer lpDifX1, lpDifY1, lightW1, lightH1
    dim as integer lightWMask1, lightHMask1
    dim as integer shiftLightW1
    
    dim as integer ptr fbDiffSrc2, fbSpecSrc2
    dim as integer lpDifX2, lpDifY2, lightW2, lightH2
    dim as integer lightWMask2, lightHMask2
    dim as integer shiftLightW2
    
    dim as integer ptr fbDiffSrc3, fbSpecSrc3
    dim as integer lpDifX3, lpDifY3, lightW3, lightH3
    dim as integer lightWMask3, lightHMask3
    dim as integer shiftLightW3
    
    dim as integer destW, destH, srcW, srcH, lightPLoc
    dim as integer destStride, srcStride, xbN, ybN
    dim as integer xp, yp, yDest, xDest, lightCol
    dim as integer lvx, lvy, lv, normCol, hicol, scol, pcol, startX
    dim as integer destPos, destOffset, srcOffset, wCount
        
    if norm_fbimg = 0 then
        putTRANS_0xLight(dest_fbimg, posX, posY,_
                         x0, y0, x1, y1,_
                         ambientLight)
        exit sub
    end if   
   
    opx = posX
    opy = posY
    
    pmapFix(posX, posY)
    
    if ScreenClip(posX, posY, x1 - x0 + 1, y1 - y0 + 1, npx, npy, sdx0, sdy0, sdx1, sdy1, clipX, clipY) then 
        sdx0 += x0
        sdy0 += y0
        sdx1 += x0
        sdy1 += y0
            
        imageinfo dest_fbimg, destW, destH,, destStride, fbDest
        imageinfo diffuse_fbimg,,,,srcStride, fbSrc
        imageinfo norm_fbimg,,,,,fbNrmSrc
        
        imageinfo light1.diffuse_fbimg, lightW1, lightH1,,,fbDiffSrc1
        imageinfo light1.specular_fbimg,,,,,fbSpecSrc1
        
        imageinfo light2.diffuse_fbimg, lightW2, lightH2,,,fbDiffSrc2
        imageinfo light2.specular_fbimg,,,,,fbSpecSrc2
        
        imageinfo light3.diffuse_fbimg, lightW3, lightH3,,,fbDiffSrc3
        imageinfo light3.specular_fbimg,,,,,fbSpecSrc3

        srcW = sdx1 - sdx0 + 1
        srcH = sdy1 - sdy0 + 1
    
        destOffset = destStride*npy + npx shl 2
        srcOffset = srcStride*sdy0 + sdx0 shl 2
        destStride -= srcW shl 2
        srcStride -= srcW shl 2
        
        lightWMask1 = not (lightW1 - 1)
        lightHMask1 = not (lightH1 - 1)
        lpDifX1 = -light1.x - 128 + lightW1 shr 1
        lpDifY1 = -light1.y - 128 + lightH1 shr 1
        shiftLightW1 = intLog2(lightW1)
        
        lightWMask2 = not (lightW2 - 1)
        lightHMask2 = not (lightH2 - 1)
        lpDifX2 = -light2.x - 128 + lightW2 shr 1
        lpDifY2 = -light2.y - 128 + lightH2 shr 1
        shiftLightW2 = intLog2(lightW2)
        
        lightWMask3 = not (lightW3 - 1)
        lightHMask3 = not (lightH3 - 1)
        lpDifX3 = -light3.x - 128 + lightW3 shr 1
        lpDifY3 = -light3.y - 128 + lightH3 shr 1
        shiftLightW3 = intLog2(lightW3)
        
        xDest = opx + (sdx0 - x0) + srcW
        yDest = opy + (sdy0 - y0) + srcH
        startX = opx + (sdx0 - x0)
        
        yp = opy + (sdy0 - y0)
        asm
                mov         esi,                [destOffset]
                mov         edi,                [srcOffset]
                movd        xmm7,               [ambientLight]
                pxor        xmm6,               xmm6
            
            zimage_putTRANS_3xLight_rows:
                
                mov         eax,                [startX]
                mov         [xp],               eax
            
            zimage_putTRANS_3xLight_cols:
            
                mov         eax,                [fbSrc]
                cmp         dword ptr[eax+edi], &hffff00ff
                je          zimage_putTRANS_3xLight_endCol
               
                movdqa      xmm1,               xmm7
                pxor        xmm2,               xmm2
                
                movd        xmm0,               [eax+edi]
                mov         eax,                [fbNrmSrc]
                mov         eax,                [eax+edi]
                                             
                movzbl      ebx,                al
                add         ebx,                [xp]
                mov         [xbN],              ebx
                movzbl      ebx,                ah
                add         ebx,                [yp]
                mov         [ybN],              ebx
                shr         eax,                8
                movzbl      ebx,                ah
                movd        xmm5,               ebx
                punpcklbw   xmm5,               xmm6
                pshuflw     xmm5,               xmm5,               &h00
                                
                '----------------------- LIGHT 1 -----------------------------

                mov         eax,                [xbN]
                add         eax,                [lpDifX1]
                mov         ebx,                [ybN]
                add         ebx,                [lpDifY1]
                mov         ecx,                eax
                mov         edx,                ebx
                
                and         eax,                [lightWMask1]
                and         ebx,                [lightHMask1]
                or          eax,                ebx
            
                jnz         zimage_putTRANS_3xLight_light1
                
                mov         eax,                ecx
                mov         ebx,                edx
                mov         cl,                 [shiftLightW1]
                shl         ebx,                cl
                add         eax,                ebx

                mov         ecx,                [fbDiffSrc1]
                movd        xmm3,               [ecx+eax*4]
                mov         ecx,                [fbSpecSrc1]
                movd        xmm4,               [ecx+eax*4]
                 
                ADDSAT(     xmm1,               xmm3)
                ADDSAT(     xmm2,               xmm4)
                
            zimage_putTRANS_3xLight_light1:    

                '--------------------------------------------------------------
                
                '----------------------- LIGHT 2 -----------------------------

                mov         eax,                [xbN]
                add         eax,                [lpDifX2]
                mov         ebx,                [ybN]
                add         ebx,                [lpDifY2]
                mov         ecx,                eax
                mov         edx,                ebx
                
                and         eax,                [lightWMask2]
                and         ebx,                [lightHMask2]
                or          eax,                ebx
            
                jnz         zimage_putTRANS_3xLight_light2
                
                mov         eax,                ecx
                mov         ebx,                edx
                mov         cl,                 [shiftLightW2]
                shl         ebx,                cl
                add         eax,                ebx

                mov         ecx,                [fbDiffSrc2]
                movd        xmm3,               [ecx+eax*4]
                mov         ecx,                [fbSpecSrc2]
                movd        xmm4,               [ecx+eax*4]
                 
                ADDSAT(     xmm1,               xmm3)
                ADDSAT(     xmm2,               xmm4)
                
            zimage_putTRANS_3xLight_light2:    

                '--------------------------------------------------------------
                
                '----------------------- LIGHT 3 -----------------------------

                mov         eax,                [xbN]
                add         eax,                [lpDifX3]
                mov         ebx,                [ybN]
                add         ebx,                [lpDifY3]
                mov         ecx,                eax
                mov         edx,                ebx
                
                and         eax,                [lightWMask3]
                and         ebx,                [lightHMask3]
                or          eax,                ebx
            
                jnz         zimage_putTRANS_3xLight_light3
                
                mov         eax,                ecx
                mov         ebx,                edx
                mov         cl,                 [shiftLightW3]
                shl         ebx,                cl
                add         eax,                ebx

                mov         ecx,                [fbDiffSrc3]
                movd        xmm3,               [ecx+eax*4]
                mov         ecx,                [fbSpecSrc3]
                movd        xmm4,               [ecx+eax*4]
                 
                ADDSAT(     xmm1,               xmm3)
                ADDSAT(     xmm2,               xmm4)
                
            zimage_putTRANS_3xLight_light3:    

                '--------------------------------------------------------------
                          
                MULMIX(     xmm0,               xmm1)
                
                MULMIX_W(   xmm2,               xmm5)  
                ADDSAT(     xmm0,               xmm2)
                
                mov         eax,                [fbDest]
                movd        [esi+eax],          xmm0

            zimage_putTRANS_3xLight_endCol:    
            
                add         esi,                4
                add         edi,                4
                    
                inc         dword ptr[xp]
                mov         eax,                [xp]
                cmp         eax,                [xDest]
                jl          zimage_putTRANS_3xLight_cols
                    
                add         esi,                [destStride]
                add         edi,                [srcStride]
                inc         dword ptr[yp]
                mov         eax,                [yp]
                cmp         eax,                [yDest]
                jl          zimage_putTRANS_3xLight_rows
        end asm   
    end if       
end sub

