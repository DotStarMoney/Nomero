#include "fbgfx.bi"

#define DEMO
using fb

#define SCRX 8192
#define SCRY 6144

dim shared as integer ACCESSES = 0

Sub triangle_Scan(dest as integer ptr = 0,_
                  x1 as double, y1 as double,_
                  x2 as double, y2 as double,_
                  x3 as double, y3 as double,_
                  tc as integer)

    dim as integer LO,LI
    dim as double PX(1 to 3)
    dim as double PY(1 to 3)
    dim as integer TFLAG
    dim as uinteger ptr pp
    dim as integer IL1,IL2,SLICE
    dim as double XP1,XP2
    dim as double XI1,XI2
    dim as double TEMPX,TEMPY
    dim as uinteger ptr BUFFER
    dim as integer XRES, YRES
    
    /'
    if dest = 0 then
        screeninfo xres, yres
        buffer = screenptr
    else
        imageinfo dest, xres, yres,,,buffer
    end if
    '/
    XRES = SCRX
    YRES = SCRY
    buffer = dest
    
    TFLAG=0
    PX(1)= X1
    PX(2)= X2
    PX(3)= X3
       
    PY(1)= Y1
    PY(2)= Y2
    PY(3)= Y3
    
    FOR LO = 1 TO 2
        FOR LI =1 TO 2    
            IF PY(LI+1) <= PY(LI) THEN
            TEMPX = PX(LI) : TEMPY = PY(LI)
            PX(LI) = PX(LI+1)
            PY(LI) = PY(LI+1)
            PX(LI+1) = TEMPX
            PY(LI+1) = TEMPY
            END IF  
        NEXT LI
    NEXT LO


    IF PY(1)<PY(2) AND PY(2)<PY(3) or (PY(2) = PY(3)) THEN
        TFLAG=1
        XP1 = PX(1)
        XP2 = PX(1)
        XI1 = (PX(1)-PX(2)) / (PY(2) - PY(1))
        XI2 = (PX(1)-PX(3)) / (PY(3) - PY(1))

        FOR LO = PY(1) TO PY(2)-1
            IF LO>=0 AND LO<YRES THEN
            
                IF XP1<=XP2 THEN
                    IL1=XP1
                    IL2=XP2
                ELSE
                    IL1=XP2
                    IL2=XP1
                END IF
               
                IF IL2>XRES THEN IL2=XRES
                IF IL1<0 THEN IL1=0
            
                SLICE = IL2-IL1
                IF SLICE>0 THEN
                    ACCESSES += 1
                    PP = @BUFFER[IL1+(LO*XRES)]  
                    /'
                    asm
                        mov eax,dword ptr[TC]
                        mov ecx, [slice]
                        mov edi, [PP]
                        rep stosd
                    end asm  
                    '/
                END IF
            
            END IF
            
            XP1=XP1-XI1
            XP2=XP2-XI2
        NEXT LO

        XI1 = (PX(2)-PX(3)) / (PY(3) - PY(2))
        XP1 = PX(2)

        FOR LO = PY(2) TO PY(3)
            IF LO>=0 AND LO<YRES THEN
                IF XP1<=XP2 THEN
                    IL1=XP1
                    IL2=XP2
                ELSE
                    IL1=XP2
                    IL2=XP1
                END IF

                IF IL2>XRES THEN IL2=XRES
                IF IL1<0 THEN IL1=0

                SLICE = IL2-IL1
                IF SLICE>0 THEN
                    PP = @BUFFER[IL1+(LO*XRES)]  
                    ACCESSES += 1
                    /'
                    asm
                        mov eax,dword ptr[TC]
                        mov ecx, [slice]
                        mov edi, [PP]
                        rep stosd
                    end asm  
                    '/
                END IF
            END IF
            XP1=XP1-XI1
            XP2=XP2-XI2
        NEXT LO

    END IF
    
    IF TFLAG=0 AND PY(1) = PY(2) THEN

        TFLAG=1
        XP1 = PX(1)
        XP2 = PX(2)
        XI1 = (PX(1)-PX(3)) / (PY(3) - PY(1))
        XI2 = (PX(2)-PX(3)) / (PY(3) - PY(2))
        FOR LO = PY(1) TO PY(3)
            IF LO>=0 AND LO<YRES THEN
                IF XP1<=XP2 THEN
                    IL1=XP1
                    IL2=XP2
                ELSE
                    IL1=XP2
                    IL2=XP1
                END IF
               
                IF IL2>XRES THEN IL2=XRES
                IF IL1<0 THEN IL1=0
               
                SLICE = IL2-IL1
                IF SLICE>0 THEN
                    PP = @BUFFER[IL1+(LO*XRES)]  
                    ACCESSES += 1
                    /'
                    asm
                        mov eax,dword ptr[TC]
                        mov ecx, [slice]
                        mov edi, [PP]
                        rep stosd
                    end asm  
                    '/
                END IF
            END IF
            XP1=XP1-XI1
            XP2=XP2-XI2
        NEXT LO
    END IF
END SUB

sub triangle_AHS(dest as integer ptr = 0,_
                 x0 as double, y0 as double,_
                 x1 as double, y1 as double,_
                 x2 as double, y2 as double,_
                 col as integer)
                    
    #define ALLIGNMENT 16
    #define PACKED_DATA_SIZE 108
    #define FIX_BITS 4
    #define FIX_BITS_VALUE (1 shl FIX_BITS)
    #define MIN_BLOCK_X 8
    #define MIN_BLOCK_y 8
    
    #define MAX_BLOCK_X 1024
    #define MAX_BLOCK_Y 1024
    #define START_MASK &b111111
    #define GET_SIZE_X(x) 1 shl (((x) and &b000111) + 3)
    #define GET_SIZE_Y(x) 1 shl (((x) shr 3) + 3)
    #define splitX(x) iif(((x) and &b000111) = 0, -1, ((x) and &b111000) or (((x) and &b000111) - 1))
    #define splitY(x) iif(((x) and &b111000) = 0, -1, ((x) and &b000111) or (((((x) shr 3) - 1)) shl 3))
    
    #define _0_   0
    #define _1_   4
    #define _2_   8
    
    #define _hconst0_ 0
    #define _hconst1_ 16
    #define _hconst2_ 32
    #define _dx0_ 48
    #define _dx1_ 64
    #define _dx2_ 80
    #define _dy0_ 96
    #define _dy1_ 112
    #define _dy2_ 128
    #define _cxy_ 144
    #define _pblockCY_ 160
    #define _pblockDX_ 176
    #define _pblockDY_ 192
    #define _cyx_ 208
    #define _pblockQFD0_ 224
    #define _pblockQFD1_ 240
    #define _pblockQFD2_ 256
    #define _pblockQSD0_ 272
    #define _pblockQSD1_ 288
    #define _pblockQSD2_ 304
    #define _pblockQSB0_ 320
    #define _pblockQSB1_ 336
    #define _pblockQSB2_ 352
    #define _pblockQAB0_ 368
    #define _pblockQAB1_ 384
    #define _pblockQAB2_ 400
    #define _bcol_ 416
    
    

    #macro EXPAND(x, y)
        x[y + 1] = x[y]
        x[y + 2] = x[y]
        x[y + 3] = x[y]
    #endmacro
    
    #define STACK_SIZE 64
    
    #macro PUSH_BLOCK()
        stackPtr += 1
        stack(stackPtr, 0) = scx
        stack(stackPtr, 1) = scy
        stack(stackPtr, 2) = splitMask
    #endmacro
    
    #macro POP_BLOCK()
        scx = stack(stackPtr, 0)
        scy = stack(stackPtr, 1)
        splitMask = stack(stackPtr, 2)
        stackPtr -= 1
    #endmacro
    
    #macro SPLIT_BLOCK_H()
        splitMask = splitY(splitMask)
        PUSH_BLOCK()
        scy += curBlockH shr 1
        PUSH_BLOCK()
    #endmacro
    
    #macro SPLIT_BLOCK_V()
        splitMask = splitX(splitMask)
        PUSH_BLOCK()
        scx += curBlockW shr 1
        PUSH_BLOCK()
    #endmacro
    
    #macro FAST_STEP_INIT()
        asm
            mov     eax,        [startLoc]
            mov     ebx,        [alligned_base]
            mov     ecx,        [stride]
            movdqa  xmm0,       _bcol_[ebx]   
        end asm
    #endmacro
    
    #macro FAST_STEP_64_LINE()
        asm
            movdqa  [eax],      xmm0
            movdqa  16[eax],    xmm0
            movdqa  32[eax],    xmm0
            movdqa  48[eax],    xmm0
            movdqa  64[eax],    xmm0
            movdqa  80[eax],    xmm0
            movdqa  96[eax],    xmm0
            movdqa  112[eax],   xmm0
            movdqa  128[eax],   xmm0
            movdqa  144[eax],   xmm0
            movdqa  160[eax],   xmm0
            movdqa  176[eax],   xmm0
            movdqa  192[eax],   xmm0
            movdqa  208[eax],   xmm0
            movdqa  224[eax],   xmm0
            movdqa  240[eax],   xmm0            
            add     eax,        ecx
        end asm
    #endmacro
    #macro FAST_STEP_32_LINE()
        asm
            movdqa  [eax],      xmm0
            movdqa  16[eax],    xmm0
            movdqa  32[eax],    xmm0
            movdqa  48[eax],    xmm0
            movdqa  64[eax],    xmm0
            movdqa  80[eax],    xmm0
            movdqa  96[eax],    xmm0
            movdqa  112[eax],   xmm0
            add     eax,        ecx
        end asm
    #endmacro
    #macro FAST_STEP_16_LINE()
        asm
            movdqa  [eax],      xmm0
            movdqa  16[eax],    xmm0
            movdqa  32[eax],    xmm0
            movdqa  48[eax],    xmm0
            add     eax,        ecx
        end asm
    #endmacro
    #macro FAST_STEP_8_LINE()
        asm
            movdqa  [eax],      xmm0
            movdqa  16[eax],    xmm0
            add     eax,        ecx
        end asm
    #endmacro
    #macro FAST_STEP_64()
        FAST_STEP_64_LINE()
        FAST_STEP_64_LINE()
        FAST_STEP_64_LINE()
        FAST_STEP_64_LINE()
        FAST_STEP_64_LINE()
        FAST_STEP_64_LINE()
        FAST_STEP_64_LINE()
        FAST_STEP_64_LINE()
    #endmacro
    #macro FAST_STEP_32()
        FAST_STEP_32_LINE()
        FAST_STEP_32_LINE()
        FAST_STEP_32_LINE()
        FAST_STEP_32_LINE()
        FAST_STEP_32_LINE()
        FAST_STEP_32_LINE()
        FAST_STEP_32_LINE()
        FAST_STEP_32_LINE()
    #endmacro
    #macro FAST_STEP_16()
        FAST_STEP_16_LINE()
        FAST_STEP_16_LINE()
        FAST_STEP_16_LINE()
        FAST_STEP_16_LINE()
        FAST_STEP_16_LINE()
        FAST_STEP_16_LINE()
        FAST_STEP_16_LINE()
        FAST_STEP_16_LINE()
    #endmacro
    #macro FAST_STEP_8()
        FAST_STEP_8_LINE()
        FAST_STEP_8_LINE()
        FAST_STEP_8_LINE()
        FAST_STEP_8_LINE()
        FAST_STEP_8_LINE()
        FAST_STEP_8_LINE()
        FAST_STEP_8_LINE()
        FAST_STEP_8_LINE()
    #endmacro
    
    dim as integer px0, py0
    dim as integer dst_w, dst_h
    dim as integer sdst_w, sdst_h
    dim as integer px1, py1
    dim as integer px2, py2
    dim as integer tl_x, tl_y
    dim as integer otl_x, otl_y
    dim as integer br_x, br_y
    dim as integer sotl_x, sotl_y
    dim as integer sbr_x, sbr_y
    dim as integer x, y
    dim as integer scx, scy
    dim as integer stackPtr
    dim as integer fdx(0 to 2)
    dim as integer fdy(0 to 2)
    dim as integer stack(0 to STACK_SIZE-1, 0 to 2)
    dim as integer slowStride
    dim as integer stride
    dim as integer curBlockW, curBlockH
    dim as integer splitMask
    dim as integer crnr(0 to 2)
    dim as integer crnrMask

    dim as integer ptr dstPxls
    dim as integer ptr startLoc
    
    dim as integer ptr hconst     
    dim as integer ptr dx         
    dim as integer ptr dy         
    dim as integer ptr cxy     
    dim as integer ptr cyx
    
    dim as integer ptr pblockCY   
    dim as integer ptr pblockDX   
    dim as integer ptr pblockDY   
    dim as integer ptr pblockQFD
    dim as integer ptr pblockQSD
    dim as integer ptr pblockQAB
    dim as integer ptr pblockQSB

    dim as integer ptr bcol
    
    dim as integer ptr alligned_
    dim as integer ptr alligned_base
    
    /'
    if dest <> 0 then
        imageinfo dest, dst_w, dst_h, , ,dstPxls
    else
        screeninfo dst_w, dst_h
        dstPxls = screenptr
    end if
    '/
    dst_w = SCRX
    dst_h = SCRY
    dstPxls = dest
    
    sdst_w = dst_w shl FIX_BITS
    sdst_h = dst_h shl FIX_BITS

    px0 = cint(x0 * FIX_BITS_VALUE)
    py0 = cint(y0 * FIX_BITS_VALUE)
    px1 = cint(x1 * FIX_BITS_VALUE)
    py1 = cint(y1 * FIX_BITS_VALUE)
    px2 = cint(x2 * FIX_BITS_VALUE)
    py2 = cint(y2 * FIX_BITS_VALUE)

    alligned_ = allocate((sizeof(integer) * PACKED_DATA_SIZE) + (sizeof(byte) * (ALLIGNMENT - 1)))
    alligned_base = cast(integer ptr, (cast(integer, alligned_) + ALLIGNMENT) _
                    and (not (ALLIGNMENT - 1)))
   
    hconst     = @alligned_base[0]
    dx         = @alligned_base[12]
    dy         = @alligned_base[24]
    cxy        = @alligned_base[36]
    pblockCY   = @alligned_base[40]
    pblockDX   = @alligned_base[44]
    pblockDY   = @alligned_base[48]
    cyx        = @alligned_base[52]
    pblockQFD  = @alligned_base[56]
    pblockQSD  = @alligned_base[68]
    pblockQSB  = @alligned_base[80]
    pblockQAB  = @alligned_base[92]
    bcol       = @alligned_base[104]
    
    bcol[_0_] = col
    EXPAND(bcol, _0_)

    dx[_0_] = px0 - px1
    dy[_0_] = py0 - py1

    dx[_1_] = px1 - px2
    dy[_1_] = py1 - py2

    if dx[_0_] * dy[_1_] < dx[_1_] * dy[_0_] then
        swap px0, px1
        swap py0, py1
        
        dx[_0_] = -dx[_0_]
        dy[_0_] = -dy[_0_]
        
        dx[_1_] = px1 - px2
        dy[_1_] = py1 - py2
    end if

    dx[_2_] = px2 - px0
    dy[_2_] = py2 - py0
    
    fdx(0) = dx[_0_] shl FIX_BITS
    fdy(0) = dy[_0_] shl FIX_BITS
    fdx(1) = dx[_1_] shl FIX_BITS
    fdy(1) = dy[_1_] shl FIX_BITS
    fdx(2) = dx[_2_] shl FIX_BITS
    fdy(2) = dy[_2_] shl FIX_BITS
    
    pblockQSD[_0_ + 0] = 0
    pblockQSD[_0_ + 1] = pblockQSD[_0_ + 0] + fdy(0)
    pblockQSD[_0_ + 2] = pblockQSD[_0_ + 1] + fdy(0)
    pblockQSD[_0_ + 3] = pblockQSD[_0_ + 2] + fdy(0)
    
    pblockQSD[_1_ + 0] = 0
    pblockQSD[_1_ + 1] = pblockQSD[_1_ + 0] + fdy(1)
    pblockQSD[_1_ + 2] = pblockQSD[_1_ + 1] + fdy(1)
    pblockQSD[_1_ + 3] = pblockQSD[_1_ + 2] + fdy(1)   

    pblockQSD[_2_ + 0] = 0
    pblockQSD[_2_ + 1] = pblockQSD[_2_ + 0] + fdy(2)
    pblockQSD[_2_ + 2] = pblockQSD[_2_ + 1] + fdy(2)
    pblockQSD[_2_ + 3] = pblockQSD[_2_ + 2] + fdy(2)
    
    pblockQSB[_0_] = fdy(0) shl 2
    pblockQSB[_1_] = fdy(1) shl 2
    pblockQSB[_2_] = fdy(2) shl 2
   
    EXPAND(pblockQSB, _0_)
    EXPAND(pblockQSB, _1_)
    EXPAND(pblockQSB, _2_)
    
    pblockQAB[_0_] = fdx(0)
    pblockQAB[_1_] = fdx(1)
    pblockQAB[_2_] = fdx(2)
   
    EXPAND(pblockQAB, _0_)
    EXPAND(pblockQAB, _1_)
    EXPAND(pblockQAB, _2_)    
    
    pblockDX[_0_ + 0] = dx[_0_]
    pblockDX[_0_ + 1] = dx[_1_]
    pblockDX[_0_ + 2] = dx[_2_]
    
    pblockDY[_0_ + 0] = dy[_0_]
    pblockDY[_0_ + 1] = dy[_1_]
    pblockDY[_0_ + 2] = dy[_2_]  
    
    if px0 < px1 then
        if px0 < px2 then
            tl_x = px0
            if px1 < px2 then
                br_x = px2
            else
                br_x = px1
            end if
        else
            tl_x = px2
            br_x = px1
        end if
    else
        if px0 > px2 then
            br_x = px0
            if px2 > px1 then
                tl_x = px1
            else
                tl_x = px2
            end if
        else
            br_x = px2
            tl_x = px1
        end if
    end if
        
    if py0 < py1 then
        if py0 < py2 then
            tl_y = py0
            if py1 < py2 then
                br_y = py2
            else
                br_y = py1
            end if
        else
            tl_y = py2
            br_y = py1
        end if
    else
        if py0 > py2 then
            br_y = py0
            if py2 > py1 then
                tl_y = py1
            else
                tl_y = py2
            end if
        else
            br_y = py2
            tl_y = py1
        end if
    end if   
    
    if (br_x < 0) orElse (br_y < 0) then exit sub
    if (tl_x >= sdst_w) orElse (tl_y >= sdst_h) then exit sub
    
    stackPtr = -1
    
    if tl_x < 0 then tl_x = 0
    if tl_y < 0 then tl_y = 0
    if br_x >= sdst_w then br_x = sdst_w
    if br_y >= sdst_h then br_y = sdst_h
    
    tl_x = (tl_x + (FIX_BITS_VALUE-1)) shr FIX_BITS
    tl_y = (tl_y + (FIX_BITS_VALUE-1)) shr FIX_BITS
    br_x = (br_x + (FIX_BITS_VALUE-1)) shr FIX_BITS
    br_y = (br_y + (FIX_BITS_VALUE-1)) shr FIX_BITS
    
    otl_x = tl_x
    otl_y = tl_y
    tl_x and= not(MAX_BLOCK_X - 1)
    tl_y and= not(MAX_BLOCK_Y - 1)
    
    sotl_x = otl_x shl FIX_BITS
    sotl_y = otl_y shl FIX_BITS
    sbr_x = br_x shl FIX_BITS
    sbr_y = br_y shl FIX_BITS
    
    hconst[_0_] = dy[_0_]*px0 - dx[_0_]*py0 + _
                  iif((dy[_0_] < 0) orElse ((dy[_0_] = 0) andAlso (dx[_0_] > 0)), 1, 0)
                  
    hconst[_1_] = dy[_1_]*px1 - dx[_1_]*py1 + _
                  iif((dy[_1_] < 0) orElse ((dy[_1_] = 0) andAlso (dx[_1_] > 0)), 1, 0)
                  
    hconst[_2_] = dy[_2_]*px2 - dx[_2_]*py2 + _
                  iif((dy[_2_] < 0) orElse ((dy[_2_] = 0) andAlso (dx[_2_] > 0)), 1, 0)    
        
    pblockCY[_0_ + 0] = hconst[_0_]
    pblockCY[_0_ + 1] = hconst[_1_]
    pblockCY[_0_ + 2] = hconst[_2_]
    
    slowStride = (dst_w - 4) shl 2
    
    EXPAND(hconst, _0_)
    EXPAND(hconst, _1_)
    EXPAND(hconst, _2_)
    
    EXPAND(dx, _0_)
    EXPAND(dx, _1_)
    EXPAND(dx, _2_)
    
    EXPAND(dy, _0_)
    EXPAND(dy, _1_)
    EXPAND(dy, _2_)
        
    crnr(0) = 0
    crnr(1) = 0
    crnr(2) = 0
    
    for y = tl_y to br_y step MAX_BLOCK_Y
        for x = tl_x to br_x step MAX_BLOCK_X
            
            splitMask = START_MASK
            scx = x
            scy = y
            PUSH_BLOCK()
            
            while(stackPtr > -1)
                POP_BLOCK()

                curBlockW = GET_SIZE_X(splitMask)
                curBlockH = GET_SIZE_Y(splitMask) 
     
                #ifdef DEMO
                    'line (scx, scy)-(scx + curBlockW-1, scy + curBlockH-1), &h7f7f7f, B
                #endif
                  
                cxy[_0_ + 0] = scx shl FIX_BITS
                cxy[_0_ + 1] = scy shl FIX_BITS
                cxy[_0_ + 2] = (scx + curBlockW - 1) shl FIX_BITS
                cxy[_0_ + 3] = (scy + curBlockH - 1) shl FIX_BITS

                if (cxy[_0_ + 0] < sbr_x) andAlso _ 
                   (cxy[_0_ + 2] >= sotl_x) andAlso _
                   (cxy[_0_ + 1] < sbr_y) andAlso _
                   (cxy[_0_ + 3] >= sotl_y) then

                    asm
                        mov         eax,        [alligned_base]
                        pxor        xmm4,       xmm4
                        
                        movdqa      xmm0,       _cxy_[eax]
                        movdqa      xmm1,       xmm0
                        pshufd      xmm6,       xmm0,               0xF5   
                        pshufd      xmm7,       xmm1,               0x88    
                        movdqa      xmm0,       xmm6
                        movdqa      xmm1,       xmm7

                        movdqa      xmm2,       _dx0_[eax]
                        movdqa      xmm3,       _dy0_[eax]
                        
                        pmulld      xmm0,       xmm2
                        pmulld      xmm1,       xmm3
                        psubd       xmm0,       xmm1
                        movdqa      xmm2,       _hconst0_[eax]
                        paddd       xmm0,       xmm2
                        
                        pcmpgtd     xmm0,       xmm4
                        packssdw    xmm0,       xmm0
                        packsswb    xmm0,       xmm0
                        movd        ebx,        xmm0
                        not         ebx
                        mov         0[crnr],    ebx
                        
                        movdqa      xmm0,       xmm6
                        movdqa      xmm1,       xmm7
                        
                        movdqa      xmm2,       _dx1_[eax]
                        movdqa      xmm3,       _dy1_[eax]
                        
                        pmulld      xmm0,       xmm2
                        pmulld      xmm1,       xmm3
                        psubd       xmm0,       xmm1
                        movdqa      xmm2,       _hconst1_[eax]
                        paddd       xmm0,       xmm2
                        
                        pcmpgtd     xmm0,       xmm4
                        packssdw    xmm0,       xmm0
                        packsswb    xmm0,       xmm0
                        movd        ebx,        xmm0
                        not         ebx
                        mov         4[crnr],    ebx
                        
                        movdqa      xmm0,       xmm6
                        movdqa      xmm1,       xmm7
                        
                        movdqa      xmm2,       _dx2_[eax]
                        movdqa      xmm3,       _dy2_[eax]
                        
                        pmulld      xmm0,       xmm2
                        pmulld      xmm1,       xmm3
                        psubd       xmm0,       xmm1
                        movdqa      xmm2,       _hconst2_[eax]
                        paddd       xmm0,       xmm2
                        
                        pcmpgtd     xmm0,       xmm4
                        packssdw    xmm0,       xmm0
                        packsswb    xmm0,       xmm0
                        movd        ebx,        xmm0
                        not         ebx
                        mov         8[crnr],    ebx

                    end asm
                    
                    if (crnr(0) <> 0) andAlso (crnr(1) <> 0) andAlso (crnr(2) <> 0) then
                        if (crnr(0) = &hFFFFFFFF) andAlso (crnr(1) = &hFFFFFFFF) andAlso (crnr(2) = &hFFFFFFFF) then
                            startLoc = @dstPxls[(scy * dst_w) + scx]
                            stride = dst_w shl 2
                            #ifndef DEMO
                                select case as const splitMask
                                case 0
                                    FAST_STEP_INIT()
                                    FAST_STEP_8()
                                case 1
                                    FAST_STEP_INIT()
                                    FAST_STEP_16()
                                case 2
                                    FAST_STEP_INIT()
                                    FAST_STEP_32()
                                case 3
                                    FAST_STEP_INIT()
                                    FAST_STEP_64()
                                case 4
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        2
                                        dtAHS_block4_loop:
                                    end asm
                                    FAST_STEP_8()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block4_loop
                                    end asm
                                case 5
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        2
                                        dtAHS_block5_loop:
                                    end asm
                                    FAST_STEP_16()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block5_loop
                                    end asm
                                case 6
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        2
                                        dtAHS_block6_loop:
                                    end asm
                                    FAST_STEP_32()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block6_loop
                                    end asm
                                case 7
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        2
                                        dtAHS_block7_loop:
                                    end asm
                                    FAST_STEP_64()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block7_loop
                                    end asm 
                                case 8
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        4
                                        dtAHS_block8_loop:
                                    end asm
                                    FAST_STEP_8()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block8_loop
                                    end asm 
                                case 9
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        4
                                        dtAHS_block9_loop:
                                    end asm
                                    FAST_STEP_16()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block9_loop
                                    end asm 
                                case 10
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        4
                                        dtAHS_block10_loop:
                                    end asm
                                    FAST_STEP_32()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block10_loop
                                    end asm 
                                case 11
                                    FAST_STEP_INIT()
                                    asm
                                            mov     edx,        4
                                        dtAHS_block11_loop:
                                    end asm
                                    FAST_STEP_64()
                                    asm
                                            dec     edx
                                            jnz     dtAHS_block11_loop
                                    end asm 
                                end select
                            #else
                                'line (scx+1,scy+1)-(scx+curBlockW-2, scy+curBlockH-2), &h0000ff, BF
                                ACCESSES += 1
                            #endif
                        else
                            if splitX(splitMask) = -1 then
                                if splitY(splitMask) = -1 then
                                    cyx[_0_ + 0] =  cxy[_0_ + 1]
                                    EXPAND(cxy, _0_)
                                    EXPAND(cyx, _0_)
                                    #ifdef DEMO
                                        ACCESSES += 0'64                                    
                                    #endif
                                    /'
                                    asm
                                        
                                            mov         ecx,                [alligned_base]
                                            pxor        xmm7,               xmm7
                                            mov         ebx,                0xffffffff
                                            movd        xmm6,               ebx
                                            pshufd      xmm6,               xmm6,               0x00
                                            
                                            movdqa      xmm0,               _pblockDX_[ecx]
                                            movdqa      xmm1,               _cyx_[ecx]
                                            pmulld      xmm0,               xmm1
                                            
                                            movdqa      xmm2,               _pblockDY_[ecx]
                                            movdqa      xmm3,               _cxy_[ecx]
                                            pmulld      xmm2,               xmm3
                                            
                                            psubd       xmm0,               xmm2
                                            
                                            movdqa      xmm1,               _pblockCY_[ecx]
                                            paddd       xmm1,               xmm0
                                            
                                            pshufd      xmm3,               xmm1,               0x00
                                            psubd       xmm3,               _pblockQSD0_[ecx]            
                                            pshufd      xmm4,               xmm1,               0x55
                                            psubd       xmm4,               _pblockQSD1_[ecx]
                                            pshufd      xmm5,               xmm1,               0xAA
                                            psubd       xmm5,               _pblockQSD2_[ecx]
                                            movdqa      _pblockQFD0_[ecx],  xmm3
                                            movdqa      _pblockQFD1_[ecx],  xmm4
                                            movdqa      _pblockQFD2_[ecx],  xmm5
                                        
                                            mov         eax,                [dst_w]
                                            mov         ebx,                [scy]
                                            mul         ebx
                                            add         eax,                [scx]
                                            shl         eax,                2
                                            add         eax,                [dstPxls]
                                            mov         edx,                8
                                            
                                        dtAHS_slow_rows:
                                                                                        
                                            movdqa      xmm0,               xmm3
                                            movdqa      xmm1,               xmm4
                                            movdqa      xmm2,               xmm5
                                            pcmpgtd     xmm0,               xmm7
                                            pcmpgtd     xmm1,               xmm7
                                            pcmpgtd     xmm2,               xmm7
                                            por         xmm0,               xmm1
                                            por         xmm0,               xmm2
                                            movdqa      xmm1,               xmm0
                                            pxor        xmm1,               xmm6
                                            movdqa      xmm2,               [eax]
                                            pand        xmm0,               xmm2    
                                            pand        xmm1,               _bcol_[ecx]
                                            por         xmm0,               xmm1
                                            movdqa      [eax],              xmm0
                                            psubd       xmm3,               _pblockQSB0_[ecx]
                                            psubd       xmm4,               _pblockQSB1_[ecx]
                                            psubd       xmm5,               _pblockQSB2_[ecx]
                                            add         eax,                16
                                                                                        
                                            movdqa      xmm0,               xmm3
                                            movdqa      xmm1,               xmm4
                                            movdqa      xmm2,               xmm5
                                            pcmpgtd     xmm0,               xmm7
                                            pcmpgtd     xmm1,               xmm7
                                            pcmpgtd     xmm2,               xmm7
                                            por         xmm0,               xmm1
                                            por         xmm0,               xmm2
                                            movdqa      xmm1,               xmm0
                                            pxor        xmm1,               xmm6
                                            movdqa      xmm2,               [eax]
                                            pand        xmm0,               xmm2
                                            pand        xmm1,               _bcol_[ecx]
                                            por         xmm0,               xmm1
                                            movdqa      [eax],              xmm0
                                            add         eax,                [slowStride]
                                            
                                            movdqa      xmm0,               _pblockQFD0_[ecx]
                                            paddd       xmm0,               _pblockQAB0_[ecx]
                                            movdqa      xmm3,               xmm0
                                            movdqa      _pblockQFD0_[ecx],  xmm0
                                            
                                            movdqa      xmm0,               _pblockQFD1_[ecx]
                                            paddd       xmm0,               _pblockQAB1_[ecx]
                                            movdqa      xmm4,               xmm0
                                            movdqa      _pblockQFD1_[ecx],  xmm0
                                            
                                            movdqa      xmm0,               _pblockQFD2_[ecx]
                                            paddd       xmm0,               _pblockQAB2_[ecx]
                                            movdqa      xmm5,               xmm0
                                            movdqa      _pblockQFD2_[ecx],  xmm0
                                            
                                            dec         edx
                                            jnz         dtAHS_slow_rows
                                            
                                    end asm
                                    '/
                                else
                                    SPLIT_BLOCK_H()
                                end if
                            elseif splitY(splitMask) = -1 then
                                SPLIT_BLOCK_V()
                            else
                                crnrMask = crnr(0) and crnr(1) and crnr(2)
                                crnrMask = ((crnrMask shr 21) and &h08) or ((crnrMask shr 14) and &h04) or _
                                           ((crnrMask shr  7) and &h02) or (crnrMask and &h01)
                                if crnrMask = 3 orElse crnrMask = 12 then
                                    SPLIT_BLOCK_H()
                                elseif crnrMask = 5 orElse crnrMask = 10 then
                                    SPLIT_BLOCK_V()
                                else
                                    if curBlockW > curBlockH then
                                        SPLIT_BLOCK_V()
                                    else
                                        SPLIT_BLOCK_H()
                                    end if
                                end if
                            end if
                        end if
                    end if
                end if
            wend
        next x
    next y
    
    deallocate(alligned_)
end sub


type vect2
    as double x, y
end type

'screenres SCRX,SCRY,32,2
'screenset 1,0
randomize 13

dim as vect2 pts(0 to 2)
dim as integer i, cursel, dsel, button
dim as integer old_button, click
dim as integer mx, my, mode
dim as integer f, fps
dim as integer toggle, o_toggle
dim as double t
dim as double dist, bdist
dim as double dmag, x
dim as integer ptr image = allocate(SCRX*SCRY + 8)

pts(0).x = 0
pts(0).y = 0
pts(1).x = SCRX - 1
pts(1).y = 0
pts(2).x = 0
pts(2).y = SCRY - 1
mode = 0
x=0
t = timer
do 
    'cls
    /'
    getmouse mx, my,, button
    if (old_button <> button) and (button > 0) then click = 1
    old_button = button
    
    if click = 1 then 
        bdist = 1000000
        for i = 0 to 2
            dist = (pts(i).x - mx)^2 + (pts(i).y - my)^2
            if dist < bdist then
                cursel = i
                bdist = dist
            end if
        next i
    end if
    
    if button > 0 then
        pts(cursel).x = mx
        pts(cursel).y = my
    end if
    '/
    
    o_toggle = toggle 
    if multikey(SC_SPACE) then
        toggle = 1
    else
        toggle = 0
    end if
    if o_toggle = 0 andAlso toggle = 1 then mode = 1 - mode
    ACCESSES = 0
    if mode = 0 then
        triangle_Scan image,pts(0).x + x, pts(0).y, pts(1).x + x, pts(1).y, pts(2).x + x, pts(2).y, &he52b50
    else
        triangle_AHS image,pts(0).x + x, pts(0).y, pts(1).x + x, pts(1).y, pts(2).x + x, pts(2).y, &h6495ed
    end if


    
    f += 1
    if timer - t >= 1 then
        fps = f
        f = 0
        t = timer
        print "FPS: " & str(fps)
        print "Block Transfers: " & str(ACCESSES)

    end if
    /'
    click = 0
    '/
loop until multikey(1)
deallocate(image)

end 



