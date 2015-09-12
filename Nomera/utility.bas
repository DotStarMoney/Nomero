#include "utility.bi"
#include "constants.bi"
#include "debug.bi"
#include "fbgfx.bi"

'_______________________________________________________________________________
type sse_t field = 1
	s(0 to 3) as single
end type

type mmx_t field = 1
	i(0 to 1) as integer
end type
'________________
const pi_180 = _PI_ / 180
sub rotozoom_alpha2( byref dst as FB.IMAGE ptr = 0, byref src as const FB.IMAGE ptr, byval positx as integer, byval posity as integer, byref angle as integer,_
                     byref zoomx as single = 0, byref zoomy as single = 0, byval transcol as uinteger = &hffff00ff, byval alphalvl as integer = 255, byref offsetx as integer = 0, byref offsety as integer = 0 )
    
	dim as sse_t sse0, sse1, sse2, sse3, sse4, sse5
	dim as integer nx = any, ny = any
	dim as single tcdzx = any, tcdzy = any, tsdzx = any, tsdzy = any
	dim as integer sw2 = any, sh2 = any, dw = any, dh = any
	dim as single tc = any, ts = any
	dim as uinteger ptr dstptr = any, srcptr = any
	dim as integer startx = any, endx = any, starty = any, endy = any
	dim as integer x(3), y(3)
	dim as integer xa = any, xb = any, ya = any, yb = any
	dim as integer dstpitch = any
	dim as integer srcpitch = any, srcwidth = any, srcheight = any
	Dim As Ulongint mask1 = &H00FF00FF00FF00FFULL'&H000000FF00FF00FFULL mask change copies src alpha
	dim as integer x_draw_len = any, y_draw_len = any
	dim as short alphalevel(3) = {alphalvl,alphalvl,alphalvl,alphalvl}
    
    if alphalvl <0 then
        alphalvl = 0
    elseif alphalvl>255 then
        alphalvl = 255
    end if
    
	if zoomx = 0 then exit sub
    if zoomy = 0 then zoomy = zoomx
    If src = 0 Then Exit Sub

	if dst = 0 then
		dstptr = screenptr
		screeninfo dw,dh,,,dstpitch
    else
		dstptr = cast( uinteger ptr, dst + 1 )
		dw = dst->width
		dh = dst->height
		dstpitch = dst->pitch
    end if
    
	srcptr = cast( uinteger ptr, src + 1 )
   
	sw2 = src->width\2
	sh2 = src->height\2
	srcpitch = src->pitch
	srcwidth = src->width
	srcheight = src->height
  
    
	tc = cos( angle * pi_180 )
	ts = sin( angle * pi_180 )
	tcdzx = tc/zoomx
	tcdzy = tc/zoomy
	tsdzx = ts/zoomx
	tsdzy = ts/zoomy
    
	xa = sw2 * tc * zoomx + sh2  * ts * zoomx
	ya = sh2 * tc * zoomy - sw2  * ts * zoomy
    
	xb = sh2 * ts * zoomx - sw2  * tc * zoomx
	yb = sw2 * ts * zoomy + sh2  * tc * zoomy

    Dim As Integer centerx = -(offsetx*(tc*zoomx) + offsety*(ts*zoomx)) + offsetx
    Dim As Integer centery = -(offsety*(tc*zoomy) - offsetx*(ts*zoomy)) + offsety

	x(0) = sw2-xa
	x(1) = sw2+xa
	x(2) = sw2-xb
	x(3) = sw2+xb
	y(0) = sh2-ya
	y(1) = sh2+ya
	y(2) = sh2-yb
	y(3) = sh2+yb
    
	for i as integer = 0 to 3
		for j as integer = i to 3
			if x(i)>=x(j) then
				swap x(i), x(j)
            end if
        next
    next
	startx = x(0)
	endx = x(3)
    
	for i as integer = 0 to 3
		for j as integer = i to 3
			if y(i)>=y(j) then
				swap y(i), y(j)
            end if
        next
    next
	starty = y(0)
	endy = y(3)
    
	positx-=sw2
	posity-=sh2
    positx+=centerx
    posity+=centery
	if posity+starty<0 then starty = -posity
	if positx+startx<0 then startx = -positx
	if posity+endy<0 then endy = -posity
	if positx+endx<0 then endx = -positx
    
	if positx+startx>(dw-1) then startx = (dw-1)-positx
	if posity+starty>(dh-1) then starty = (dh-1)-posity
	if positx+endx>(dw-1) then endx = (dw-1)-positx
	if posity+endy>(dh-1) then endy = (dh-1)-posity
	if startx = endx or starty = endy then exit sub
    
	ny = starty - sh2
	nx = startx - sw2
    
	dstptr += dstpitch * (starty + posity) \ 4
    
	x_draw_len = (endx - startx)
	y_draw_len = (endy - starty)
    
	sse1.s(0) = tcdzx
	sse1.s(1) = tsdzx
    
	sse2.s(0) = -(ny * tsdzy)
	sse2.s(1) = (ny * tcdzy)
    
	sse3.s(0) = -tsdzy
	sse3.s(1) = tcdzy
    
	sse4.s(0) = (nx * tcdzx) + sw2
	sse4.s(1) = (nx * tsdzx) + sh2
    
	if x_draw_len = 0 then exit sub
	if y_draw_len = 0 then exit sub
    
	cptr( any ptr, dstptr ) += (startx + positx) * 4
    
	dim as any ptr ptr row_table = callocate( srcheight * sizeof( any ptr ) )
	dim as any ptr p = srcptr
    
	for i as integer = 0 to srcheight - 1
		row_table[i] = p
		p += srcpitch
    next i
    
	asm
		.balign 4
        
        movups xmm1, [sse1]
        movups xmm2, [sse2]
        movups xmm3, [sse3]
        movups xmm4, [sse4]
        
		.balign 4
		y_inner4:
    
        movaps xmm0, xmm4
        
        mov edi, dword ptr [dstptr]
        
        mov ecx, dword ptr [x_draw_len]
        
        
        addps xmm0, xmm2
        
		.balign 4
		x_inner4:
        
        cvtps2pi mm0, xmm0
        
        movd esi, mm0
        
        psrlq mm0, 32
        
        cmp esi, dword ptr [srcwidth]
        jae no_draw4
        
        movd edx, mm0
        
        cmp edx, dword ptr [srcheight]
        jae no_draw4
        
        shl esi, 2
        mov eax, dword ptr [row_table]
        add esi, dword ptr [eax+edx*4]
        
        mov eax, dword ptr [esi]

        cmp eax, dword ptr [transcol]
        je no_draw4
      
        punpcklbw mm0, dword ptr [esi]
        punpcklbw mm1, dword ptr [edi]
        
        psrlw mm0, 8               
        psrlw mm1, 8               
        
        
        movq      mm3, [alphalevel]
        movq      mm2, mm0
        
        punpckhwd mm2, mm2         
        punpckhdq mm2, mm2         
        pmullw    mm2, mm3
        psrlw     mm2, 8
        
        
        psubw mm0, mm1              
        pmullw mm0, mm2             
        psrlq mm0, 8                
        paddw mm0, mm1              
        pand mm0, qword ptr [mask1] 
        
        packuswb mm0, mm0
        
        movd dword ptr [edi], mm0
        
		.balign 4
		no_draw4:
        


        addps xmm0, xmm1
        
        add edi, 4
        
        sub ecx, 1
        
        jnz x_inner4
        
		x_end4:
        


        addps xmm2, xmm3
        
        mov eax, dword ptr [dstpitch]
        add dword ptr [dstptr], eax
        
        sub dword ptr [y_draw_len], 1
        
        jnz y_inner4
        
		y_end4:
        
        emms
    end asm
    
	deallocate( row_table )
    
end sub



function _min_ overload(x as double, y as double) as double
    if x < y then 
        return x
    else
        return y
    end if
end function

function _min_ overload(x as integer, y as integer) as integer
    if x < y then 
        return x
    else
        return y
    end if
end function


function _max_ overload(x as double, y as double) as double
    if x >= y then 
        return x
    else
        return y
    end if
end function

function _max_ overload(x as integer, y as integer) as integer
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
function findChar(text as string, searchChar as string, hirearchy as string = "", interval as string = "") as integer
    dim as integer bnum
    dim as integer i, q
    dim as string curChar, curHire = "", curInterval = ""
    for i = 1 to len(text)
        curChar = mid(text, i, 1)

        bnum = 0
        for q = 1 to len(hirearchy)
            if mid(hirearchy, q, 1) = curChar then
                bnum = q
                exit for
            end if
        next q
        if bnum > 0 then
            if (bnum and 1) then
                curHire += curChar
            else
                if right(curHire, 1) = mid(hirearchy, bnum - 1, 1) then
                    curHire = left(curHire, len(curHire) - 1)
                end if
            end if
        end if
        
        bnum = 0
        for q = 1 to len(interval)
            if mid(interval, q, 1) = curChar then
                bnum = q
                exit for
            end if
        next q
        if bnum > 0 then
            if right(curInterval, 1) = mid(interval, bnum, 1) then
                curInterval = left(curInterval, len(curInterval) - 1)
            else
                curInterval = curInterval + mid(interval, bnum, 1)
            end if
        end if
        
        if curHire = "" andAlso curInterval = "" andAlso curChar = searchChar then return i
    next i
    return 0
end function

sub getStringFromFile(filenum as integer, stringData as string)
    dim as ubyte curASCII
    stringData = ""
    do
        get #filenum,,curASCII
        if curASCII then stringData += chr(curASCII)
    loop while curASCII 
end sub

sub tokenize(text as string, ret() as string, delim as string = " ", max_ret as integer = -1, hirearchy as string = "")
    dim as integer curToken = 0
    dim as string curHire = ""
    dim as string curChar
    dim as integer isDelim
    dim as integer bnum
    dim as integer i, q
    redim as string ret(0)
    for i = 1 to len(text)
        curChar = mid(text, i, 1)
        
        isDelim = 0
        for q = 1 to len(delim)
            if mid(delim, q, 1) = curChar then
                isDelim = 1
                exit for
            end if
        next q
        
        if isDelim andAlso curHire = "" then
            curToken += 1
            if curToken = max_ret then exit sub
            redim preserve as string ret(curToken)
            ret(curToken) = ""
            continue for
        end if
        
        bnum = 0
        for q = 1 to len(hirearchy)
            if mid(hirearchy, q, 1) = curChar then
                bnum = q
                exit for
            end if
        next q
        if bnum > 0 then
            if (bnum and 1) then
                curHire += curChar
            else
                if right(curHire, 1) = mid(hirearchy, bnum - 1, 1) then
                    curHire = left(curHire, len(curHire) - 1)
                end if
            end if
        end if
        
        ret(curToken) += curChar
        
    next i
end sub
 
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
                  centerX as double, centerY as double,_
                  depth as double)
                    
    p_x += (cam_x - centerX) * (1-depth)
    p_y += (cam_y - centerY) * (1-depth)
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
					dest_x as integer, dest_y as integer, treatAsNorm as integer = 0)
	
	#define X_ 0
	#define Y_ 1
	
	dim as integer ppos(0 to 1)
	dim as integer pdes(0 to 1)
	dim as integer pdir(0 to 1)
	dim as integer ptr ptile(0 to 1)
	dim as integer byCol, byRow, oldCol
	dim as integer xpos, ypos, w
	dim as integer rt, xtn, ytn
	dim as integer xpn, ypn, col, bx, by
    dim as integer flipX, flipY
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
                
                if treatAsNorm = 1 then
                    bx = (col and &hff) - 128
                    by = ((col shr 8) and &hff) - 128
                    
                    if byRow = X_ then swap bx, by
                    if pdir(X_) < 0 then bx = (-bx - 1)
                    if pdir(Y_) < 0 then by = (-by - 1)                
                
                    col = (col and &hFFFF0000) or ((by + 128) shl 8) or (bx + 128)
                end if
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

function intLog2(x as integer) as integer
    asm
        mov     eax,        [x]
        bsr     eax,        eax
        mov     [function], eax
    end asm
end function

sub bitblt_alphaGlow(dest as uinteger ptr,_
					 xpos as integer, ypos as integer,_
					 src  as uinteger ptr,_
                     src_x0 as integer, src_y0 as integer,_
                     src_x1 as integer, src_y1 as integer,_
                     colOffset as integer = &h00000000)

    #macro MIX_STEP()
						
		movdqu		xmm2,		[col_offset]	
		psubusb		xmm0,		xmm2
				
		movhlps		xmm1,		xmm0    
		
		punpcklbw 	xmm0, 		xmm6
		punpcklbw 	xmm1, 		xmm6
		movdqu		xmm2,		xmm0
		movdqu		xmm3,		xmm1
	
		pshufhw		xmm0,		xmm0,				&hff
		pshuflw		xmm0,		xmm0,				&hff
		
		pshufhw		xmm1,		xmm1,				&hff
		pshuflw		xmm1,		xmm1,				&hff

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
    
    #macro MIX_STEP_HALF()
						
		movdqu		xmm2,		[col_offset]	
		psubusb		xmm0,		xmm2
						
		punpcklbw 	xmm0, 		xmm6
		movdqu		xmm2,		xmm0
	
		pshufhw		xmm0,		xmm0,				&hff
		pshuflw		xmm0,		xmm0,				&hff
				
		punpcklbw 	xmm4, 		xmm6
		
		psubsw		xmm2,		xmm4
		
		psrlw		xmm0,		1
		pmullw		xmm2,		xmm0			
		psraw		xmm2, 		7
		
		paddsw		xmm2,		xmm4

		packuswb	xmm2,		xmm3			
		
    #endmacro
    
	static as integer zeroReg(0 to 3) = {&h00000000, &h00000000, &h00000000, &h00000000}    
    static as integer col_offset(0 to 3)
    
    dim as byte ptr dest_pxls, src_pxls
    dim as integer  dest_w, dest_h
    dim as integer  src_w, src_h
    dim as integer  target_w, target_h
    dim as integer  dest_row_adv, src_row_adv
    
    imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
    imageinfo src,src_w,src_h,,src_row_adv,src_pxls
    
    dest_pxls += (xpos shl 2) + ypos*dest_row_adv
    src_pxls  += (src_x0 shl 2) + src_y0*src_row_adv
    
    target_w = (src_x1 - src_x0 + 1)
    target_h = (src_y1 - src_y0 + 1)
    
    if target_h < 1 then exit sub
    
    dest_row_adv -= target_w shl 2
    src_row_adv  -= target_w shl 2    
    
    colOffset = ((&hff - ((colOffset shr 24) and &hff)) shl 24) or _
				((&hff - ((colOffset shr 16) and &hff)) shl 16) or _
                ((&hff - ((colOffset shr 08) and &hff)) shl 08) or _
                (&hff - (colOffset and &hff))
	
	col_offset(0) = colOffset
	col_offset(1) = colOffset
	col_offset(2) = colOffset
	col_offset(3) = colOffset

    
    asm
                movdqu		xmm6,		[zeroReg]

                mov         esi,        [src_pxls]
                mov         edi,        [dest_pxls]
                
                mov         eax,        [target_w]
                mov         ebx,        [target_h]
                    
        bitblt_ag_rows:
                
                mov         ecx,        eax

                cmp         ecx,        4
                jl          bitblt_ag_2pxls
                
        bitblt_ag_cols:
        
                movdqu		xmm0,		[esi]		
                movdqu		xmm4,		[edi]			
                
                MIX_STEP()	
                
                movdqu		[edi],		xmm2
               
                add         esi,        16
                add         edi,        16
                        
                sub			ecx,		4
                cmp         ecx,        4
                jge         bitblt_ag_cols
        
        bitblt_ag_2pxls:        
                
                test        ecx,        2
                jz          bitblt_ag_1pxls
 
                movq		xmm0,		[esi]		
                movq		xmm4,		[edi]
                
                MIX_STEP_HALF()
                
                movq        [edi],      xmm2

                add         esi,        8
                add         edi,        8
 
        bitblt_ag_1pxls:
        
                test        ecx,        1
                jz          bitblt_ag_nextRow
        
                movd        xmm0,       [esi]
                movd        xmm4,       [edi]
                
                MIX_STEP_HALF()
                
                movd        [edi],      xmm2
        
                add         esi,        4
                add         edi,        4 
                
        bitblt_ag_nextRow:
        
                add         esi,        [src_row_adv]
                add         edi,        [dest_row_adv]
                
                dec         ebx
                jnz         bitblt_ag_rows
        
    end asm
    
 
end sub

sub bitblt_prealpha_target(dest as uinteger ptr,_
                           alphasrc as uinteger ptr,_
                           xpos as integer, ypos as integer,_
                           src  as uinteger ptr,_
                           src_x0 as integer, src_y0 as integer,_
                           src_x1 as integer, src_y1 as integer)
                                   
                                   
    #macro MIX_STEP()
		movdqu		xmm0,		[esi]		            
        movdqu      xmm1,       [alphaMask]
        por         xmm0,       xmm1
        
        movdqu      xmm4,       [edx]		            
        
        movdqa      xmm3,       xmm0                    
        pcmpeqd     xmm3,       xmm7
        por         xmm4,       xmm3                    
        
        movhlps     xmm5,       xmm4                    
		punpcklbw 	xmm4, 		xmm6
		punpcklbw 	xmm5, 		xmm6
		pshufhw		xmm4,		xmm4,				&hff
		pshuflw		xmm4,		xmm4,				&hff
		pshufhw		xmm5,		xmm5,				&hff
		pshuflw		xmm5,		xmm5,				&hff
        
        movhlps     xmm1,       xmm0                      
        punpcklbw 	xmm0, 		xmm6
		punpcklbw 	xmm1, 		xmm6
        
        movdqu      xmm2,       [edi]                     
        movhlps     xmm3,       xmm2
        punpcklbw 	xmm2, 		xmm6
		punpcklbw 	xmm3, 		xmm6
        
        psubsw		xmm2,		xmm0
		psubsw		xmm3,		xmm1
		
		psrlw		xmm4,		1
		psrlw		xmm5,		1
		pmullw		xmm2,		xmm4			
		pmullw		xmm3,		xmm5
		psraw		xmm2, 		7
		psraw		xmm3,		7
		
		paddsw		xmm2,		xmm0
		paddsw		xmm3,		xmm1
        
        
        packuswb	xmm2,		xmm3			
        
        movdqu      [edi],      xmm2
		
    #endmacro
    
    #macro MIX_STEP_HALF()
						
		movq 		xmm0,		[esi]		            
        movq        xmm1,       [alphaMask]
        por         xmm0,       xmm1
        
        movq        xmm4,       [edx]		            
        
        movq        xmm3,       xmm0                    
        pcmpeqd     xmm3,       xmm7
        por         xmm4,       xmm3                    
        
		punpcklbw 	xmm4, 		xmm6
		pshufhw		xmm4,		xmm4,				&hff
		pshuflw		xmm4,		xmm4,				&hff
        
        punpcklbw 	xmm0, 		xmm6
        
        movq        xmm2,       [edi]                     
        punpcklbw 	xmm2, 		xmm6
        
        psubsw		xmm2,		xmm0
		
		psrlw		xmm4,		1
		pmullw		xmm2,		xmm4			
		psraw		xmm2, 		7
		
		paddsw		xmm2,		xmm0
                
        packuswb	xmm2,		xmm3			
        
        movq        [edi],      xmm2
			
    #endmacro
    
    #macro MIX_STEP_QUARTER()
						
		movd 		xmm0,		[esi]		            
        movd        xmm1,       [alphaMask]
        por         xmm0,       xmm1
        
        movd        xmm4,       [edx]		            
        
        movq        xmm3,       xmm0                    
        pcmpeqd     xmm3,       xmm7
        por         xmm4,       xmm3                    
        
		punpcklbw 	xmm4, 		xmm6
		pshufhw		xmm4,		xmm4,				&hff
		pshuflw		xmm4,		xmm4,				&hff
        
        punpcklbw 	xmm0, 		xmm6
        
        movd        xmm2,       [edi]                     
        punpcklbw 	xmm2, 		xmm6
        
        psubsw		xmm2,		xmm0
		
		psrlw		xmm4,		1
		pmullw		xmm2,		xmm4			
		psraw		xmm2, 		7
		
		paddsw		xmm2,		xmm0
                
        packuswb	xmm2,		xmm3			
        
        movd        [edi],      xmm2
			
    #endmacro
    
	static as integer zeroReg(0 to 3) = {&h00000000, &h00000000, &h00000000, &h00000000}    
    static as integer transPink(0 to 3) = {&hffff00ff, &hffff00ff, &hffff00ff, &hffff00ff}
    static as integer alphaMask(0 to 3) = {&hff000000, &hff000000, &hff000000, &hff000000}
    
    dim as byte ptr dest_pxls, src_pxls, alpha_pxls
    dim as integer  dest_w, dest_h
    dim as integer  src_w, src_h
    dim as integer  target_w, target_h
    dim as integer  dest_row_adv, src_row_adv
    
    imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
    imageinfo src,src_w,src_h,,src_row_adv,src_pxls
    imageinfo alphasrc,,,,,alpha_pxls
    
    dest_pxls += (xpos shl 2) + ypos*dest_row_adv
    alpha_pxls += (xpos shl 2) + ypos*dest_row_adv
    src_pxls  += (src_x0 shl 2) + src_y0*src_row_adv
    
    target_w = (src_x1 - src_x0 + 1)
    target_h = (src_y1 - src_y0 + 1)
    
    if target_h < 1 then exit sub
    
    dest_row_adv -= target_w shl 2
    src_row_adv  -= target_w shl 2    
     
    asm
                movdqu      xmm7,       [transPink]
                movdqu		xmm6,		[zeroReg]

                mov         esi,        [src_pxls]
                mov         edi,        [dest_pxls]
                mov         edx,        [alpha_pxls]
                
                mov         eax,        [target_w]
                mov         ebx,        [target_h]
                    
        bitblt_pat_rows:
                
                mov         ecx,        eax

                cmp         ecx,        4
                jl          bitblt_pat_2pxls
                
        bitblt_pat_cols:
          
                MIX_STEP()	
                       
                add         esi,        16
                add         edi,        16
                add         edx,        16
                        
                sub			ecx,		4
                cmp         ecx,        4
                jge         bitblt_pat_cols
        
        bitblt_pat_2pxls:        
                
                test        ecx,        2
                jz          bitblt_pat_1pxls
 
                MIX_STEP_HALF()
                
                add         esi,        8
                add         edi,        8
                add         edx,        8
 
        bitblt_pat_1pxls:
        
                test        ecx,        1
                jz          bitblt_pat_nextRow
        
                MIX_STEP_QUARTER()
        
                add         esi,        4
                add         edi,        4 
                add         edx,        4
                
        bitblt_pat_nextRow:
        
                add         esi,        [src_row_adv]
                add         edi,        [dest_row_adv]
                add         edx,        [dest_row_adv]
                
                dec         ebx
                jnz         bitblt_pat_rows
        
    end asm
                                       
                                   
end sub

sub bitblt_prealpha(dest as uinteger ptr,_
                    xpos as integer, ypos as integer,_
                    src  as uinteger ptr,_
                    src_x0 as integer, src_y0 as integer,_
                    src_x1 as integer, src_y1 as integer)
    
    #macro MIX_STEP()
										
		movhlps		xmm1,		xmm0    
		
		punpcklbw 	xmm0, 		xmm6
		punpcklbw 	xmm1, 		xmm6
		movdqu		xmm2,		xmm0
		movdqu		xmm3,		xmm1
       
		pshufhw		xmm0,		xmm0,				&hff
		pshuflw		xmm0,		xmm0,				&hff
		
		pshufhw		xmm1,		xmm1,				&hff
		pshuflw		xmm1,		xmm1,				&hff
     
		movhlps		xmm5,		xmm4    		
		
		punpcklbw 	xmm4, 		xmm6
		punpcklbw 	xmm5, 		xmm6
        
        pmullw      xmm4,       xmm0
        pmullw      xmm5,       xmm1
        psrlw       xmm4,       8
        psrlw       xmm5,       8
        
       
        pand        xmm2,       xmm7
        pand        xmm3,       xmm7
        paddusw     xmm2,       xmm4
        paddusw     xmm3,       xmm5
        
		packuswb	xmm2,		xmm3			
		
    #endmacro
    
    #macro MIX_STEP_HALF()
						
		punpcklbw 	xmm0, 		xmm6
		movdqu		xmm2,		xmm0
	
		pshufhw		xmm0,		xmm0,				&hff
		pshuflw		xmm0,		xmm0,				&hff
				
		punpcklbw 	xmm4, 		xmm6
		
        pmullw      xmm4,       xmm0
        psrlw       xmm4,       8   
        
        pand        xmm2,       xmm7
        paddusw     xmm2,       xmm4

		packuswb	xmm2,		xmm3			
		
    #endmacro
    
	static as integer zeroReg(0 to 3) = {&h00000000, &h00000000, &h00000000, &h00000000}    
    static as integer maskReg(0 to 3) = {&hffffffff, &h0000ffff, &hffffffff, &h0000ffff}
    static as integer addWords(0 to 3) = {&h00010001, &h00000001, &h00010001, &h00000001}
    
    dim as byte ptr dest_pxls, src_pxls
    dim as integer  dest_w, dest_h
    dim as integer  src_w, src_h
    dim as integer  target_w, target_h
    dim as integer  dest_row_adv, src_row_adv
    
    imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
    imageinfo src,src_w,src_h,,src_row_adv,src_pxls
    
    dest_pxls += (xpos shl 2) + ypos*dest_row_adv
    src_pxls  += (src_x0 shl 2) + src_y0*src_row_adv
    
    target_w = (src_x1 - src_x0 + 1)
    target_h = (src_y1 - src_y0 + 1)
    
    if target_h < 1 then exit sub
    
    dest_row_adv -= target_w shl 2
    src_row_adv  -= target_w shl 2    
    
    asm
                movdqu		xmm6,		[zeroReg]
                movdqu      xmm7,       [maskReg]

                mov         esi,        [src_pxls]
                mov         edi,        [dest_pxls]
                
                mov         eax,        [target_w]
                mov         ebx,        [target_h]
                    
        bitblt_prea_rows:
                
                mov         ecx,        eax

                cmp         ecx,        4
                jl          bitblt_prea_2pxls
                
        bitblt_prea_cols:
        
                movdqu		xmm0,		[esi]		
                movdqu		xmm4,		[edi]			
                
                MIX_STEP()	
                
                movdqu		[edi],		xmm2
               
                add         esi,        16
                add         edi,        16
                        
                sub			ecx,		4
                cmp         ecx,        4
                jge         bitblt_prea_cols
        
        bitblt_prea_2pxls:        
                
                test        ecx,        2
                jz          bitblt_prea_1pxls
 
                movq		xmm0,		[esi]		
                movq		xmm4,		[edi]
                
                MIX_STEP_HALF()
                
                movq        [edi],      xmm2

                add         esi,        8
                add         edi,        8
 
        bitblt_prea_1pxls:
        
                test        ecx,        1
                jz          bitblt_prea_nextRow
        
                movd        xmm0,       [esi]
                movd        xmm4,       [edi]
                
                MIX_STEP_HALF()
                
                movd        [edi],      xmm2
        
                add         esi,        4
                add         edi,        4 
                
        bitblt_prea_nextRow:
        
                add         esi,        [src_row_adv]
                add         edi,        [dest_row_adv]
                
                dec         ebx
                jnz         bitblt_prea_rows
        
    end asm                    
                    
end sub

sub bitblt_invertPset(dest as uinteger ptr,_
                      xpos as integer, ypos as integer,_
                      src  as uinteger ptr,_
                      src_x0 as integer, src_y0 as integer,_
                      src_x1 as integer, src_y1 as integer)       
                          
    #macro PLOT()
        movdqu      xmm1,       xmm2  
        psubusb     xmm1,       xmm0
    #endmacro

    dim as byte ptr dest_pxls, src_pxls
    dim as integer  dest_w, dest_h
    dim as integer  src_w, src_h
    dim as integer  target_w, target_h
    dim as integer  dest_row_adv, src_row_adv
    static as integer allOnes(0 to 3) = {&hffffffff, &hffffffff, &hffffffff, &hffffffff}
        
    imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
    imageinfo src,src_w,src_h,,src_row_adv,src_pxls
      

    dest_pxls += (xpos shl 2) + ypos*dest_row_adv
    src_pxls  += (src_x0 shl 2) + src_y0*src_row_adv
    
    target_w = (src_x1 - src_x0 + 1)
    target_h = (src_y1 - src_y0 + 1)
    
    if target_h < 1 then exit sub
    
    dest_row_adv -= target_w shl 2
    src_row_adv  -= target_w shl 2    

    asm
                movdqu      xmm2,       [allOnes]
                mov         esi,        [src_pxls]
                mov         edi,        [dest_pxls]
                
                mov         eax,        [target_w]
                mov         ebx,        [target_h]
                    
        bitblt_inv_rows:
                
                mov         ecx,        eax

                cmp         ecx,        4
                jl          bitblt_inv_2pxls
                
        bitblt_inv_cols:
        
                movdqu      xmm0,       [esi]
                PLOT()
                movdqu      [edi],      xmm1
                               
                add         esi,        16
                add         edi,        16
                        
                sub			ecx,		4
                cmp         ecx,        4
                jge         bitblt_inv_cols
        
        bitblt_inv_2pxls:        
                
                test        ecx,        2
                jz          bitblt_inv_1pxls
 
                movq        xmm0,       [esi]                
                PLOT()
                movq        [edi],      xmm1
                
                add         esi,        8
                add         edi,        8
 
        bitblt_inv_1pxls:
        
                test        ecx,        1
                jz          bitblt_inv_nextRow
        
                movd        xmm0,       [esi]                
                PLOT()
                movd        [edi],      xmm1
                        
                add         esi,        4
                add         edi,        4 
                
        bitblt_inv_nextRow:
        
                add         esi,        [src_row_adv]
                add         edi,        [dest_row_adv]
                
                dec         ebx
                jnz         bitblt_inv_rows
    end asm                       
                         
end sub

sub bitblt_trans_clip(dest as uinteger ptr,_
                      xpos_ as integer, ypos_ as integer,_
                      src  as uinteger ptr,_
                      src_x0_ as integer, src_y0_ as integer,_
                      src_x1_ as integer, src_y1_ as integer)    
             
             
    #macro PLOT()
        por         xmm0,       xmm7
        
        movdqa      xmm2,       xmm0
        pcmpeqd     xmm2,       xmm6
        pand        xmm1,       xmm2
        pandn       xmm2,       xmm0
        
        por         xmm2,       xmm1
    #endmacro

    dim as byte ptr dest_pxls, src_pxls
    dim as integer  dest_w, dest_h
    dim as integer  src_w, src_h
    dim as integer  target_w, target_h
    dim as integer  dest_row_adv, src_row_adv
    static as integer alphaMask(0 to 3) = {&hff000000, &hff000000, &hff000000, &hff000000}
    static as integer transPink(0 to 3) = {&hffff00ff, &hffff00ff, &hffff00ff, &hffff00ff}
    dim as integer  xpos, ypos
    dim as integer  src_x0, src_y0, src_x1, src_y1
        
    imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
    imageinfo src,src_w,src_h,,src_row_adv,src_pxls
      
    if anyClip(xpos_, ypos_, src_x1_ - src_x0_ + 1, src_y1_ - src_y0_ + 1, _
               0, 0, dest_w - 1, dest_h - 1,_
               xpos, ypos, src_x0, src_y0, src_x1, src_y1) then
  
        src_x0 += src_x0_
        src_y0 += src_y0_
        src_x1 += src_x0_
        src_y1 += src_y0_      
    
        imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
        imageinfo src,src_w,src_h,,src_row_adv,src_pxls
          
        dest_pxls += (xpos shl 2) + ypos*dest_row_adv
        src_pxls  += (src_x0 shl 2) + src_y0*src_row_adv

        target_w = (src_x1 - src_x0 + 1)
        target_h = (src_y1 - src_y0 + 1)

        if target_h < 1 then exit sub

        dest_row_adv -= target_w shl 2
        src_row_adv  -= target_w shl 2    

        asm
                    movdqu      xmm7,       [alphaMask]
                    movdqu      xmm6,       [transPink]
                    
                    mov         esi,        [src_pxls]
                    mov         edi,        [dest_pxls]
                    
                    mov         eax,        [target_w]
                    mov         ebx,        [target_h]
                        
            bitblt_trans_rows:
                    
                    mov         ecx,        eax

                    cmp         ecx,        4
                    jl          bitblt_trans_2pxls
                    
            bitblt_trans_cols:
            
                    movdqu      xmm0,       [esi]
                    movdqu      xmm1,       [edi]
                    PLOT()
                    movdqu      [edi],      xmm2
                                   
                    add         esi,        16
                    add         edi,        16
                            
                    sub			ecx,		4
                    cmp         ecx,        4
                    jge         bitblt_trans_cols
            
            bitblt_trans_2pxls:        
                    
                    test        ecx,        2
                    jz          bitblt_trans_1pxls

                    movq        xmm0,       [esi]  
                    movq        xmm1,       [edi]                
                    PLOT()
                    movq        [edi],      xmm2
                    
                    add         esi,        8
                    add         edi,        8

            bitblt_trans_1pxls:
            
                    test        ecx,        1
                    jz          bitblt_trans_nextRow
            
                    movd        xmm0,       [esi]     
                    movd        xmm1,       [edi]                
                    PLOT()
                    movd        [edi],      xmm2
                            
                    add         esi,        4
                    add         edi,        4 
                    
            bitblt_trans_nextRow:
            
                    add         esi,        [src_row_adv]
                    add         edi,        [dest_row_adv]
                    
                    dec         ebx
                    jnz         bitblt_trans_rows
        end asm                       
    end if              
end sub

sub bitblt_addRGBA_Clip(dest as uinteger ptr,_
                        xpos_ as integer, ypos_ as integer,_
                        src  as uinteger ptr,_
                        src_x0_ as integer, src_y0_ as integer,_
                        src_x1_ as integer, src_y1_ as integer)
           
    #macro PLOT()
        paddusb     xmm0,       xmm1    
    #endmacro

    dim as byte ptr dest_pxls, src_pxls
    dim as integer  dest_w, dest_h
    dim as integer  src_w, src_h
    dim as integer  target_w, target_h
    dim as integer  dest_row_adv, src_row_adv
    dim as integer  xpos, ypos
    dim as integer  src_x0, src_y0, src_x1, src_y1
        
    imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
    imageinfo src,src_w,src_h,,src_row_adv,src_pxls
      
    if anyClip(xpos_, ypos_, src_x1_ - src_x0_ + 1, src_y1_ - src_y0_ + 1, _
               0, 0, dest_w - 1, dest_h - 1,_
               xpos, ypos, src_x0, src_y0, src_x1, src_y1) then
  
        src_x0 += src_x0_
        src_y0 += src_y0_
        src_x1 += src_x0_
        src_y1 += src_y0_      
  
        dest_pxls += (xpos shl 2) + ypos*dest_row_adv
        src_pxls  += (src_x0 shl 2) + src_y0*src_row_adv
        
        target_w = (src_x1 - src_x0 + 1)
        target_h = (src_y1 - src_y0 + 1)
        
        if target_h < 1 then exit sub
        
        dest_row_adv -= target_w shl 2
        src_row_adv  -= target_w shl 2    
  
        asm
                    
                    mov         esi,        [src_pxls]
                    mov         edi,        [dest_pxls]
                    
                    mov         eax,        [target_w]
                    mov         ebx,        [target_h]
                        
            bitblt_arc_rows:
                    
                    mov         ecx,        eax

                    cmp         ecx,        4
                    jl          bitblt_arc_2pxls
                    
            bitblt_arc_cols:
            
                    movdqu      xmm0,       [esi]
                    movdqu      xmm1,       [edi]
                    PLOT()
                    movdqu      [edi],      xmm0
                                   
                    add         esi,        16
                    add         edi,        16
                            
                    sub			ecx,		4
                    cmp         ecx,        4
                    jge         bitblt_arc_cols
            
            bitblt_arc_2pxls:        
                    
                    test        ecx,        2
                    jz          bitblt_arc_1pxls
     
                    movq        xmm0,       [esi]
                    movq        xmm1,       [edi]
                    
                    PLOT()
                    
                    movq        [edi],      xmm0
                    
                    add         esi,        8
                    add         edi,        8
     
            bitblt_arc_1pxls:
            
                    test        ecx,        1
                    jz          bitblt_arc_nextRow
            
                    movd        xmm0,       [esi]
                    movd        xmm1,       [edi]
                    
                    PLOT()
                    
                    movd        [edi],      xmm0
                            
                    add         esi,        4
                    add         edi,        4 
                    
            bitblt_arc_nextRow:
            
                    add         esi,        [src_row_adv]
                    add         edi,        [dest_row_adv]
                    
                    dec         ebx
                    jnz         bitblt_arc_rows
        end asm                       
                          
    end if         
end sub

sub bitblt_transMulMix(dest as uinteger ptr,_
                       xpos as integer, ypos as integer,_
                       src  as uinteger ptr,_
                       src_x0 as integer, src_y0 as integer,_
                       src_x1 as integer, src_y1 as integer,_
                       mixColor as integer = &h00000000)

    #macro MIX_STEP()
        movdqa      xmm2,       xmm0
        movhlps		xmm1,		xmm0   
        punpcklbw 	xmm0, 		xmm6
		punpcklbw 	xmm1, 		xmm6
            
        pmullw      xmm0,       xmm7
        pmullw      xmm1,       xmm7
        psrlw		xmm0, 		8
        psrlw		xmm1, 		8
   
        packuswb	xmm0,		xmm1
   
        pcmpeqd     xmm2,       xmm5
        
        pand        xmm4,       xmm2
        pandn       xmm2,       xmm0
        por         xmm2,       xmm4        
    #endmacro
    
    #macro MIX_STEP_HALF()
        movdqa      xmm2,       xmm0
        punpcklbw 	xmm0, 		xmm6
            
        pmullw      xmm0,       xmm7
        psrlw		xmm0, 		8
   
        packuswb	xmm0,		xmm0
   
        pcmpeqd     xmm2,       xmm5
        
        pand        xmm4,       xmm2
        pandn       xmm2,       xmm0
        por         xmm2,       xmm4     
    #endmacro
    
	static as integer zeroReg(0 to 3) = {&h00000000, &h00000000, &h00000000, &h00000000}    
    static as integer col_offset(0 to 3)
    static as integer trans_color(0 to 3) = {&hffff00ff, &hffff00ff, &hffff00ff, &hffff00ff}
    
    dim as byte ptr dest_pxls, src_pxls
    dim as integer  dest_w, dest_h
    dim as integer  src_w, src_h
    dim as integer  target_w, target_h
    dim as integer  dest_row_adv, src_row_adv
    
    imageinfo dest,dest_w,dest_h,,dest_row_adv,dest_pxls
    imageinfo src,src_w,src_h,,src_row_adv,src_pxls
    
    dest_pxls += (xpos shl 2) + ypos*dest_row_adv
    src_pxls  += (src_x0 shl 2) + src_y0*src_row_adv
    
    target_w = (src_x1 - src_x0 + 1)
    target_h = (src_y1 - src_y0 + 1)
    
    if target_h < 1 then exit sub
    
    dest_row_adv -= target_w shl 2
    src_row_adv  -= target_w shl 2    
   
	col_offset(0) = (mixColor and &hff) or ((mixColor and &hff00) shl 8)
	col_offset(1) = ((mixColor and &hff0000) shr 16) or ((mixColor and &hff000000) shr 8)
    col_offset(2) = col_offset(0)
    col_offset(3) = col_offset(1)
    
    asm
                movdqu      xmm5,       [trans_color]
                movdqu		xmm6,		[zeroReg]
                movdqu      xmm7,       [col_offset]
                
                mov         esi,        [src_pxls]
                mov         edi,        [dest_pxls]
                
                mov         eax,        [target_w]
                mov         ebx,        [target_h]
                    
        bitblt_tmm_rows:
                
                mov         ecx,        eax

                cmp         ecx,        4
                jl          bitblt_tmm_2pxls
                
        bitblt_tmm_cols:
        
                movdqu		xmm0,		[esi]		
                movdqu		xmm4,		[edi]			
                
                MIX_STEP()	
                               
                movdqu		[edi],		xmm2
                               
                add         esi,        16
                add         edi,        16
                        
                sub			ecx,		4
                cmp         ecx,        4
                jge         bitblt_tmm_cols
        
        bitblt_tmm_2pxls:        
                
                test        ecx,        2
                jz          bitblt_tmm_1pxls
 
                movq		xmm0,		[esi]		
                movq		xmm4,		[edi]
                
                MIX_STEP_HALF()
                
                movq		[edi],		xmm2
                
                add         esi,        8
                add         edi,        8
 
        bitblt_tmm_1pxls:
        
                test        ecx,        1
                jz          bitblt_tmm_nextRow
        
                movd        xmm0,       [esi]
                movd        xmm4,       [edi]
                
                MIX_STEP_HALF()
                
                movd		[edi],		xmm2
                        
                add         esi,        4
                add         edi,        4 
                
        bitblt_tmm_nextRow:
        
                add         esi,        [src_row_adv]
                add         edi,        [dest_row_adv]
                
                dec         ebx
                jnz         bitblt_tmm_rows
        
    end asm                       
                                        
      
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

function raycastImage(src as uinteger ptr, byref startx as integer, byref starty as integer,_
                      dirx as integer, diry as integer) as integer
                              
    dim as integer w, h, x, y, coff, pitch
	dim as integer ptr data_
	imageinfo src, w, h, , pitch, data_
	pitch shr= 2
	data_ += startx + starty * pitch 
    coff = diry*pitch + dirx
	while (startx >= 0) andALso (startx < w) andALso (starty >= 0) andAlso (starty < h) 
		if (*data_ and &h00ffffff) <> &h00ff00ff then return 1
        data_ += coff
		startx += dirx
        starty += diry
    wend
	return 0                                                    
end function

function compareTrans(src0 as uinteger ptr,_
					  src0_x as integer, src0_y as integer,_
					  src1 as uinteger ptr,_
					  src1_x as integer, src1_y as integer,_
					  w as integer, h as integer) as double
	dim as integer pitch0, pitch1
	dim as integer count
	dim as integer ptr data0_, data1_
	imageinfo src0, , , , pitch0, data0_
	imageinfo src1, , , , pitch1, data1_
	pitch0 shr= 2
	pitch1 shr= 2

	data0_ += src0_x + src0_y * pitch0
	data1_ += src1_x + src1_y * pitch1
	
	pitch0 = (pitch0 - w) shl 2
	pitch1 = (pitch1 - w) shl 2
		
	asm
		mov 	esi,					[data0_]
		mov		edi,					[data1_]
        mov     ecx,                    0
		
		ct_rows:
		
		mov		edx,					[w]

		ct_cols:
		
		mov     eax,                    [edi]
        cmp     eax,                    &hffff00ff
        je      skipAcc
        
        mov     eax,                    [esi]
        shr     eax,                    24
        
        add     ecx,                    eax
        
        skipAcc:
		
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
	
	return count / 255.0				  
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

function stripwhite(s as string) as string
    dim as integer i, quoteLevel
    dim as string ret, curChar
    ret = ""
    quoteLevel = 0
    for i = 1 to len(s)
        curChar = mid(s, i, 1)
        if curChar = "'" then quoteLevel = 1 - quoteLevel
        if quoteLevel = 0 then
            if (curChar <> " ") andAlso (curChar <> "\t") then ret += curChar
        else
            ret += curChar
        end if
    next i
    return ret
end function

sub pmapFix(byref x as integer, byref y as integer)
    dim as double x_r, y_r
    x_r = x
    y_r = y
    x_r = pmap(x_r, 0)
    y_r = pmap(y_r, 1)
    #ifndef SCALE_ELLIOTT
        #ifdef SCALE_2X
            x = x_r / 2
            y = y_r / 2
        #else
            x = x_r
            y = y_r
        #endif
    #else
        x = x_r / 1.25
        y = y_r / 1.25
    #endif
    'if x > SCRX*0.5 then x -= 1
    'if y > SCRY*0.5 then y -= 1
end sub

function pmapFixV(v as Vector2D) as Vector2D
    dim as double x_r, y_r
    dim as Vector2D vr
    x_r = v.xs
    y_r = v.ys
    x_r = pmap(x_r, 0)
    y_r = pmap(y_r, 1)
    #ifndef SCALE_ELLIOTT
        #ifdef SCALE_2X
            vr.xs = int(x_r / 2.0)
            vr.ys = int(y_r / 2.0)
        #else
            vr.xs = x_r
            vr.ys = y_r
        #endif
    #else
        vr.xs = int(x_r / 1.25)
        vr.ys = int(y_r / 1.25)
    #endif
    if vr.xs > int(SCRX*0.5) then vr.xs -= 1
    if vr.ys > int(SCRY*0.5) then vr.ys -= 1
    return vr
end function

function AnyClip(px as integer, py as integer ,_
                 sx as integer, sy as integer ,_
                 btl_x as integer, btl_y as integer,_
                 bbr_x as integer, bbr_y as integer,_
                 byref npx  as integer, byref npy  as integer ,_
                 byref sdx1 as integer, byref sdy1 as integer ,_
                 byref sdx2 as integer, byref sdy2 as integer) as integer
    Dim as integer px1,py1,px2,py2
    dim as integer bbx1, bbx2, bby1, bby2   
   
    px1 = px       : py1 = py
    px2 = px+sx - 1: py2 = py+sy - 1
    
    If px2 < btl_x Then Return 0
    If px1 > bbr_x Then Return 0
    If py2 < btl_y Then Return 0
    If py1 > bbr_y Then Return 0
    
    bbx1 = iif(px1 < btl_x, btl_x, px1)
    bby1 = iif(py1 < btl_y, btl_y, py1)
    bbx2 = iif(px2 > bbr_x, bbr_x, px2)
    bby2 = iif(py2 > bbr_y, bbr_y, py2)
    
    npx  = bbx1
    npy  = bby1
    sdx1 = bbx1 - px1
    sdy1 = bby1 - py1
    sdx2 = sx - (px2 - bbx2) - 1
    sdy2 = sy - (py2 - bby2) - 1

    Return 1             
                 
end function

Function ScreenClip(px as integer, py as integer ,_
                    sx as integer, sy as integer ,_
                    byref npx  as integer, byref npy  as integer ,_
                    byref sdx1 as integer, byref sdy1 as integer ,_
                    byref sdx2 as integer, byref sdy2 as integer ,_
                    nx as integer, ny as integer) as integer
    Dim as integer px1,py1,px2,py2,SW,SH
    dim as integer bbx1, bbx2, bby1, bby2
    if nx = -1 then
        SW = SCRX
    else
        SW = nx
    end if
    if ny = -1 then
        SH = SCRY
    else
        SH = ny
    end if
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
    dim as integer dx, dy, x, y, c
    c = 0
    x = px
    rad *= rad
    if x < x1 then
        x = x1
        c = 1
    elseif x > x2 then
        x = x2
        c = 1
    end if
    x = x - px
    x *= x
    dy = y1 - py
    dy *= dy
    if x + dy <= rad then return 1
    dy = y2 - py
    dy *= dy
    if x + dy <= rad then return 1
    y = py
    if y < y1 then
        y = y1
        c = 1
    elseif y > y2 then
        y = y2 
        c = 1
    end if
    y = y - py
    y *= y
    dx = x1 - px
    dx *= dx
    if y + dx <= rad then return 1
    dx = x2 - px
    dx *= dx
    if y + dx <= rad then return 1
    if c = 0 then return 1
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

sub allocateAlligned(byref basePtr as any ptr, byref allignedPtr as any ptr, bytes as integer)
    #define ALLIGNMENT 16
    
    basePtr     = allocate(bytes + (sizeof(byte) * (ALLIGNMENT - 1)))
    allignedPtr = cast(integer ptr, (cast(integer, basePtr) + ALLIGNMENT) _
                  and (not (ALLIGNMENT - 1)))
                  
end sub

function lineCircleCollision(p as Vector2D, r as double, a as Vector2D, b as Vector2D, byref ret1 as vector2D, byref ret2 as vector2D) as integer
    dim as Vector2D dl, dr
    dim as double x0, x1, x2
    dim as double disc, t1, t2
    
    dl = b - a
    dr = a - p
    x0 = dl*dl
    x1 = 2*(dl*dr)
    x2 = dr*dr - r*r
    
    disc = x1*x1 - 4*x0*x2
    
    if disc < 0 then 
        return 0
    else
        disc = sqr(disc)
        t1 = (-x1 - disc) / (2*x0)
        t2 = (-x1 + disc) / (2*x0)
        
        if (t1 >= 0) andAlso (t1 <= 1) then
            if (t2 >= 0) andAlso (t2 <= 1) then
                ret1 = t1*dl + a
                ret2 = t2*dl + a
                return 2
            else
                ret1 = t1*dl + a
                return 1
            end if
        elseif (t2 >= 0) andAlso (t2 <= 1) then
            ret1 = t2*dl + a
            return 1
        else
            return 0
        end if
    end if

end function

function angDist(a as double, b as double) as double
    dim as double ret

    ret = b - a
    if ret > _PI_ then 
        ret -= 2*_PI_
    elseif ret < -_PI_ then
        ret += 2*_PI_
    end if
    
    return ret
end function

function windowCircleIntersect(tl as Vector2d, br as Vector2d,_
                               p as Vector2d, r as double, byref ret as windowCircleIntersectData_t) as integer
                          
    #macro TEST_ADD_LINE(_A_, _B_)
        npts = lineCircleCollision(p, r, _A_, _B_, ptA, ptB)
        if npts > 0 then
            p_list(p_list_N) = ptA: p_list_N += 1
        end if
        if npts > 1 then
            p_list(p_list_N) = ptB: p_list_N += 1
        end if
    #endmacro
    
    dim as double dx, dy, nx, ny
    dim as Vector2D p_list(0 to 7), ptA, ptB, m
    dim as Vector2D minP, maxP, nTl, nBr
    dim as double p_listAngles(0 to 7)
    dim as integer p_list_N, p_listAngles_N, npts, i, highI, lowI
    
    if circleBox(p.x, p.y, r, tl.x, tl.y, br.x, br.y) then
        if (p.x >= tl.x) andAlso (p.y >= tl.y) andAlso (p.x <= br.x) andALso (p.y <= br.y) then
            ret.tl_x = _max_(tl.x, p.x - r)
            ret.tl_y = _max_(tl.y, p.y - r)
            ret.br_x = _min_(br.x, p.x + r)
            ret.br_y = _min_(br.y, p.y + r)           
            ret.dx0 = 0: ret.dy0 = 0
            ret.dx1 = 0: ret.dy1 = 0
        else
            p_list_N = 0
            
            TEST_ADD_LINE(Vector2D(tl.x, tl.y), Vector2D(br.x, tl.y))
            TEST_ADD_LINE(Vector2D(br.x, tl.y), Vector2D(br.x, br.y))
            TEST_ADD_LINE(Vector2D(br.x, br.y), Vector2D(tl.x, br.y))
            TEST_ADD_LINE(Vector2D(tl.x, br.y), Vector2D(tl.x, tl.y))
            m = Vector2D(tl.x, tl.y) - p
            if m.magnitude() < r then 
                p_list(p_list_N) = Vector2D(tl.x, tl.y): p_list_N += 1
            end if
            m = Vector2D(br.x, tl.y) - p
            if m.magnitude() < r then 
                p_list(p_list_N) = Vector2D(br.x, tl.y): p_list_N += 1
            end if
            m = Vector2D(br.x, br.y) - p
            if m.magnitude() < r then 
                p_list(p_list_N) = Vector2D(br.x, br.y): p_list_N += 1
            end if
            m = Vector2D(tl.x, br.y) - p
            if m.magnitude() < r then 
                p_list(p_list_N) = Vector2D(tl.x, br.y): p_list_N += 1
            end if
            
            p_listAngles_N = p_list_N
            highI = 0
            lowI = 0
            for i = 0 to p_listAngles_N - 1
                p_listAngles(i) = atan2(p_list(i).y - p.y, p_list(i).x - p.x)
                if angDist(p_listAngles(i), p_listAngles(highI)) < 0 then highI = i
                if angDist(p_listAngles(i), p_listAngles(lowI)) > 0  then lowI = i
            next i
            
            minP = p_list(lowI)
            maxP = p_list(highI)
   
            nTl = Vector2D(_min_(_min_(minP.x, maxP.x), p.x), _min_(_min_(minP.y, maxP.y), p.y))
            nBr = Vector2D(_max_(_max_(minP.x, maxP.x), p.x), _max_(_max_(minP.y, maxP.y), p.y))
            
            if p.y < tl.y then
                if (p.x >= tl.x) andAlso (p.x <= br.x) then
                    nBr = Vector2D(nBr.x, _min_(p.y + r, br.y))
                end if
            elseif p.y > br.y then
                if (p.x >= tl.x) andAlso (p.x <= br.x) then
                    nTl = Vector2D(nTl.x, _max_(p.y - r, tl.y))
                end if    
            elseif p.x < tl.x then
                if (p.y >= tl.y) andAlso (p.y <= br.y) then
                    nBr = Vector2D(_min_(p.x + r, br.x), nBr.y)
                end if                
            elseif p.x > br.x then
                if (p.y >= tl.y) andAlso (p.y <= br.y) then
                    nTl = Vector2D(_max_(p.x - r, tl.x), nTl.y)
                end if                  
            end if
           
            ret.tl_x = nTl.x
            ret.tl_y = nTl.y
            ret.br_x = nBr.x
            ret.br_y = nBr.y
            ret.dx0 = minP.x - p.x: ret.dy0 = minP.y - p.y
            ret.dx1 = maxP.x - p.x: ret.dy1 = maxP.y - p.y
   
        end if
    else
        return 0
    end if  
    return 1
end function

sub imageSet(fbimg_ptr as integer ptr, value as integer, _
             tl_x as integer,_
             tl_y as integer,_
             br_x as integer,_
             br_y as integer)
    
    static as integer col_offset(0 to 3)
    dim as any ptr pxls
    dim as integer stride, offset, cols, rows
    
    imageinfo fbimg_ptr,,,,stride, pxls
    pxls = pxls + (stride*tl_y) + (tl_x shl 2)
    
    cols = br_x - tl_x + 1
    stride -= (cols shl 2)
    
    rows = br_y - tl_y + 1

    col_offset(0) = value
    col_offset(1) = value
    col_offset(2) = value
    col_offset(3) = value
    
    asm
        
            movdqu      xmm0,       [col_offset]
            mov         edi,        [pxls]      
            mov         ecx,        [rows]
            mov         edx,        [stride]
        
        imageSet_rows:
        
            mov         ebx,        [cols]
    
        imageSet_startCopyCols4:
            cmp         ebx,        4
            jl          imageSet_endCopyCols4
                
            movdqu      [edi],      xmm0
            
            add         edi,        16
            sub         ebx,        4
            jmp         imageSet_startCopyCols4
        imageSet_endCopyCols4:
        
            cmp         ebx,        2
            jl          imageSet_endCopyCols2
                
            movq        [edi],      xmm0
            
            add         edi,        8
            sub         ebx,        2
        imageSet_endCopyCols2:
        
            cmp         ebx,        1
            jl          imageSet_endCopyCols1
                
            movd        [edi],      xmm0
            
            add         edi,        4
            sub         ebx,        1
        imageSet_endCopyCols1:
        
            add         edi,        edx
            dec         ecx
            
            jnz         imageSet_rows
        
    end asm

end sub
             
Sub pointCastTexture(dest1 as integer ptr, dest2 as integer ptr,_
                     source1 As Integer Ptr, source2 as integer ptr,_
                     occlude as Integer ptr, _
                     tl_x as integer, tl_y as integer,_
                     br_x as integer, br_y as integer,_
                     dx0 as integer, dy0 as integer,_
                     dx1 as integer, dy1 as integer,_
                     xp As Integer, yp As Integer,_
                     rad As integer, tcol As Integer = &HFF000000, memoryPool as integer ptr = 0)
              
    'may hit the skids when image pitch is not in words 
    
    #define _Ek 0
    #define _Dn 1
    #define _Dp 2
    #define _Xd 3
    #define _Xx 4
        
    #define SEARCH_LOOP 0
    #define FILL_LOOP 1
    
    #define RR2 0.70710678118654
    
    #define MAX_DWORDS 512

    #define ShadowsA(_I_, _P_) readList[(_I_)*5 + _P_]
    #define ShadowsB(_I_, _P_) writeList[(_I_)*5 + _P_]

    #macro _addelement(a)
        ShadowsB(_N,_Xx) = a: ShadowsB(_N,_Xd) = Sgn(dx)
        dx = Abs(dx): dy = Abs(dy)
        ShadowsB(_N,_Ek) = dx SHL 1 - dy
        ShadowsB(_N,_Dn) = ShadowsB(_N,_Ek) + dy
        ShadowsB(_N,_Dp) = ShadowsB(_N,_Ek) - dy
        _N += 1
    #endmacro
    
    #macro _copyelement(x)
        ShadowsB(_N,_Ek) = ShadowsA(x,_Ek)
        ShadowsB(_N,_Dn) = ShadowsA(x,_Dn)
        ShadowsB(_N,_Dp) = ShadowsA(x,_Dp)
        ShadowsB(_N,_Xx) = ShadowsA(x,_Xx)
        ShadowsB(_N,_Xd) = ShadowsA(x,_Xd)
        _N += 1
    #endmacro
    
    #macro _copylist()
        swap readList, writeList
    #endmacro
        
    dim as integer ptr readList, writeList, Sptr, tex, Sptr2, tex2, occPxls
    Dim As Integer inc, scan, xs, xe, yend = rad*RR2, xcirc, dx, dy, s1, s2, prad, oxs, oxe, txe
    Dim As Integer xpos, ypos, segs, i, _N, ccol, LeftBnd, RightBnd, Offset, yadd,q
    Dim As integer proc, checkAddr, cind, srcW, srcH, sourceStride, texOffset, texCurOffset
    Dim As Integer QuadBnd(0 To 7, 0 To 3), WorkCol, destW, destH, destStride, texCenter
    dim as integer skipQuad, fquad, equad
    redim as integer CurveOff(0)
    
    imageinfo dest1, destW, destH,, destStride, Sptr 
    imageinfo dest2,,,,, Sptr2 

    imageinfo source1, srcW, srcH,, sourceStride, tex
    imageinfo source2,,,,, tex2
    
    imageinfo occlude,,,,,occPxls
    
    sourceStride shr=2
    destStride shr= 2
    
    skipQuad = 0
    
    if memoryPool = 0 then
        readList  = new integer[MAX_DWORDS]
        writeList = new integer[MAX_DWORDS]
    else
        readList = memoryPool
        writeList = @(memoryPool[MAX_DWORDS])
    end if
    
    texCenter = (srcW*0.5) + (srcH*0.5)*sourceStride
    
    fquad = -1
    equad = -1
    if (dy0 < 0) andAlso (abs(dy0) > abs(dx0)) then
        fquad = 0
    elseif (dx0 > 0) andAlso (abs(dx0) > abs(dy0)) then
        fquad = 1
    elseif (dy0 > 0) andAlso (abs(dy0) > abs(dx0)) then
        fquad = 2
    elseif (dx0 < 0) andAlso (abs(dx0) > abs(dy0)) then
        fquad = 3
    end if
    if (dy1 < 0) andAlso (abs(dy1) > abs(dx1)) then
        equad = 0
    elseif (dx1 > 0) andAlso (abs(dx1) > abs(dy1)) then
        equad = 1
    elseif (dy1 > 0) andAlso (abs(dy1) > abs(dx1)) then
        equad = 2
    elseif (dx1 < 0) andAlso (abs(dx1) > abs(dy1)) then
        equad = 3
    end if
    skipQuad = 0
    QuadBnd(0,_Ek) = 1: QuadBnd(0,_Dn) = 2: QuadBnd(0,_Dp) = 0: QuadBnd(0,_Xd) = -1
    QuadBnd(1,_Ek) = 1: QuadBnd(1,_Dn) = 2: QuadBnd(1,_Dp) = 0: QuadBnd(1,_Xd) =  1
    QuadBnd(2,_Ek) = 1: QuadBnd(2,_Dn) = 2: QuadBnd(2,_Dp) = 0: QuadBnd(2,_Xd) = -1
    QuadBnd(3,_Ek) = 1: QuadBnd(3,_Dn) = 2: QuadBnd(3,_Dp) = 0: QuadBnd(3,_Xd) =  1
    QuadBnd(4,_Ek) = 1: QuadBnd(4,_Dn) = 2: QuadBnd(4,_Dp) = 0: QuadBnd(4,_Xd) =  1
    QuadBnd(5,_Ek) = 1: QuadBnd(5,_Dn) = 2: QuadBnd(5,_Dp) = 0: QuadBnd(5,_Xd) = -1
    QuadBnd(6,_Ek) = 1: QuadBnd(6,_Dn) = 2: QuadBnd(6,_Dp) = 0: QuadBnd(6,_Xd) =  1
    QuadBnd(7,_Ek) = 1: QuadBnd(7,_Dn) = 2: QuadBnd(7,_Dp) = 0: QuadBnd(7,_Xd) = -1
    
    if (fquad <> -1) andAlso (equad <> -1) then

        if (fquad = 0) orElse (fquad = 2) then
            dx = dx0
            dy = dy0
        else
            dx = dy0
            dy = dx0        
        end if 
               
        QuadBnd(fquad*2,_Xd) = Sgn(dx)
        dx = Abs(dx)
        dy = Abs(dy)
        QuadBnd(fquad*2,_Ek) = dx shl 1 - dy
        QuadBnd(fquad*2,_Dn) = QuadBnd(fquad*2,_Ek) + dy
        QuadBnd(fquad*2,_Dp) = QuadBnd(fquad*2,_Ek) - dy

        
        if (equad = 0) orElse (equad = 2) then
            dx = dx1
            dy = dy1
        else
            dx = dy1
            dy = dx1        
        end if 
        QuadBnd(equad*2 + 1,_Xd) = Sgn(dx)
        dx = Abs(dx)
        dy = Abs(dy)
        QuadBnd(equad*2 + 1,_Ek) = dx shl 1 - dy
        QuadBnd(equad*2 + 1,_Dn) = QuadBnd(equad*2 + 1,_Ek) + dy
        QuadBnd(equad*2 + 1,_Dp) = QuadBnd(equad*2 + 1,_Ek) - dy
        
        equad = (equad + 1) mod 4
        do
            skipQuad = skipQuad or (1 shl equad)
            equad = (equad + 1) mod 4
        loop until equad = fquad
        
    end if
    
    prad = rad-yend
    redim as integer CurveOff(0 to prad-1)
    dx = 0
    dy = Rad
    xs = 1 - Rad
    i = prad
    Do
        If xs < 0 Then
            xs += dx SHL 1 + 3
        Else
            xs += (dx - dy) SHL 1 + 5
            CurveOff(i - 1) = dx
            dy -= 1
            i -= 1
        End If
        dx += 1
    Loop Until i = 0
    '-------------------------------------------------QUAD 1---------------------------------------
    
    if (yp >= tl_y) andAlso (yp <= br_y) andAlso (xp >= tl_x) andALso (xp <= br_x) then
        checkAddr = yp*sourceStride+xp
        if occPxls[checkAddr] = tcol then
            checkAddr = yp*destStride+xp
            Sptr[checkAddr] = tex[texCenter]
            Sptr2[checkAddr] = tex2[texCenter]
        else
            exit sub
        end if
    else
        exit sub
    end if
    
    if yp > tl_y andAlso ((skipQuad and 1) = 0) then
        ShadowsA(0,_Ek) = QuadBnd(0,_Ek): ShadowsA(0,_Dn) = QuadBnd(0,_Dn): ShadowsA(0,_Dp) = QuadBnd(0,_Dp)
        ShadowsA(0,_Xx) = xp: ShadowsA(0,_Xd) = QuadBnd(0,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(1,_Ek): ShadowsA(1,_Dn) = QuadBnd(1,_Dn): ShadowsA(1,_Dp) = QuadBnd(1,_Dp)
        ShadowsA(1,_Xx) = xp: ShadowsA(1,_Xd) = QuadBnd(1,_Xd)
        _N = 2
        texOffset = texCenter
        yadd = yp * destStride
        If yp - rad < tl_y Then 
            prad = yp - tl_y 
        Else
            prad = rad
        End if
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = xp + CurveOff(xcirc)
                LeftBnd  = xp - CurveOff(xcirc)
            Else
                RightBnd = xp + inc - 1
                LeftBnd  = xp - inc
            End if
            If RightBnd > br_x Then RightBnd = br_x
            If LeftBnd  < tl_x Then LeftBnd  = tl_x
            ypos = yp - inc
            yadd -= destStride
            texOffset -= sourceStride
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                
                s1 = i
                s2 = i + 1

                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe < LeftBnd Then 
                    Goto SkipScanQ1
                Elseif xs > RightBnd andAlso _N > 2 Then
                    Goto SkipScanQ1
                Elseif xs < LeftBnd Then
                    xs = LeftBnd
                End if
                
                txe = xe
                If xe > RightBnd Then xe = RightBnd
                        
                If (xs - oxs) < 0 then
                    if (occPxls[yadd+xs+1] <> tcol) andAlso (occPxls[yadd+xs+destStride] <> tcol) then
                        xs += 1
                    end if
                end if
                If (txe - oxe) > 0 andAlso xe > 0 then
                    if (occPxls[yadd+xe-1] <> tcol) andAlso (occPxls[yadd+xe+destStride] <> tcol) then
                        xe -= 1
                    end if
                end if
                
                if xe < xs andAlso _N > 2 then goto SkipScanQ1

                xpos = xs
                texCurOffset = texOffset + (xs - xp)
                If occPxls[yadd+xpos] <> tcol Then
                    Do
                        xpos += 1
                        texCurOffset += 1
                        If xpos >= xe Then Goto SkipScanQ1
                        ccol = occPxls[yadd+xpos]
                        If ccol = tcol Then
                            If xpos < xe Then
                                dx = xpos-xp: dy = inc
                                _addelement(xpos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                                Sptr2[yadd+xpos] = tex2[texCurOffset]                                
                            End if
                            Exit Do
                        End if
                    Loop
                Else
                    _copyelement(s1)
                End if
                
                proc = FILL_LOOP
                
                Do
                    if proc = FILL_LOOP then
                        If occPxls[yadd+xpos] <> tcol Then
                            dx = xpos-xp-1: dy = inc
                            _addelement(xpos-1)
                            proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]  
                        End if
                    else
                        If occPxls[yadd+xpos] = tcol Then
                            dx = xpos-xp: dy = inc 
                            _addelement(xpos)
                            Proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]  
                        End if
                    end if
                    xpos += 1
                    texCurOffset += 1
                Loop until xpos > xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if
                SkipScanQ1:    
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
    end if
    
    '----------------------------------------------------QUAD 2------------------------------------
    
    if xp < br_x andAlso ((skipQuad and 2) = 0) then
        
        ShadowsA(0,_Ek) = QuadBnd(2,_Ek): ShadowsA(0,_Dn) = QuadBnd(2,_Dn): ShadowsA(0,_Dp) = QuadBnd(2,_Dp)
        ShadowsA(0,_Xx) = yp: ShadowsA(0,_Xd) = QuadBnd(2,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(3,_Ek): ShadowsA(1,_Dn) = QuadBnd(3,_Dn): ShadowsA(1,_Dp) = QuadBnd(3,_Dp)
        ShadowsA(1,_Xx) = yp: ShadowsA(1,_Xd) = QuadBnd(3,_Xd)
        _N = 2
        texOffset = texCenter
        If xp + rad > br_x Then
            prad = br_x - xp
        Else
            prad = rad
        Endif
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = yp + CurveOff(xcirc)
                LeftBnd  = yp - CurveOff(xcirc)
            Else
                RightBnd = yp + inc - 1
                LeftBnd  = yp - inc
            Endif
            If RightBnd > br_y Then RightBnd = br_y
            If LeftBnd  < tl_y Then LeftBnd  = tl_y
            xpos = xp + inc
            texOffset += 1
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2               
                s1 = i
                s2 = i + 1
                
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe < LeftBnd Then 
                    Goto SkipScanQ2
                Elseif xs > RightBnd andAlso _N > 2 Then
                    Goto SkipScanQ2
                Elseif xs < LeftBnd Then
                    xs = LeftBnd
                End if
                txe = xe
                If xe > RightBnd Then xe = RightBnd
                
                
                If (xs - oxs) < 0 then
                    checkAddr = xs*destStride + xpos
                    if (occPxls[checkAddr + destStride] <> tcol) andAlso (occPxls[checkAddr - 1] <> tcol) then
                        xs += 1
                    end if
                end if
                
                If (txe - oxe) > 0 andAlso xe > 0 then
                    checkAddr = xe*destStride + xpos
                    if (occPxls[checkAddr - destStride] <> tcol) andAlso (occPxls[checkAddr - 1] <> tcol) then
                        xe -= 1
                    end if
                end if                
                
                if xe < xs andAlso _N > 2 then goto SkipScanQ2
                
                ypos = xs
                yadd = xs * destStride
                texCurOffset = texOffset + (xs - yp)*sourceStride
                If occPxls[yadd+xpos] <> tcol Then
                    Do
                        ypos += 1
                        yadd += destStride
                        texCurOffset += sourceStride
                        If ypos >= xe Then Goto SkipScanQ2
                        ccol = occPxls[yadd+xpos]
                        If ccol = tcol Then
                            If ypos < xe Then
                                dx = ypos-yp: dy = inc
                                _addelement(ypos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                                Sptr2[yadd+xpos] = tex2[texCurOffset]
                            End if
                            Exit Do
                        End if
                    Loop
                Else
                    _copyelement(s1)
                End if

                proc = FILL_LOOP
                Do
                    if proc = FILL_LOOP then
                        If occPxls[yadd+xpos] <> tcol Then
                            dx = ypos-yp-1: dy = inc
                            _addelement(ypos-1)
                            proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]
                        End if 
                    else
                        If occPxls[yadd+xpos] = tcol Then
                            dx = ypos-yp: dy = inc
                            _addelement(ypos)
                            proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]
                        End if
                    end if
                    ypos += 1
                    yadd += destStride
                    texCurOffset += sourceStride
                Loop until ypos > xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if

                SkipScanQ2:
            Next i
        
            If _N = 0 Then Exit For
            _copylist()
            
        Next inc
    end if
    

    '------------------------------------------------QUAD 3---------------------------------------
    if yp < br_y andAlso ((skipQuad and 4) = 0) then
        ShadowsA(0,_Ek) = QuadBnd(4,_Ek): ShadowsA(0,_Dn) = QuadBnd(4,_Dn): ShadowsA(0,_Dp) = QuadBnd(4,_Dp)
        ShadowsA(0,_Xx) = xp: ShadowsA(0,_Xd) = QuadBnd(4,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(5,_Ek): ShadowsA(1,_Dn) = QuadBnd(5,_Dn): ShadowsA(1,_Dp) = QuadBnd(5,_Dp)
        ShadowsA(1,_Xx) = xp: ShadowsA(1,_Xd) = QuadBnd(5,_Xd)
        texOffset = texCenter
        yadd = yp * destStride
        If yp + rad > br_y Then
            prad = br_y - yp
        Else
            prad = rad
        End if
        _N = 2
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = xp + CurveOff(xcirc)
                LeftBnd  = xp - CurveOff(xcirc)
            Else
                RightBnd = xp + inc
                LeftBnd  = xp - inc + 1
            End if
            If RightBnd > br_x Then RightBnd = br_x
            If LeftBnd  < tl_x Then LeftBnd  = tl_x
            ypos = yp + inc
            yadd += destStride
            texOffset += sourceStride
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                
                s1 = i
                s2 = i + 1
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe > RightBnd Then 
                    Goto SkipScanQ3
                Elseif xs < LeftBnd andAlso _N > 2 Then
                    Goto SkipScanQ3
                Elseif xs > RightBnd Then
                    xs = RightBnd
                End if
                
                txe = xe
                If xe < LeftBnd Then xe = LeftBnd
                
                If (xs - oxs) > 0 andalso xs > 0 then
                    if (occPxls[yadd+xs-1] <> tcol) andAlso (occPxls[yadd+xs-destStride] <> tcol) then
                        xs -= 1
                    end if
                end if
                If (txe - oxe) < 0 then
                    if (occPxls[yadd+xe+1] <> tcol) andAlso (occPxls[yadd+xe-destStride] <> tcol) then
                        xe += 1
                    end if
                end if
                
                if xe > xs andALso _N > 2 then goto SkipScanQ3

                xpos = xs
                texCurOffset = texOffset + (xs - xp)
                If occPxls[yadd+xpos] <> tcol Then
                    Do
                        xpos -= 1
                        texCurOffset -= 1
                        If xpos <= xe Then Goto SkipScanQ3
                        ccol = occPxls[yadd+xpos]
                        If ccol = tcol Then
                            If xpos > xe Then
                                dx = xpos-xp: dy = inc
                                _addelement(xpos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                                Sptr2[yadd+xpos] = tex2[texCurOffset]                                
                            End if
                            Exit Do
                        End if
                    Loop
                Else
                    _copyelement(s1)
                End if
                
                proc = FILL_LOOP
                Do
                    if proc = FILL_LOOP then
                        If occPxls[yadd+xpos] <> tcol Then
                            dx = xpos-xp+1: dy = inc
                            _addelement(xpos+1)
                            proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]                          
                        End if
                    else
                        If occPxls[yadd+xpos] = tcol Then
                            dx = xpos-xp: dy = inc 
                            _addelement(xpos)
                            proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]                            
                        End if                   
                    end if
                    xpos -= 1
                    texCurOffset -= 1
                Loop until xpos < xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if
                SkipScanQ3:
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
    end if
    
    '------------------------------------------------QUAD 4---------------------------------------
    if xp > tl_x andAlso ((skipQuad and 8) = 0) then
        ShadowsA(0,_Ek) = QuadBnd(6,_Ek): ShadowsA(0,_Dn) = QuadBnd(6,_Dn): ShadowsA(0,_Dp) = QuadBnd(6,_Dp)
        ShadowsA(0,_Xx) = yp: ShadowsA(0,_Xd) = QuadBnd(6,_Xd)
        ShadowsA(1,_Ek) = QuadBnd(7,_Ek): ShadowsA(1,_Dn) = QuadBnd(7,_Dn): ShadowsA(1,_Dp) = QuadBnd(7,_Dp)
        ShadowsA(1,_Xx) = yp: ShadowsA(1,_Xd) = QuadBnd(7,_Xd)
        texOffset = texCenter
        _N = 2
        If xp - rad < tl_x Then
            prad = xp - tl_x
        Else
            prad = rad
        End if
        For inc = 1 To prad
            If inc > yend Then
                xcirc = inc - yend - 1
                RightBnd = yp + CurveOff(xcirc)
                LeftBnd  = yp - CurveOff(xcirc)
            Else
                RightBnd = yp + inc
                LeftBnd  = yp - inc + 1
            End if
            If RightBnd > br_y Then RightBnd = br_y
            If LeftBnd  < tl_y Then LeftBnd  = tl_y
            xpos = xp - inc
            texOffset -= 1
            segs = _N
            _N = 0
            For i = 0 To segs-1 Step 2
                
                s1 = i
                s2 = i + 1
                oxs = ShadowsA(s1,_Xx)
                If ShadowsA(s1,_Ek) < 0 Then
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dn)
                Else
                    ShadowsA(s1,_Ek) += ShadowsA(s1,_Dp)
                    ShadowsA(s1,_Xx) += ShadowsA(s1,_Xd)
                End If
                oxe = ShadowsA(s2,_Xx)
                If ShadowsA(s2,_Ek) < 0 Then
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dn)
                Else
                    ShadowsA(s2,_Ek) += ShadowsA(s2,_Dp)
                    ShadowsA(s2,_Xx) += ShadowsA(s2,_Xd)
                End If
                xs = ShadowsA(s1,_Xx)
                xe = ShadowsA(s2,_Xx)
                
                If xe > RightBnd Then 
                    Goto SkipScanQ4
                Elseif xs < LeftBnd andAlso _N > 2 Then
                    Goto SkipScanQ4
                Elseif xs > RightBnd Then
                    xs = RightBnd
                End if
                
                txe = xe
                If xe < LeftBnd Then xe = LeftBnd
                
                If (xs - oxs) > 0 andalso xs > 0 then
                    checkAddr = xs*destStride + xpos
                    if (occPxls[checkAddr - destStride] <> tcol) andAlso (occPxls[checkAddr + 1] <> tcol) then
                        xs -= 1
                    end if
                end if
                If (txe - oxe) < 0 then
                    checkAddr = xe*destStride + xpos
                    if (occPxls[checkAddr + destStride] <> tcol) andAlso (occPxls[checkAddr + 1] <> tcol) then
                        xe += 1
                    end if
                end if
                
                if xe > xs andALso _N > 2 then goto SkipScanQ4
                
                ypos = xs
                yadd = xs * destStride
                texCurOffset = texOffset + (xs - yp)*sourceStride
                If occPxls[yadd+xpos] <> tcol Then
                    Do
                        ypos -= 1
                        yadd -= destStride
                        texCurOffset -= sourceStride
                        If ypos <= xe Then Goto SkipScanQ4
                        ccol = occPxls[yadd+xpos]
                        If ccol = tcol Then
                            If ypos > xe Then
                                dx = ypos-yp: dy = inc
                                _addelement(ypos)
                            Else
                                Sptr[yadd+xpos] = tex[texCurOffset]
                                Sptr2[yadd+xpos] = tex2[texCurOffset]                                
                            End if
                            Exit Do
                        End if
                    Loop
                Else
                    _copyelement(s1)
                End if
                
                proc = FILL_LOOP
                Do
                    if proc = FILL_LOOP then
                        If occPxls[yadd+xpos] <> tcol Then
                            dx = ypos-yp+1: dy = inc
                            _addelement(ypos+1)
                            Proc = SEARCH_LOOP
                        Else
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]                            
                        End if
                    else
                        If occPxls[yadd+xpos] = tcol Then
                            dx = ypos-yp: dy = inc
                            _addelement(ypos)
                            Proc = FILL_LOOP
                            Sptr[yadd+xpos] = tex[texCurOffset]
                            Sptr2[yadd+xpos] = tex2[texCurOffset]           
                        End if                        
                    end if
                    ypos -= 1
                    yadd -= destStride
                    texCurOffset -= sourceStride
                Loop until ypos < xe
                
                If _N Mod 2 = 1 Then
                    _copyelement(s2)
                End if
                SkipScanQ4:
            Next i
            If _N = 0 Then Exit For
            _copylist()
        Next inc
    end if
   
    if memoryPool = 0 then
        delete(readList)
        delete(writeList)
    end if
  
End Sub

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

function sortSegList(list as SegList_t ptr) as SegList_t ptr
    dim as SegList_t ptr p, q, e, tail
    dim as integer insize, nmerges, psize, qsize
    dim as integer i, qdist, pdist
    
    if (list = 0) then exit function
    
    insize = 1
    
    do
        p = list
        list = 0
        tail = 0
        
        nmerges = 0
        while p <> 0
            nmerges += 1
            
            q = p
            psize = 0
            for i = 0 to insize - 1
                psize += 1
                q = q->next_
                if q = 0 then exit for
            next i
            
            qsize = insize
            
            while (psize > 0) orElse ((qsize > 0) andAlso (q <> 0))
                if psize = 0 then
                    e = q
                    q = q->next_
                    qsize -= 1
                elseif (qsize = 0) orElse (q = 0) then
                    e = p
                    p = p->next_
                    psize -= 1
                else
                    qdist = iif(q->x0 = q->x1, abs(q->y1 - q->y0), abs(q->x1 - q->x0))
                    pdist = iif(p->x0 = p->x1, abs(p->y1 - p->y0), abs(p->x1 - p->x0))
                    if pdist <= qdist then
                        e = p
                        p = p->next_
                        psize -= 1
                    else
                        e = q
                        q = q->next_
                        qsize -= 1
                    end if
                end if
                
                if tail <> 0 then
                    tail->next_ = e
                else
                    list = e
                end if
                tail = e
                
            wend
            
            p = q
          
        wend
    
        tail->next_ = 0
        if nmerges <= 1 then return list

        insize *= 2
    
    loop

end function

function extractOrthoBoundsCheck(A as integer ptr, w as integer, h as integer, x as integer, y as integer) as integer
    if x <  0 then return 0
    if x >= w then return 0
    if y <  0 then return 0
    if y >= h then return 0
    
    if A[y*w + x] <> 0 then return 1    
    return 0
end function

function extractOrthoSegs(A as integer ptr, w as integer, h as integer) as SegList_t ptr

    #define s_at(X,Y) extractOrthoBoundsCheck(A,w,h,X,Y)
    #macro new_seg(a,b,c,d) 
        lastSeg->next_ = new SegList_t
        lastSeg = lastSeg->next_                     
        lastSeg->next_ = 0                           
        lastSeg->x0 = a                              
        lastSeg->y0 = b                                  
        lastSeg->x1 = c                                  
        lastSeg->y1 = d   
    #endmacro
	
	dim as SegList_t ptr segs
	dim as SegList_t ptr lastSeg
	dim as integer       xScan
	dim as integer       yScan
	dim as integer       xStart
	dim as integer       yStart
	dim as Cardinal      dire
	dim as Cardinal      side
	dim as integer ptr   aTrace
	dim as integer       i

	aTrace = new integer[h*w]
    for i = 0 to w*h-1
        aTrace[i] = 0
    next i
    
	segs = 0
    side = N
	
	for yScan = 0 to h-1
		for xScan = 0 to w-1
            if ((A[yScan*w + xScan] <> 0) andAlso (aTrace[yScan*w + xScan] = 0) andAlso (s_at(xScan, yScan-1) = 0)) then
				side = N
				dire = E
				if (segs = 0) then
					segs = new SegList_t 
					lastSeg = segs
				else
					lastSeg->next_ = new SegList_t
					lastSeg = lastSeg->next_
				end if
				lastSeg->x0    = xScan
				lastSeg->y0    = yScan
				lastSeg->x1    = xScan+1
				lastSeg->y1    = yScan
				lastSeg->next_ = 0 
				xStart = xScan
				yStart = yScan
				do
					if side = N then aTrace[yScan*w + xScan] = 1
					select case side
                    case N:
                        if dire = W then
                            if (s_at(xScan-1,yScan-1) <> 0) then
                                xScan -= 1
                                yScan -= 1
                                side = E
                                dire = N
                                new_seg(xScan+1,yScan+1,xScan+1,yScan)
                            elseif (s_at(xScan-1,yScan) <> 0) then 
                                xScan -= 1
                                lastSeg->x0 -= 1
                            else
                                side = W
                                dire = S
                                new_seg(xScan,yScan,xScan,yScan+1)
                            end if
                        else 'dire == E
                            if (s_at(xScan+1,yScan-1) <> 0) then
                                xScan += 1
                                yScan -=1
                                side = W
                                dire = N		
                                new_seg(xScan,yScan+1,xScan,yScan)
                            elseif (s_at(xScan+1,yScan) <> 0) then
                                xScan += 1
                                lastSeg->x1 += 1
                            else
                                side = E
                                dire = S
                                new_seg(xScan+1,yScan,xScan+1,yScan+1)
                            end if
                        end if
                    case E:
                        if (dire = N) then
                            if (s_at(xScan+1,yScan-1) <> 0) then 
                                xScan += 1
                                yScan -=1
                                side = S
                                dire = E
                                new_seg(xScan,yScan+1,xScan+1,yScan+1)
                            elseif (s_at(xScan,yScan-1) <> 0) then
                                yScan -= 1 
                                lastSeg->y0 -= 1
                            else
                                side = N
                                dire = W
                                new_seg(xScan+1,yScan,xScan,yScan)
                            end if
                        else ' // dire == S
                            if (s_at(xScan+1,yScan+1) <> 0) then
                                xScan += 1
                                yScan +=1
                                side = N
                                dire = E
                                new_seg(xScan,yScan,xScan+1,yScan)
                            elseif (s_at(xScan,yScan+1) <> 0) then
                                yScan += 1 
                                lastSeg->y1 += 1
                            else
                                side = S
                                dire = W
                                new_seg(xScan+1,yScan+1,xScan,yScan+1)
                            end if
                        end if
                    case S:
                        if (dire = E) then
                            if (s_at(xScan+1,yScan+1) <> 0) then
                                xScan += 1
                                yScan +=1
                                side = W
                                dire = S
                                new_seg(xScan,yScan,xScan,yScan+1)
                            elseif (s_at(xScan+1,yScan) <> 0) then
                                xScan += 1 
                                lastSeg->x0 -= 1
                            else
                                side = E
                                dire = N
                                new_seg(xScan+1,yScan+1,xScan+1,yScan)
                            end if
                        else' // dire == W
                            if (s_at(xScan-1,yScan+1) <> 0) then
                                xScan -= 1
                                yScan +=1
                                side = E
                                dire = S
                                new_seg(xScan+1,yScan,xScan+1,yScan+1)
                            elseif (s_at(xScan-1,yScan) <> 0) then
                                xScan -= 1 
                                lastSeg->x1 -= 1
                            else
                                side = W
                                dire = N
                                new_seg(xScan,yScan+1,xScan,yScan)
                            end if
                        end if
                    case W:
                        if (dire = S) then
                            if (s_at(xScan-1,yScan+1) <> 0) then
                                xScan -= 1
                                yScan +=1
                                side = N
                                dire = W
                                new_seg(xScan+1,yScan,xScan,yScan)
                            elseif (s_at(xScan,yScan+1) <> 0) then
                                yScan += 1 
                                lastSeg->y0 += 1
                            else
                                side = S
                                dire = E
                                new_seg(xScan,yScan+1,xScan+1,yScan+1)
                            end if
                        else' // dire == N
                            if (s_at(xScan-1,yScan-1) <> 0) then
                                xScan -= 1
                                yScan -=1
                                side = S
                                dire = W
                                new_seg(xScan+1,yScan+1,xScan,yScan+1)
                            elseif (s_at(xScan,yScan-1) <> 0) then
                                yScan -= 1
                                lastSeg->y1 -= 1
                            else
                                side = N
                                dire = E
                                new_seg(xScan,yScan,xScan+1,yScan)
                            end if
                        end if
					end select
				loop while((xScan <> xStart) orElse (yScan <> yStart) orElse (side <> N))
			end if
		next xscan
	next yscan
    
	delete(aTrace)
	return segs
end function

function intToBCD(value as integer, bcd as integer ptr) as integer
    dim as integer i
    i = 0
    if value = 0 then
        bcd[0] = 0
        return 1
    else
        while value > 0
            bcd[i] = value mod 10
            value = int(value / 10.0)
            i += 1
        wend
        return i
    end if
end function
function lineLineIntersection(a0 as Vector2D, b0 as Vector2D, a1 as Vector2D, b1 as Vector2D, byref p as Vector2D) as integer
    dim as double det
    dim as double c1
    dim as double c2
 
    det = (a0.x - b0.x)*(a1.y - b1.y) - (a0.y - b0.y)*(a1.x - b1.x)
    if det = 0 then 
        p = Vector2D(0,0)
        return 0
    end if
    
    c1 = a0.x*b0.y - a0.y*b0.x
    c2 = a1.x*b1.y - a1.y*b1.x
    p.xs = ((a1.x - b1.x)*c1 - (a0.x - b0.x)*c2) / det
    p.ys = ((a1.y - b1.y)*c1 - (a0.y - b0.y)*c2) / det

    if (a1.x = b1.x) orELse (a0.x = b0.x) then
        if (p.y < _min_(a0.y, b0.y)) orElse (p.y > _max_(a0.y, b0.y)) then return 0
        if (p.y < _min_(a1.y, b1.y)) orELse (p.y > _max_(a1.y, b1.y)) then return 0        
    else
        if (p.x < _min_(a0.x, b0.x)) orElse (p.x > _max_(a0.x, b0.x)) then return 0
        if (p.x < _min_(a1.x, b1.x)) orELse (p.x > _max_(a1.x, b1.x)) then return 0
    end if
    return 1
end function

function lineRectangleCollision(a as Vector2D, b as Vector2D, tl as Vector2D, br as Vector2D, byref p as Vector2D) as integer
    dim as Vector2D iPts(0 to 1)
    dim as Vector2D tempP
    dim as integer cp
    
    cp = 0
    if lineLineIntersection(Vector2D(tl.x,tl.y), Vector2D(br.x,tl.y), a, b, tempP) then
        iPts(cp) = tempP
        cp += 1
    end if
    if lineLineIntersection(Vector2D(br.x,tl.y), Vector2D(br.x,br.y), a, b, tempP) then
        iPts(cp) = tempP
        cp += 1
    end if    
    
    if cp < 2 then
        if lineLineIntersection(Vector2D(br.x,br.y), Vector2D(tl.x,br.y), a, b, tempP) then
            iPts(cp) = tempP
            cp += 1
        end if        
        if cp < 2 then
            if lineLineIntersection(Vector2D(tl.x,br.y), Vector2D(tl.x,tl.y), a, b, tempP) then
                iPts(cp) = tempP
                cp += 1
            end if          
        end if
    end if
    
    if cp = 2 then
        if (a - iPts(0)).magnitude() < (a - iPts(1)).magnitude() then
            p = iPts(0)
        else
            p = iPts(1)
        end if
        return 1
    end if
    return 0
end function

