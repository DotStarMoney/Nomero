#include "electricarc.bi"
#include "vector2d.bi"
#include "utility.bi"
#include "hashtable.bi"

dim as integer ElectricArc.toneMap(0 to 255)
dim as integer ElectricArc.toneMap_setup = 0
constructor ElectricArc()
    reset_construct()
end constructor
constructor ElectricArc(planeW as integer, planeH as integer)
    reset_construct()
    init(planeW, planeH)
end constructor
sub ElectricArc.clean()
    if arcSmoothData_alloc <> 0 then deallocate(arcSmoothData_alloc)
    if arcSpineData_alloc <> 0 then deallocate(arcSpineData_alloc)
    if arcGlowData_alloc <> 0 then deallocate(arcGlowData_alloc)  
    if activeBlockFiles <> 0 then deallocate(activeBlockFiles)  
    if activeBlockList <> 0 then deallocate(activeBlockList)     
    flush()
end sub
sub ElectricArc.reset_construct()
    dim as integer i, tone
    dim as double  expVal
    if toneMap_setup = 0 then
        expVal = 0.8
        toneMap_setup = 1
        for i = 0 to 255
            tone = ((i/255)^(expval))*255
            toneMap(i) = rgb(tone*0.7, tone*0.8, tone)
        next i
    end if
    generate = 0
    planeWidth = 0
    planeHeight = 0
    blockW = 0
    blockH = 0
    arcSpineData = 0
    arcGlowData = 0
    arcSmoothData = 0
    arcSpineData_alloc = 0
    arcGlowData_alloc = 0
    arcSmoothData_alloc = 0
    activeBlockFiles = 0
    activeBlockList = 0
    activeBlockList_N = 0   
end sub
destructor ElectricArc()
    clean()
end destructor 

sub ElectricArc.drawArcLine(x1 as integer, y1 as integer,_
                            x2 as integer, y2 as integer)
    Dim as integer x, y, Dx, Dy, Dn, Dp, Ek, DirY, stride
    dim as integer ptr offset
    If x2 < x1 Then 
        Swap x1, x2
        Swap y1, y2
    End if
    
    if x1 <  0          then exit sub
    if x2 >= planeWidth then exit sub
    if y1 < y2 then
        if y1 < 0 then exit sub
        if y2 >= planeHeight then exit sub
    else
        if y2 < 0 then exit sub
        if y1 >= planeHeight then exit sub
    end if
    
    x = x1
    y = y1
    Dx = x2 - x1
    Dy = y2 - y1: DirY = Sgn(Dy)
    stride = sgn(dy)*planeWidth
    Dy = ABs(dy)
    offset = arcSpineData + planeWidth*y1 + x1
    If Dx >= Dy Then
        Ek = 2 * Dy - Dx
        Dn = Ek + Dx
        Dp = Ek - Dx
        Do 
            *offset = 1
            x += 1
            offset += 1
            If Ek < 0 Then
                Ek = Ek + Dn
            Else
                Ek = Ek + Dp
                offset += stride
            End If
        Loop while x <= x2
    Else
        Ek = 2 * Dx - Dy
        Dn = Ek + Dy
        Dp = Ek - Dy
        Do 
            *offset = 1
            y += DirY
            offset += stride
            If Ek < 0 Then
                Ek = Ek + Dn
            Else
                Ek = Ek + Dp
                offset += 1
            End If
        Loop While y <> y2
        *offset = 1
    End if
end sub

sub ElectricArc.accSquareR5()
    
    dim as integer stride, stride_hi, stride_res
    dim as integer i, bx, by
    dim as integer ptr offsetS, offsetD
    
    stride_res = (BLOCK_SIZE*planeWidth - 1) shl 2

    stride_hi = (planeWidth*9) shl 2
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then
            stride = (planeWidth - BLOCK_SIZE) shl 2
            offsetS = arcSpineData + by*planeWidth + bx - 4
            offsetD = arcSmoothData + by*planeWidth + bx
            asm
                    mov     esi,        [offsetS]
                    mov     edi,        [offsetD]
                    mov     edx,        [stride]
                    mov     ebx,        BLOCK_SIZE
                    
                electricarc_blurR5_00_H0_row:
                
                    mov     eax,        BLOCK_SIZE
                
                    mov     ecx,        [esi]
                    add     ecx,        [esi+4]
                    add     ecx,        [esi+8]
                    add     ecx,        [esi+12]
                    add     ecx,        [esi+16]
                    add     ecx,        [esi+20]
                    add     ecx,        [esi+24]
                    add     ecx,        [esi+28]
                    add     ecx,        [esi+32]  
                    
                electricarc_blurR5_00_H0_col:
               
                    mov     [edi],      ecx
                    
                    sub     ecx,        [esi]
                    add     ecx,        [esi+36]
                    add     esi,        4
                    add     edi,        4
                    
                    dec     eax
                    jnz     electricarc_blurR5_00_H0_col
                    
                    add     esi,        edx
                    add     edi,        edx
                    dec     ebx
                    jnz     electricarc_blurR5_00_H0_row
                    
            end asm
        else
            accSquareR5_XH(arcSpineData, arcSmoothData, bx, by, 4)
        end if
    next i
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then
            stride = planeWidth shl 2
            offsetS = arcSmoothData + (by - 4)*planeWidth + bx
            offsetD = arcGlowData + by*planeWidth + bx
            asm
                    mov     esi,        [offsetS]
                    mov     edi,        [offsetD]
                    mov     ebx,        BLOCK_SIZE
                    
                electricarc_blurR5_00_V0_row:
                
                    mov     eax,        BLOCK_SIZE
                    mov     edx,        esi
                
                    mov     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
        
                    mov     esi,        edx
                    mov     edx,        [stride_hi]
        
                electricarc_blurR5_00_V0_col:
               
                    mov     [edi],      ecx
                    
                    sub     ecx,        [esi]
                    add     ecx,        [esi+edx]
                    
                    add     esi,        [stride]
                    add     edi,        [stride]
        
                    dec     eax
                    jnz     electricarc_blurR5_00_V0_col
                    
                    sub     esi,        [stride_res]
                    sub     edi,        [stride_res]
                    
                    dec     ebx
                    jnz     electricarc_blurR5_00_V0_row
                    
            end asm
        else
            accSquareR5_XV(arcSmoothData, arcGlowData, bx, by, 4)
        end if
    next i
    
    stride_hi = (planeWidth*11) shl 2
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then    
            stride = (planeWidth - BLOCK_SIZE) shl 2
            offsetS = arcGlowData + by*planeWidth + bx - 5
            offsetD = arcSmoothData + by*planeWidth + bx
            asm
                    mov     esi,        [offsetS]
                    mov     edi,        [offsetD]
                    mov     edx,        [stride]
                    mov     ebx,        BLOCK_SIZE
                    
                electricarc_blurR5_00_H1_row:
                
                    mov     eax,        BLOCK_SIZE
                
                    mov     ecx,        [esi]
                    add     ecx,        [esi+4]
                    add     ecx,        [esi+8]
                    add     ecx,        [esi+12]
                    add     ecx,        [esi+16]
                    add     ecx,        [esi+20]
                    add     ecx,        [esi+24]
                    add     ecx,        [esi+28]
                    add     ecx,        [esi+32]
                    add     ecx,        [esi+36]
                    add     ecx,        [esi+40]   
                    
                electricarc_blurR5_00_H1_col:
               
                    mov     [edi],      ecx
                    
                    sub     ecx,        [esi]
                    add     ecx,        [esi+44]
                    add     esi,        4
                    add     edi,        4
                    
                    dec     eax
                    jnz     electricarc_blurR5_00_H1_col
                    
                    add     esi,        edx
                    add     edi,        edx
                    dec     ebx
                    jnz     electricarc_blurR5_00_H1_row
            end asm
        else
            accSquareR5_XH(arcGlowData, arcSmoothData, bx, by, 5)
        end if
    next i
    
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then    
            stride = planeWidth shl 2
            offsetS = arcSmoothData + (by - 5)*planeWidth + bx
            offsetD = arcGlowData + by*planeWidth + bx
            asm
                    mov     esi,        [offsetS]
                    mov     edi,        [offsetD]
                    mov     ebx,        BLOCK_SIZE
                    
                electricarc_blurR5_00_V1_row:
                
                    mov     eax,        BLOCK_SIZE
                    mov     edx,        esi
                    
                    mov     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    
                    mov     esi,        edx
                    mov     edx,        [stride_hi]
        
                electricarc_blurR5_00_V1_col:
               
                    mov     [edi],      ecx
                    
                    sub     ecx,        [esi]
                    add     ecx,        [esi+edx]
                    
                    add     esi,        [stride]
                    add     edi,        [stride]
                    
                    dec     eax
                    jnz     electricarc_blurR5_00_V1_col
                    
                    sub     esi,        [stride_res]
                    sub     edi,        [stride_res]
                    
                    dec     ebx
                    jnz     electricarc_blurR5_00_V1_row
            end asm    
        else
            accSquareR5_XV(arcSmoothData, arcGlowData, bx, by, 5)            
        end if
    next i
    
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then  
            stride = (planeWidth - BLOCK_SIZE) shl 2
            offsetS = arcGlowData + by*planeWidth + bx - 5
            offsetD = arcSmoothData + by*planeWidth + bx
            asm
                    mov     esi,        [offsetS]
                    mov     edi,        [offsetD]
                    mov     edx,        [stride]
                    mov     ebx,        BLOCK_SIZE
                    
                electricarc_blurR5_00_H2_row:
                
                    mov     eax,        BLOCK_SIZE
                
                    mov     ecx,        [esi]
                    add     ecx,        [esi+4]
                    add     ecx,        [esi+8]
                    add     ecx,        [esi+12]
                    add     ecx,        [esi+16]
                    add     ecx,        [esi+20]
                    add     ecx,        [esi+24]
                    add     ecx,        [esi+28]
                    add     ecx,        [esi+32]
                    add     ecx,        [esi+36]
                    add     ecx,        [esi+40]   
                    
                electricarc_blurR5_00_H2_col:
               
                    mov     [edi],      ecx
                    
                    sub     ecx,        [esi]
                    add     ecx,        [esi+44]
                    add     esi,        4
                    add     edi,        4
                    
                    dec     eax
                    jnz     electricarc_blurR5_00_H2_col
                    
                    add     esi,        edx
                    add     edi,        edx
                    dec     ebx
                    jnz     electricarc_blurR5_00_H2_row
                    
            end asm
        else
            accSquareR5_XH(arcGlowData, arcSmoothData, bx, by, 5)            
        end if
    next i
       
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then  
            stride = planeWidth shl 2
            offsetS = arcSmoothData + (by - 5)*planeWidth + bx
            offsetD = arcGlowData + by*planeWidth + bx
            asm
                    mov     esi,        [offsetS]
                    mov     edi,        [offsetD]
                    mov     ebx,        BLOCK_SIZE
                    
                electricarc_blurR5_00_V2_row:
                
                    mov     eax,        BLOCK_SIZE
                    mov     edx,        esi
                
                    mov     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    add     esi,        [stride]
                    add     ecx,        [esi]
                    
                    mov     esi,        edx
                    mov     edx,        [stride_hi]
        
                electricarc_blurR5_00_V2_col:
               
                    mov     [edi],      ecx
                    
                    sub     ecx,        [esi]
                    add     ecx,        [esi+edx]
                    
                    add     esi,        [stride]
                    add     edi,        [stride]
                    
                    dec     eax
                    jnz     electricarc_blurR5_00_V2_col
                    
                    sub     esi,        [stride_res]
                    sub     edi,        [stride_res]
                    
                    dec     ebx
                    jnz     electricarc_blurR5_00_V2_row
            end asm    
        else
            accSquareR5_XV(arcSmoothData, arcGlowData, bx, by, 5)                        
        end if
    next i
    
end sub

sub ElectricArc.accSquareR5_XH(src as integer ptr, dest as integer ptr,_
                               bx as integer, by as integer, r as integer)
    dim as integer row, col
    dim as integer xs, xe
    dim as integer ys, ye
    dim as integer accStart, accEnd, stride
    dim as integer rh
    dim as double acc, samples
    dim as integer ptr offsetS, offsetD, offsetAcc
    
    rh = r*2 + 1
    
    xs = bx
    ys = by
    xe = xs + BLOCK_SIZE - 1
    ye = ys + BLOCK_SIZE - 1
    
    offsetS = src + by*planeWidth + bx - r
    offsetD = dest + by*planeWidth + bx    
    stride = planeWidth - BLOCK_SIZE
    for row = ys to ye
        accStart = xs - r
        accEnd = xs + r
        acc = 0.0
        samples = 0.0
        offsetAcc = offsetS
        for col = accStart to accEnd
            if col >= 0 then
                acc += *offsetAcc
                samples += 1
            end if
            offsetAcc += 1
        next col
        for col = xs to xe
            *offsetD = int(acc * (rh / samples))
            if (col - r) >= 0 then 
                acc -= *offsetS
                samples -= 1
            end if
            if (col + r) < planeWidth then 
                acc += *(offsetS + rh)
                samples += 1
            end if
            offsetS += 1
            offsetD += 1
        next col
        offsetS += stride
        offsetD += stride
    next row    
end sub

sub ElectricArc.accSquareR5_XV(src as integer ptr, dest as integer ptr,_
                               bx as integer, by as integer, r as integer)
    dim as integer row, col
    dim as integer xs, xe
    dim as integer ys, ye
    dim as integer accStart, accEnd, stride, hi_stride
    dim as integer rh
    dim as double acc, samples
    dim as integer ptr offsetS, offsetD, offsetAcc
    
    rh = r*2 + 1
    
    xs = bx
    ys = by
    xe = xs + BLOCK_SIZE - 1
    ye = ys + BLOCK_SIZE - 1
    
    offsetS = src + (by - r)*planeWidth + bx
    offsetD = dest + by*planeWidth + bx    
    stride = planeWidth*BLOCK_SIZE - 1
    hi_stride = planeWidth*rh
    for col = xs to xe
        accStart = ys - r
        accEnd = ys + r
        acc = 0.0
        samples = 0.0
        offsetAcc = offsetS
        for row = accStart to accEnd
            if row >= 0 then
                acc += *offsetAcc
                samples += 1
            end if
            offsetAcc += planeWidth
        next row
        for row = ys to ye
            *offsetD = int(acc * (rh / samples))
            if (row - r) >= 0 then 
                acc -= *offsetS
                samples -= 1
            end if
            if (row + r) < planeHeight then 
                acc += *(offsetS + hi_stride)
                samples += 1
            end if
            offsetS += planeWidth
            offsetD += planeWidth
        next row
        offsetS -= stride
        offsetD -= stride
    next col      
    
end sub

sub ElectricArc.compSquareR1(pxldata as integer ptr)
    dim as integer i, bx, by
    dim as integer stride, stride_res, sx, sy
    dim as integer ptr offsetS, offsetD, offsetG
    dim as integer ptr colormap
        
    stride_res = (BLOCK_SIZE*planeWidth - 1) shl 2
    colormap = @(toneMap(0))
    
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then  
            stride = (planeWidth - BLOCK_SIZE) shl 2
            offsetS = arcSpineData + by*planeWidth + bx
            offsetD = arcSmoothData + by*planeWidth + bx
            asm
                    mov     esi,            [offsetS]
                    mov     edi,            [offsetD]
                    mov     ecx,            BLOCK_SIZE
                    
                electricarc_blurR1_00_H_row:
                
                    mov     edx,            BLOCK_SIZE
                    
                electricarc_blurR1_00_H_col:
               
                    mov     eax,            [esi-4]
                    mov     ebx,            [esi]
                    shl     ebx,            1
                    add     eax,            ebx
                    add     eax,            [esi+4]
                    
                    mov     [edi],          eax
                    
                    add     esi,            4
                    add     edi,            4
                    
                    dec     edx
                    jnz     electricarc_blurR1_00_H_col
                    
                    add     esi,            [stride]
                    add     edi,            [stride]
                    dec     ecx
                    jnz     electricarc_blurR1_00_H_row
                    
            end asm             
        else
            compSquareR1_XH(bx, by)        
        end if
    next i
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[i*3 + 0]
        by = activeBlockList[i*3 + 1]
        if activeBlockList[i*3 + 2] then  
            stride = planeWidth shl 2
            offsetS = arcSmoothData + by*planeWidth + bx
            offsetD = pxldata + by*planeWidth + bx
            offsetG = arcGlowData + by*planeWidth + bx    
            asm
                    mov         esi,            [offsetS]
                    mov         edi,            [offsetD]
                    mov         ecx,            [offsetG]
                    mov         dword ptr[sy],  BLOCK_SIZE
                    
                electricarc_blurR1_00_V_col:
                
                    mov         dword ptr[sx],  BLOCK_SIZE
                    
                electricarc_blurR1_00_V_row:
               
                    
                    mov         ebx,            esi
                    sub         ebx,            [stride]
                    mov         eax,            [ebx]
                    mov         ebx,            [esi]
                    shl         ebx,            1
                    add         eax,            ebx
                    mov         ebx,            esi
                    add         ebx,            [stride]
                    add         eax,            [ebx]
                    shl         eax,            4
                        
                    cmp         eax,            256
                    jl          electricarc_blurR1_00_V_skipsub1
                    sub         eax,            1
                    electricarc_blurR1_00_V_skipsub1:
                    
                    mov         edx,            [colormap]
                    mov         eax,            [edx+eax*4]
                    movd        xmm0,           eax
                    
                    mov         eax,            [ecx]
                    mov         ebx,            1803
                    mul         ebx
                    shr         eax,            23
                    movd        xmm1,           eax
                    
                    punpcklbw   xmm1,           xmm1
                    punpcklbw   xmm1,           xmm1
                    
                    paddusb     xmm0,           xmm1
                    
                    movd        xmm2,           [edi]
                    paddusb     xmm0,           xmm2
                    movd        [edi],          xmm0
                    
                    add         esi,            [stride]
                    add         edi,            [stride]
                    add         ecx,            [stride]         
        
                    dec         dword ptr[sx]
                    jnz         electricarc_blurR1_00_V_row
                    
                    sub         esi,            [stride_res]
                    sub         edi,            [stride_res]
                    sub         ecx,            [stride_res]
                    dec         dword ptr[sy]
                    jnz         electricarc_blurR1_00_V_col
            end asm

        else
            compSquareR1_XV(pxldata, bx, by)        
        end if
    next i
end sub

sub ElectricArc.compSquareR1_XH(bx as integer, by as integer)
    dim as integer row, col
    dim as integer xs, xe
    dim as integer cxs, cxe
    dim as integer ys, ye
    dim as integer stride
    dim as integer ptr offsetS, offsetD
        
    xs = bx
    ys = by
    xe = xs + BLOCK_SIZE - 1
    ye = ys + BLOCK_SIZE - 1
    
    if xs = 0 then 
        cxs = xs + 1
    else
        cxs = xs
    end if
    
    if xe = planeWidth-1 then 
        cxe = xe - 1
    else
        cxe = xe
    end if
    
    offsetS = arcSpineData + by*planeWidth + bx
    offsetD = arcSmoothData + by*planeWidth + bx    
    stride = planeWidth - BLOCK_SIZE
    for row = ys to ye
        
        if cxs <> xs then
            *offsetD = ((offsetS[0] shl 1) + offsetS[1])*1.333
            offsetS += 1
            offsetD += 1
        end if
        
        for col = cxs to cxe
            *offsetD = offsetS[-1] + (offsetS[0] shl 1) + offsetS[1]
            offsetS += 1
            offsetD += 1
        next col
        
        if cxe <> xe then
            *offsetD = (offsetS[-1] + (offsetS[0] shl 1))*1.333
            offsetS += 1
            offsetD += 1            
        end if
        
        offsetS += stride
        offsetD += stride
    next row    
end sub
sub ElectricArc.compSquareR1_XV(pxldata as integer ptr, bx as integer, by as integer) 
    #macro DRAWPIXEL()
        accVal shl= 4
        if accVal = 256 then accVal = 255
        accVal = toneMap(accVal)
        glowVal = ((*offsetG) * 1803) shr 23
        asm
            movd        xmm0,           [glowVal]
            punpcklbw   xmm0,           xmm0
            punpcklbw   xmm0,           xmm0 
            movd        xmm1,           [accVal]
            paddusb     xmm0,           xmm1
            mov         eax,            [offsetD]
            movd        xmm1,           [eax]
            paddusb     xmm0,           xmm1
            movd        [eax],          xmm0
        end asm    
    #endmacro
    
    dim as integer row, col
    dim as integer xs, xe, accVal
    dim as integer cys, cye, glowVal
    dim as integer ys, ye
    dim as integer stride, stride_res
    dim as integer ptr offsetS, offsetD, offsetG
        
    xs = bx
    ys = by
    xe = xs + BLOCK_SIZE - 1
    ye = ys + BLOCK_SIZE - 1
    
    if ys = 0 then 
        cys = ys + 1
    else
        cys = ys
    end if
    
    if ye = planeHeight-1 then 
        cye = ye - 1
    else
        cye = ye
    end if
    
    offsetS = arcSmoothData + by*planeWidth + bx
    offsetD = pxldata + by*planeWidth + bx    
    offsetG = arcGlowData + by*planeWidth + bx
    stride = planeWidth
    stride_res = (planeWidth * BLOCK_SIZE) - 1
    
    for col = xs to xe
        
        if cys <> ys then
            accVal = ((offsetS[0] shl 1) + offsetS[stride])*1.333
            DRAWPIXEL()

            offsetS += stride
            offsetD += stride
            offsetG += stride
        end if
        
        for row = cys to cye
            accVal = (offsetS[-stride] + (offsetS[0] shl 1) + offsetS[stride])
            DRAWPIXEL()            
            
            offsetS += stride
            offsetD += stride
            offsetG += stride
        next row
        
        if cye <> ye then
            accVal = (offsetS[-stride] + (offsetS[stride] shl 1))*1.333
            DRAWPIXEL()   
            
            offsetS += stride
            offsetD += stride 
            offsetG += stride
        end if
        
        offsetS -= stride_res
        offsetD -= stride_res
        offsetG -= stride_res
    next col  
end sub

sub ElectricArc.init(planeW as integer, planeH as integer)
    dim as integer i
    clean()
    blockW = int(planeW / BLOCK_SIZE)
    blockH = int(planeH / BLOCK_SIZE)
    planeWidth = blockW * BLOCK_SIZE
    planeHeight = blockH * BLOCK_SIZE
    
    allocateAlligned(arcSpineData_alloc, arcSpineData, sizeof(integer)*planeWidth*planeHeight)
    allocateAlligned(arcGlowData_alloc, arcGlowData, sizeof(integer)*planeWidth*planeHeight)
    allocateAlligned(arcSmoothData_alloc, arcSmoothData, sizeof(integer)*planeWidth*planeHeight)
    
    for i = 0 to planeWidth*planeHeight-1
        arcSpineData[i] = 0
        arcGlowData[i] = 0
    next i
    
    activeBlockFiles = callocate(blockW*blockH, sizeof(integer))
    
    activeBlockList = allocate(sizeof(integer)*3*blockW*blockH)
    activeBlockList_N = 0
    
    ArcHash.init(sizeof(ElectricArc_ArcData_t))
end sub

sub ElectricArc.flush()
    dim as ElectricArc_ArcData_t ptr curArc

    BEGIN_HASH(curArc, ArcHash)
        deallocate(curArc->splits)
        deallocate(curArc->drifts)
    END_HASH()
    
    ArcHash.flush()
end sub

sub ElectricArc.wipeMemory()
    dim as integer i
    dim as integer byteoffset   
    dim as integer stride 
    dim as integer bx, by
    dim as integer ptr dest1, dest2, dest3
    
    
    dest1 = arcSpineData
    dest2 = arcGlowData
    dest3 = arcSmoothData

    stride = planeWidth shl 2
    for i = 0 to activeBlockList_N-1
        bx = activeBlockList[3*i + 0]
        by = activeBlockList[3*i + 1]
        byteoffset = (by*planeWidth + bx) shl 2
        asm
                mov     eax,        [stride]
                mov     esi,        [dest1]
                mov     edi,        [dest2]
                mov     edx,        [dest3]
                add     esi,        [byteoffset]
                add     edi,        [byteoffset]
                add     edx,        [byteoffset]
                pxor    xmm0,       xmm0
                
                mov     ebx,        BLOCK_SIZE
            
            electricarc_wipememory_planeloop:
            
                movdqa  [esi],      xmm0
                movdqa  [edi],      xmm0
                movdqa  [edx],      xmm0
                movdqa  16[esi],    xmm0
                movdqa  16[edi],    xmm0
                movdqa  16[edx],    xmm0
                movdqa  32[esi],    xmm0
                movdqa  32[edi],    xmm0
                movdqa  32[edx],    xmm0
                movdqa  48[esi],    xmm0
                movdqa  48[edi],    xmm0 
                movdqa  48[edx],    xmm0

                add     esi,        eax
                add     edi,        eax
                add     edx,        eax
                dec     ebx
                jnz     electricarc_wipememory_planeloop
        end asm
        activeBlockFiles[(by shr BLOCK_SIZE_SHIFT)*blockW + (bx shr BLOCK_SIZE_SHIFT)] = 0
    next i
    activeBlockList_N = 0

end sub

function ElectricArc.create() as integer
    dim as ElectricArc_ArcData_t newArc
    generate += 1
    
    newArc.a = Vector2D(0,0)
    newArc.b = Vector2D(0,0)
    newArc.period_min = 0
    newArc.period_max = 40
    newArc.p = 0
    newArc.splits = allocate(sizeof(Vector2D) * MAX_SPLITS)
    newArc.drifts = allocate(sizeof(Vector2D) * MAX_SPLITS)
    
    ArcHash.insert(generate, @newArc)
    
    return generate
end function

sub ElectricArc.setPoints(id as integer, a as Vector2D, b as Vector2D)
    dim as ElectricArc_ArcData_t ptr curArc
    dim as integer lvl, cnt, curSplits, i, isDifferent
    dim as double persist

    isDifferent = 0
    curArc = ArcHash.retrieve(id)
    if curArc then
        if (curArc->a <> a) orElse (curArc->b <> b) then isDifferent = 1
        curArc->a = a
        curArc->b = b
 
        if isDifferent then curArc->p *= 0.75
    end if
end sub
sub ElectricArc.getPoints(id as integer, byref a as Vector2D, byref b as Vector2D)
    dim as ElectricArc_ArcData_t ptr curArc
    curArc = ArcHash.retrieve(id)
    if curArc then
        a = curArc->a
        b = curArc->b
    end if    
end sub
sub ElectricArc.setSnapPeriod(id as integer, period_min as integer, period_max as integer)
    dim as ElectricArc_ArcData_t ptr curArc
    curArc = ArcHash.retrieve(id)
    if curArc then
        curArc->period_min = period_min
        curArc->period_max = period_max
    end if   
end sub
sub ElectricArc.resetArc(id as integer)
    dim as ElectricArc_ArcData_t ptr curArc
    curArc = ArcHash.retrieve(id)
    if curArc then curArc->p = 0
end sub
function ElectricArc.isSnapFrame(id as integer) as integer
    dim as ElectricArc_ArcData_t ptr curArc
    curArc = ArcHash.retrieve(id)
    if curArc then
        if curArc->p = 0 then
            return 1
        end if
    end if
end function

sub ElectricArc.destroy(id as integer)
    dim as ElectricArc_ArcData_t ptr curArc
    curArc = ArcHash.retrieve(id)
    if curArc then
        deallocate(curArc->splits)
        deallocate(curArc->drifts)    
        ArcHash.remove(id)
    end if
end sub

sub ElectricArc.stepArcs(timestep as double)
    dim as ElectricArc_ArcData_t ptr curArc
    dim as integer lvl, cnt, curSplits, i
    dim as double persist
    
    BEGIN_HASH(curArc, ArcHash)
        if curArc->p <= 0 then
            lvl = 0
            cnt = 1 shl lvl
            persist = Sqr((curArc->a.xs - curArc->b.xs)^2 + (curArc->a.ys - curArc->b.ys)^2) * 0.5
            curSplits = (1 shl (int(log(persist*2) / log(2)) + 1)) - 1
            if curSplits > MAX_SPLITS then curSplits = MAX_SPLITS
            if curSplits < 127 then curSplits = 127
            for i = 0 to curSplits-1
                curArc->splits[i].xs = (rnd-0.5) * persist
                if i = 0 then
                    curArc->splits[i].ys = -rnd*0.5 * persist
                else
                    curArc->splits[i].ys = (rnd-0.5) * persist
                end if
                curArc->drifts[i].xs = (rnd-0.5) * sqr(persist) * 0.2
                curArc->drifts[i].ys = -persist / 90 + (rnd - 0.5) * 0.1
                
                cnt -= 1
                if cnt = 0 then
                    lvl += 1
                    cnt = 1 shl lvl
                    persist *= 0.55
                end if
            next i
            curArc->p = int(rnd * (curArc->period_max - curArc->period_min)) + curArc->period_min
            curArc->curSplit = curSplits
        else
            for i = 0 to curArc->curSplit-1
                curArc->splits[i].xs += curArc->drifts[i].xs
                curArc->splits[i].ys += curArc->drifts[i].ys
            next i
            curArc->p -= 1
        end if     
    END_HASH()
end sub

sub ElectricArc.drawArcs(scnbuff as integer ptr)
    dim as ElectricArc_ArcData_t ptr curArc
    dim as ElectricArc_Stack_t drawStack(0 to 10)
    dim as integer drawStack_ptr, blockaddr, bt, bx, by
    dim as integer curNode, xi, yi, xs, ys, xe, ye, i
    dim as integer ptr pxldata
    dim as Vector2D curA, curB
    dim as Vector2D m
    
    imageinfo scnbuff,,,,,pxldata

    BEGIN_HASH(curArc, ArcHash)
        drawStack_ptr = 0
        curNode = 0
        curA = pmapFixV(curArc->a)
        curB = pmapFixV(curArc->b)
        
        do
            while curNode < ((curArc->curSplit + 1) * 0.5) - 1
                m = (curA + curB)*0.5 + curArc->splits[curNode]
                drawStack(drawStack_ptr).a = curA
                drawStack(drawStack_ptr).b = curB
                drawStack(drawStack_ptr).node = curNode
                drawStack(drawStack_ptr).m = m
                drawStack_ptr += 1
                
                if (curNode >= 31) andALso (curNode < 63) then
                    xs = int(curA.xs) shr BLOCK_SIZE_SHIFT
                    ys = int(curA.ys) shr BLOCK_SIZE_SHIFT
                    xe = int(curB.xs) shr BLOCK_SIZE_SHIFT
                    ye = int(curB.ys) shr BLOCK_SIZE_SHIFT
                    if xe < xs then swap xs, xe
                    if ye < ys then swap ys, ye
                    xs -= 1
                    ys -= 1
                    xe += 1
                    ye += 1
                    for yi = ys to ye
                        for xi = xs to xe
                            if (xi >= 0) andAlso (xi < blockW) andALso _
                               (yi >= 0) andAlso (yi < blockH) then
                                blockaddr = yi*blockW + xi
                                if activeBlockFiles[blockaddr] = 0 then
                                    activeBlockList[activeBlockList_N*3 + 0] = xi shl BLOCK_SIZE_SHIFT
                                    activeBlockList[activeBlockList_N*3 + 1] = yi shl BLOCK_SIZE_SHIFT
                                    
                                    if xi = 0 then
                                        activeBlockList[activeBlockList_N*3 + 2] = 0
                                    elseif xi = (blockW-1) then
                                        activeBlockList[activeBlockList_N*3 + 2] = 0
                                    elseif yi = 0 then
                                        activeBlockList[activeBlockList_N*3 + 2] = 0
                                    elseif yi = (blockH-1) then
                                        activeBlockList[activeBlockList_N*3 + 2] = 0
                                    else
                                        activeBlockList[activeBlockList_N*3 + 2] = 1
                                    end if
                                    
                                    activeBlockList_N += 1
                                    activeBlockFiles[blockaddr] = 1
                                end if
                            end if
                        next xi
                    next yi
                end if
                
                curB = m
                curNode = 2*curNode + 1
            wend 
                
            m = (curA + curB)*0.5 + curArc->splits[curNode]

            if (2*curNode + 1) >= curArc->curSplit then
                m.xs += (rnd - 0.5) * 2
                m.ys += (rnd - 0.5) * 2
                drawArcLine(curA.xs, curA.ys, m.xs, m.ys)
                drawArcLine(m.xs, m.ys, curB.xs, curB.ys)
            end if
            
            if curNode = (curArc->curSplit - 1) then exit do
            
            drawStack_ptr -= 1
            curA = drawStack(drawStack_ptr).a
            curB = drawStack(drawStack_ptr).b
            curNode = drawStack(drawStack_ptr).node
            m = drawStack(drawStack_ptr).m
            
            curA = m
            curNode = 2*(curNode+1)
        loop 
    END_HASH()
    
    accSquareR5()
    compSquareR1(pxldata)
    
    
    wipeMemory()

end sub

        