#include "utility.bi"
#include "constants.bi"
#include "debug.bi"

'need put PSET style rotation blitter
'need put ALPHA style rotation blitter

'could either do real time, or generate rotation maps <- faster and easier, lets do that in animation

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

sub copyImageRotate(src as uinteger ptr, dest as uinteger ptr,_
					flipFlags as integer,_
					src_x as integer, src_y as integer,_
					img_width as integer, img_height as integer,_
					dest_x as integer, dest_y as integer)
	
	#define X_ 0
	#define Y_ 1
	
	dim as integer ppos(0 to 1)
	dim as integer pdes(0 to 1)
	dim as integer pdir(0 to 1)
	dim as integer ptr ptile(0 to 1)
	dim as integer byCol, byRow, oldCol
	dim as integer xpos, ypos, w
	dim as integer rt, xtn, ytn
	dim as integer xpn, ypn, col
	dim as integer pitchSrc, pitchDest
	dim as byte ptr dataSrc, dataDest
	
	rt  = flipFlags 
	xtn = src_x     
	ytn = src_y     
	xpn = dest_x    
	ypn = dest_y    

	if rt = 0 then
		put dest, (xpn, ypn), src, (xtn, ytn)-(xtn+img_width-1, ytn+img_height-1), PSET
	else
		imageinfo src,,,,pitchSrc, dataSrc
		imageinfo dest,,,,pitchDest, dataDest
		
		ptile(X_) = @xtn
		ptile(Y_) = @ytn
		ppos(X_) = xpn
		ppos(Y_) = ypn
		pdes(X_) = xpn
		pdes(Y_) = ypn
		select case rt
		case 7
			byRow = X_
			byCol = Y_
			ppos(byRow) += (img_height - 1)
			ppos(byCol) += (img_width - 1)
			pdes(byRow) += -1
			pdes(byCol) += -1
			pdir(byRow) = -1
			pdir(byCol) = -1
		case 2
			byRow = Y_
			byCol = X_
			ppos(byRow) += (img_height - 1)
			ppos(byCol) += 0
			pdes(byRow) += -1
			pdes(byCol) += img_width
			pdir(byRow) = -1
			pdir(byCol) = 1
		case 3
			byRow = X_
			byCol = Y_
			ppos(byRow) += 0
			ppos(byCol) += (img_width - 1)
			pdes(byRow) += img_height
			pdes(byCol) += -1
			pdir(byRow) = 1
			pdir(byCol) = -1
		case 4
			byRow = Y_
			byCol = X_
			ppos(byRow) += 0
			ppos(byCol) += (img_width - 1)
			pdes(byRow) += img_height
			pdes(byCol) += -1
			pdir(byRow) = 1
			pdir(byCol) = -1
		case 5
			byRow = X_
			byCol = Y_
			ppos(byRow) += (img_height - 1)
			ppos(byCol) += 0
			pdes(byRow) += -1
			pdes(byCol) += img_width
			pdir(byRow) = -1
			pdir(byCol) = 1
		case 6
			byRow = Y_
			byCol = X_
			ppos(byRow) += (img_height - 1)
			ppos(byCol) += (img_width - 1)
			pdes(byRow) += -1
			pdes(byCol) += -1
			pdir(byRow) = -1
			pdir(byCol) = -1
		case 1
			byRow = X_
			byCol = Y_
			ppos(byRow) += 0
			ppos(byCol) += 0
			pdes(byRow) += img_height
			pdes(byCol) += img_width
			pdir(byRow) = 1
			pdir(byCol) = 1
		end select
		ypos = ytn
		oldCol = ppos(byCol)
				
		while ppos(byRow) <> pdes(byRow)
			ppos(byCol) = oldCol
			xpos = xtn
			while ppos(byCol) <> pdes(byCol)
				
				col = *cast(integer ptr, @dataSrc[xpos*4 + ypos*pitchSrc])  
				*cast(integer ptr, @dataDest[ppos(X_)*4 + ppos(Y_)*pitchDest]) = col
				
				ppos(byCol) += pdir(byCol)
				xpos += 1
			wend
			ppos(byRow) += pdir(byRow)
			ypos += 1
		wend
	end if			
		
					
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

                movdqa      0[edi],     xmm0
                movdqa      16[edi],    xmm1
                movdqa      32[edi],    xmm2
                movdqa      48[edi],    xmm3
                movdqa      64[edi],    xmm4
                movdqa      80[edi],    xmm5
                movdqa      96[edi],    xmm6
                movdqa      112[edi],   xmm7

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

sub bitblt_alphaGlow(dest as uinteger ptr,_
					 xpos as integer, ypos as integer,_
					 src  as uinteger ptr,_
                     src_x0 as integer, src_y0 as integer,_
                     src_x1 as integer, src_y1 as integer,_
                     colOffset as integer = &h00000000)

    #macro MIX_STEP()
				
		movdqu		xmm0,		[esi]			
		
		movdqu		xmm4,		[col_offset]	
		psubusb		xmm0,		xmm4
				
		movhlps		xmm1,		xmm0    
		
		punpcklbw 	xmm0, 		xmm6
		punpcklbw 	xmm1, 		xmm6
		movdqu		xmm2,		xmm0
		movdqu		xmm3,		xmm1
	
		pshufhw		xmm0,		xmm0,				&hff
		pshuflw		xmm0,		xmm0,				&hff
		
		pshufhw		xmm1,		xmm1,				&hff
		pshuflw		xmm1,		xmm1,				&hff

		movdqu		xmm4,		[edi]			
		movhlps		xmm5,		xmm4    		
		
		punpcklbw 	xmm4, 		xmm6
		punpcklbw 	xmm5, 		xmm6
		
		psubsw		xmm2,		xmm4
		psubsw		xmm3,		xmm5
		
		psrlw		xmm0,		1
		psrlw		xmm1,		1
		pmullw		xmm2,		xmm0			
		pmullw		xmm3,		xmm1
		psraw		xmm2, 		7
		psraw		xmm3,		7
		
		paddsw		xmm2,		xmm4
		paddsw		xmm3,		xmm5

		packuswb	xmm2,		xmm3			
		
    #endmacro
    
	static as integer zeroReg(0 to 3) = {&h00000000, &h00000000, &h00000000, &h00000000}    
    static as integer col_offset(0 to 3)
    
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
    
    colOffset = ((&hff - ((colOffset shr 24) and &hff)) shl 24) or _
				((&hff - ((colOffset shr 16) and &hff)) shl 16) or _
                ((&hff - ((colOffset shr 08) and &hff)) shl 08) or _
                (&hff - (colOffset and &hff))
	
	col_offset(0) = colOffset
	col_offset(1) = colOffset
	col_offset(2) = colOffset
	col_offset(3) = colOffset
	
	if target_w and 3 then target_w -= 4 
	
	if target_w >= 4 then
		
		asm
					movdqu		xmm6,		[zeroReg]

					mov         esi,        [src_pxls]
					mov         edi,        [dest_pxls]
					
					mov         eax,        [target_w]
					mov         ebx,        [target_h]
						
			bitblt_ag_rows:
				
					mov         ecx,        eax
					
			bitblt_ag_cols:
				
					MIX_STEP()	
					
					movdqu		[edi],		xmm2
				   
					add         esi,        16
					add         edi,        16
							
					cmp         ecx,		4
					jle			bitblt_ag_oddrow
					
					sub			ecx,		4
					
					jmp         bitblt_ag_cols
					
			bitblt_ag_oddrow:
			
					test        ecx,        2
					jz          bitblt_ag_skip2
					
					MIX_STEP()
					
					movq		[edi],		xmm2
					
					add         esi,        8
					add         edi,        8
			bitblt_ag_skip2:
			
					test        ecx,        1
					jz          bitblt_ag_skip1
					
					MIX_STEP()
							
					movd		[edi],		xmm2
					
					add			esi,		4
					add			edi,		4
			
			bitblt_ag_skip1:     
					 
					add         esi,        [src_row_adv]
					add         edi,        [dest_row_adv]
					
					dec         ebx
					jnz         bitblt_ag_rows
		end asm
	elseif target_w > 1 then
		/'
		drawStringShadow dest, 200, 500, str(target_w), &hffffffff
		asm
					'movdqu		xmm6,		[zeroReg]

					mov         esi,        [src_pxls]
					mov         edi,        [dest_pxls]
					
					mov         eax,        [target_w]
					mov         ebx,        [target_h]
						
			bitblt_ag_2rows:
				
					mov         ecx,        eax
					
			bitblt_ag_2cols:
			
					test        ecx,        2
					jz          bitblt_ag_2skip2
					
					MIX_STEP()
					
					movq		[edi],		xmm2
					
					add         esi,        8
					add         edi,        8
					
					sub			ecx,		2
			bitblt_ag_2skip2:
			
					test        ecx,        1
					jz          bitblt_ag_2skip1
					
					MIX_STEP()
							
					movd		[edi],		xmm2
					
					add			esi,		4
					add			edi,		4
			
					sub			ecx,		1
			bitblt_ag_2skip1:     
					 
					add         esi,        [src_row_adv]
					add         edi,        [dest_row_adv]
					
					dec         ebx
					jnz         bitblt_ag_2rows
		end asm	
		'/
	end if         
end sub

function countTrans(src as uinteger ptr,_
					src_x0 as integer, src_y0 as integer,_
                    src_x1 as integer, src_y1 as integer) as integer
	dim as integer w, h, w_init
	dim as integer pitch
	dim as integer count
	dim as integer ptr data_
	w_init = src_x1 - src_x0 + 1
	h = src_y1 - src_y0 + 1
	imageinfo src, , , , pitch, data_
	pitch shr= 2
	data_ += src_x0 + src_y0 * pitch 
	pitch = (pitch - w_init)
	count = 0
	while h > 0
		w = w_init
		while w > 0
			if *data_ <> &hffff00ff then count += 1
			data_ += 1
			w -= 1
		wend
		data_ += pitch
		h -= 1
	wend
	return count
end function

function compareTrans(src0 as uinteger ptr,_
					  src0_x as integer, src0_y as integer,_
					  src1 as uinteger ptr,_
					  src1_x as integer, src1_y as integer,_
					  w as integer, h as integer) as integer
	dim as integer pitch0, pitch1
	dim as integer count
	dim as integer const_one
	dim as integer ptr data0_, data1_
	imageinfo src0, , , , pitch0, data0_
	imageinfo src1, , , , pitch1, data1_
	pitch0 shr= 2
	pitch1 shr= 2

	data0_ += src0_x + src0_y * pitch0
	data1_ += src1_x + src1_y * pitch1
	
	pitch0 = (pitch0 - w) shl 2
	pitch1 = (pitch1 - w) shl 2
	
	const_one = 1
	
	asm
		mov 	esi,					[data0_]
		mov		edi,					[data1_]
		mov		ecx,					&h00
		
		ct_rows:
		
		mov		edx,					[w]

		ct_cols:
		
		mov		eax,					&h00
		mov		ebx,					&h00
		
		cmp		dword ptr [esi],		&hffff00ff
		cmovne	eax,					[const_one]
		cmp		dword ptr [edi],		&hffff00ff
		cmovne	ebx,					[const_one]
		
		and		eax,					ebx	
		add		ecx,					eax
		
		add		esi,					&h04
		add		edi,					&h04
		dec		edx
		
		jnz		ct_cols
		
		add		esi,					[pitch0]
		add		edi,					[pitch1]
		
		dec		dword ptr [h]
		
		jnz		ct_rows
		
		mov		[count],				ecx
	end asm
	
	return count				  
end function

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
    end if
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
    end if
    y = y - py: y *= y
    dx = x1 - px: dx *= dx
    if y+dx<rad then return 1
    dx = x2 - px: dx *= dx
    if y+dx<rad then return 1
    if c=0 then return 1
    return 0
end function 

function boxbox(a0 as Vector2D, b0 as Vector2D, a1 as Vector2D, b1 as Vector2D) as integer
	if (a1.x > b0.x) orElse (a0.x > b1.x) then return 0
	if (a1.y > b0.y) orElse (a0.y > b1.y) then return 0
	return 1
end function

sub vTriangle(dest as integer ptr = 0,_
			  p0 as Vector2D, p1 as Vector2D, p2 as Vector2D, _
			  col as integer)
			  
	triangle_AHS dest, p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, col
end sub


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
    #define MAX_BLOCK_X 64
    #define MAX_BLOCK_Y 32
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
    
    #define GET_SIZE_X(x) 1 shl (((x) and &h03) + 3)
    #define GET_SIZE_Y(x) 1 shl (((x) shr &h02) + 3)

    #macro EXPAND(x, y)
        x[y + 1] = x[y]
        x[y + 2] = x[y]
        x[y + 3] = x[y]
    #endmacro
    
    #define STACK_SIZE 16
    
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
    dim as integer splitX(0 to 11) = { -1,   0,   1,   2,_
                                       -1,   4,   5,   6,_
                                       -1,   8,   9,  10}
    dim as integer splitY(0 to 11) = { -1,  -1,  -1,  -1,_
                                        0,   1,   2,   3,_
                                        4,   5,   6,   7}

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
    
    if dest <> 0 then
        imageinfo dest, dst_w, dst_h, , ,dstPxls
    else
        screeninfo dst_w, dst_h
        dstPxls = screenptr
    end if
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
            
            splitMask = 11
            scx = x
            scy = y
            PUSH_BLOCK()
            
            while(stackPtr > -1)
                POP_BLOCK()
                curBlockW = GET_SIZE_X(splitMask)
                curBlockH = GET_SIZE_Y(splitMask)       
                                
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
                        else
                            if splitX(splitMask) = -1 then
                                if splitY(splitMask) = -1 then
                                    cyx[_0_ + 0] =  cxy[_0_ + 1]
                                    EXPAND(cxy, _0_)
                                    EXPAND(cyx, _0_)
                                    
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
                                    SPLIT_BLOCK_H()
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

sub drawStringShadow(scnbuff as integer ptr,_
					 x as integer, y as integer,_
					 text as string,_
					 col as integer)
	draw STRING scnbuff, (x+1, y+1), text, rgb(16,16,16)
	draw string scnbuff, (x, y), text, col
end sub

sub addColor(byref ac as integer, byref bc as integer)
	dim as integer r, g, b
	r = ((ac shr 16) and &hff) + ((bc shr 16) and &hff) 
	if r > 255 then r = 255
	g = ((ac shr 8) and &hff) + ((bc shr 8) and &hff) 
	if g > 255 then g = 255
	b = (ac and &hff) + (bc and &hff) 
	if b > 255 then b = 255	
	ac = (r shl 16) or (g shl 8) or (b)
end sub

sub subColor(byref ac as integer, byref bc as integer)
	dim as integer r, g, b
	r = ((ac shr 16) and &hff) - ((bc shr 16) and &hff) 
	if r < 0 then r = 0
	g = ((ac shr 8) and &hff) - ((bc shr 8) and &hff) 
	if g < 0 then g = 0
	b = (ac and &hff) - (bc and &hff) 
	if b < 0 then b = 0	
	ac = (r shl 16) or (g shl 8) or (b)
end sub

sub vline(scnbuff as integer ptr, a as Vector2D, b as Vector2D, col as integer)
	line scnbuff, (a.x, a.y)-(b.x, b.y), col
end sub
