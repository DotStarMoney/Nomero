#include "utility.bi"
#include "constants.bi"
#include "debug.bi"

function min overload(x as double, y as double) as double
    if x < y then 
        return x
    else
        return y
    end if
end function

function min overload(x as integer, y as integer) as integer
    if x < y then 
        return x
    else
        return y
    end if
end function


function max overload(x as double, y as double) as double
    if x >= y then 
        return x
    else
        return y
    end if
end function

function max overload(x as integer, y as integer) as integer
    if x >= y then 
        return x
    else
        return y
    end if
end function

function wrap(v as double, v_w as double = 6.28318530718) as double
	if v >= v_w then 
		v -= int(v / v_w) * v_w
	elseif v < 0 then
		v += (1 + int(abs(v) / v_w)) * v_w
	end if
    return v
end function


Public Sub Split(Text As String, Delim As String, Count As Long, Ret() As String)

    Dim As Long x, p
    If Count < 1 Then
        Do
            x = InStr(x + 1, Text, Delim)
            p += 1
        Loop Until x = 0
        Count = p - 1
    ElseIf Count = 1 Then
        ReDim Ret(Count)
        Ret(0) = Text
    Else
        Count -= 1
    End If
    Dim RetVal(Count) As Long
    x = 0
    p = 0
    Do Until p = Count
        x = InStr(x + 1,Text,Delim)
        RetVal(p) = x
        p += 1
    Loop
    ReDim Ret(Count)
    Ret(0) = Left(Text, RetVal(0) - 1 )
    p = 1
    Do Until p = Count
        Ret(p) = Mid(Text, RetVal(p - 1) + 1, RetVal(p) - RetVal(p - 1) )
        p += 1
    Loop
    Ret(Count) = Mid(Text, RetVal(Count - 1) + 1)
    for x = 1 to ubound(Ret)-1
        Ret(x) = left(Ret(x), len(Ret(x))-1)
    next x
   
End Sub

function rndRange(a as double, b as double) as double
    if b < a then swap a, b
    return (rnd * (b - a)) + a
end function

sub parallaxAdjust(byref p_x as double, byref p_y as double,_
                  cam_x as double, cam_y as double,_
                  lvlWidth as integer, lvlHeight as integer,_
                  depth as double)
                    
    p_x += (cam_x - (lvlWidth * 0.5)) * (1-depth)
    p_y += (cam_y - (lvlHeight * 0.5)) * (1-depth)
end sub

sub stall(mili as integer)
    dim as double t
    t = timer + cdbl(mili) / 1000
    while timer <= t: wend
end sub

sub roundDbl(byref v as double, r as integer)
    v = int(v / cdbl(r)) * r
end sub


sub scale2sync(img as uinteger ptr)
    dim as uinteger ptr pxlData
    dim as uinteger ptr scnptr
    dim as integer w, h

    imageinfo img,w,h,,,pxlData
    scnptr = screenptr
    screenlock
        asm
                mov         esi,        [pxlData]
                mov         edi,        [scnptr]
                
                mov         eax,        [w]
                mov         ebx,        [h]
                
                mov         edx,        eax
                shl         edx,        2           
                shr         eax,        4           
                shl         ebx,        1           
                
            row_copy:

                mov         ecx,        eax         

            col_copy:
            
                prefetchnta 64[esi]
                prefetchnta 96[esi]
                
                movdqa      xmm0,       0[esi]
                movaps      xmm1,       xmm0
                shufps      xmm0,       xmm0,       &b01010000
                shufps      xmm1,       xmm1,       &b11111010
                
                movdqa      xmm2,       16[esi]
                movaps      xmm3,       xmm2
                shufps      xmm2,       xmm2,       &b01010000
                shufps      xmm3,       xmm3,       &b11111010
                
                movdqa      xmm4,       32[esi]
                movaps      xmm5,       xmm4
                shufps      xmm4,       xmm4,       &b01010000
                shufps      xmm5,       xmm5,       &b11111010
                
                movdqa      xmm6,       48[esi]
                movaps      xmm7,       xmm6
                shufps      xmm6,       xmm6,       &b01010000
                shufps      xmm7,       xmm7,       &b11111010
                
                
                movntdq     0[edi],     xmm0
                movntdq     16[edi],    xmm1
                movntdq     32[edi],    xmm2
                movntdq     48[edi],    xmm3
                movntdq     64[edi],    xmm4
                movntdq     80[edi],    xmm5
                movntdq     96[edi],    xmm6
                movntdq     112[edi],   xmm7
                
                add         esi,        64
                add         edi,        128
            
                dec         ecx
                jnz         col_copy
                
                test        ebx, 1
                jnz         no_reset_row
                
                sub         esi,        edx    
                
            no_reset_row:
            
                dec         ebx
                jnz         row_copy
        
        end asm
    screenunlock
end sub


sub bitblt_FalloutMix(dest as uinteger ptr,_
                      xpos as integer, ypos as integer,_
                      src  as uinteger ptr,_
                      src_x0 as integer, src_y0 as integer,_
                      src_x1 as integer, src_y1 as integer)
    dim as integer ptr dest_pxls, src_pxls
    dim as integer     dest_w, dest_h
    dim as integer     src_w, src_h
    dim as integer     target_w, target_h
    dim as integer     dest_row_adv, src_row_adv
    imageinfo dest,dest_w,dest_h,,,dest_pxls
    imageinfo src,src_w,src_h,,,src_pxls
      
    dest_pxls += xpos + ypos * dest_w
    src_pxls += src_x0 + src_y0 * src_w
    
    target_w = (src_x1 - src_x0 + 1)
    target_h = (src_y1 - src_y0 + 1)
    
    dest_row_adv = (dest_w - target_w) shl 2
    src_row_adv = (src_w - target_w) shl 2
    
    asm
        
                mov         esi,        [src_pxls]
                mov         edi,        [dest_pxls]
                
                mov         eax,        [target_w]
                mov         ebx,        [target_h]
                
                pxor        mm2,        mm2
                mov         edx,        &h00010001
                movd        mm3,        edx
                punpckldq   mm3,        mm3
                
            bitblt_fm_rows:
            
                mov         ecx,        eax
                
            bitblt_fm_cols:
            
                mov         edx,        [esi]
                cmp         edx,        &hff000000
                je          bitblt_fm_setTrans
                movd        mm0,        edx
                mov         edx,        [edi]
                cmp         edx,        &hffff00ff
                je          bitblt_fm_setTrans
                movd        mm1,        edx
                punpcklbw   mm0,        mm2
                punpcklbw   mm1,        mm2
                
                paddusw     mm0,        mm3
                pmullw      mm1,        mm0
                psrlw       mm1,        8
                packuswb    mm1,        mm2
                
                jmp         bitblt_fm_earlyOut
            bitblt_fm_setTrans:
                mov         edx,        &hffff00ff
                movd        mm1,        edx
            bitblt_fm_earlyOut:
           
                movd        [edi],      mm1
                
                add         esi,        4
                add         edi,        4
           
                dec         ecx
                jnz         bitblt_fm_cols
                
                add         esi,        [src_row_adv]
                add         edi,        [dest_row_adv]
                
                dec         ebx
                jnz         bitblt_fm_rows
                
                emms
    end asm
end sub

sub bitblt_FalloutToFalloutMix(dest as uinteger ptr,_
                               xpos as integer, ypos as integer,_
                               src  as uinteger ptr,_
                               src_x0 as integer, src_y0 as integer,_
                               src_x1 as integer, src_y1 as integer)
                               
    dim as integer ptr dest_pxls, src_pxls
    dim as integer     dest_w, dest_h
    dim as integer     src_w, src_h
    dim as integer     target_w, target_h
    dim as integer     dest_row_adv, src_row_adv
    imageinfo dest,dest_w,dest_h,,,dest_pxls
    imageinfo src,src_w,src_h,,,src_pxls
    
    dest_pxls += xpos + ypos * dest_w
    src_pxls += src_x0 + src_y0 * src_w
    
    target_w = (src_x1 - src_x0 + 1)
    target_h = (src_y1 - src_y0 + 1)
    
    dest_row_adv = (dest_w - target_w) shl 2
    src_row_adv = (src_w - target_w) shl 2
    
    asm
        
                mov         esi,        [src_pxls]
                mov         edi,        [dest_pxls]
                
                mov         eax,        [target_w]
                mov         ebx,        [target_h]
                
                pxor        mm2,        mm2
                mov         edx,        &h00010001
                movd        mm3,        edx
                punpckldq   mm3,        mm3
                
            bitblt_ftfm_rows:
            
                mov         ecx,        eax
                
            bitblt_ftfm_cols:
            
                movd        mm0,        [esi]
                movd        mm1,        [edi]
                punpcklbw   mm0,        mm2
                punpcklbw   mm1,        mm2
                
                paddusw     mm0,        mm3
                pmullw      mm1,        mm0
                psrlw       mm1,        8
                packuswb    mm1,        mm2
                
                movd        [edi],      mm1
                
                add         esi,        4
                add         edi,        4
           
                dec         ecx
                jnz         bitblt_ftfm_cols
                
                add         esi,        [src_row_adv]
                add         edi,        [dest_row_adv]
                
                dec         ebx
                jnz         bitblt_ftfm_rows
                
                emms
    end asm
end sub

function trimwhite(s as string) as string
	while (left(s, 1) = " ") or (left(s, 1) = "\t")
		s = right(s, len(s)-1)
	wend
	while (right(s, 1) = " ") or (right(s, 1) = "\t")
		s = left(s, len(s)-1)
	wend
	return s
end function

Function ScreenClip(px as integer, py as integer ,_
                    sx as integer, sy as integer ,_
                    byref npx  as integer, byref npy  as integer ,_
                    byref sdx1 as integer, byref sdy1 as integer ,_
                    byref sdx2 as integer, byref sdy2 as integer) as integer
    Dim as integer px1,py1,px2,py2,SW,SH
    dim as integer bbx1, bbx2, bby1, bby2
    SW = SCRX
    SH = SCRY
    px1 = px       : py1 = py
    px2 = px+sx - 1: py2 = py+sy - 1
    If px2 <  0  Then Return 0
    If px1 >= sw Then Return 0
    If py2 <  0  Then Return 0
    If py1 >= sh Then Return 0
    
    bbx1 = iif(px1 <   0, 0     , px1)
    bby1 = iif(py1 <   0, 0     , py1)
    bbx2 = iif(px2 >= SW, SW - 1, px2)
    bby2 = iif(py2 >= SH, SH - 1, py2)
    
    npx  = bbx1
    npy  = bby1
    sdx1 = bbx1 - px1
    sdy1 = bby1 - py1
    sdx2 = sx - (px2 - bbx2) - 1
    sdy2 = sy - (py2 - bby2) - 1

    Return 1
End Function

function circleBox(px as double, py as double, rad as double,_
                   x1 as double, y1 as double,_
                   x2 as double, y2 as double) as integer
    dim as integer dx, dy, x, y, c=0
    x=px
    rad *= rad
    if x<x1 then
        x=x1
        c = 1
    elseif x>x2 then
        x=x2
        c = 1
    endif
    x = x - px: x *= x
    dy = y1 - py: dy *= dy
    if x+dy<rad then return 1
    dy = y2 - py: dy *= dy
    if x+dy<rad then return 1
    y=py
    if y<y1 then
        y=y1
        c=1
    elseif y>y2 then
        y=y2
        c=1
    endif
    y = y - py: y *= y
    dx = x1 - px: dx *= dx
    if y+dx<rad then return 1
    dx = x2 - px: dx *= dx
    if y+dx<rad then return 1
    if c=0 then return 1
    return 0
end function 

sub drawStringShadow(scnbuff as integer ptr,_
					 x as integer, y as integer,_
					 text as string,_
					 col as integer)
	draw STRING scnbuff, (x+1, y+1), text, rgb(16,16,16)
	draw string scnbuff, (x, y), text, col
end sub
