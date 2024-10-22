#include "effects3d.bi"
#include "utility.bi"


sub drawXQuad3D(scnptr as integer ptr, vp as BasicViewport3D,_
                                       z0 as double, z1 as double,_
                                       x0 as double, x1 as double,_
                                       yd as double,_
                                       tex as integer ptr,_
                                       tex_x0 as integer, tex_y0 as integer,_
                                       tex_x1 as integer, tex_y1 as integer,_
                                       mulMix as integer)
                                       
    dim as double scn_y0_l, scn_y0_h
    dim as double scn_y1_l, scn_y1_h
    dim as double zdepth, t
    dim as double C(0 to 3)
    dim as double lvx, lvz, zs, xs
    dim as double  row_l, row_h, row_l_inc, row_h_inc
    dim as integer mulConstData(0 to 1)
    dim as integer ptr mulConst_ptr
    dim as integer scn_x0
    dim as integer scn_x1
    dim as integer col, texCol
    dim as integer scn_row_l, scn_row_h, N, D, scn_row_height
    dim as integer tex_w, tex_h, row, cur_y, pitch_src, pitch_dest
    dim as integer ptr pxls, soffset, src_offset, dest_offset, dest_pxls
    
    lvx = x1 - x0
    lvz = z1 - z0
    
    
    imageinfo tex,,,,pitch_src,pxls
    imageinfo scnptr,,,,pitch_dest,dest_pxls

    tex_w = tex_x1 - tex_x0 + 1
    tex_h = tex_y1 - tex_y0 + 1
    
    zdepth = vp.Z_PLANE / (z0 - vp.cam_z)
    scn_x0   = (x0 - vp.cam_x) * zdepth
    scn_y0_l = ((-yd*0.5) - vp.cam_y) * zdepth
    scn_y0_h = (( yd*0.5) - vp.cam_y) * zdepth
    
    zdepth = vp.Z_PLANE / (z1 - vp.cam_z)
    scn_x1   = (x1 - vp.cam_x) * zdepth
    scn_y1_l = ((-yd*0.5) - vp.cam_y) * zdepth
    scn_y1_h = (( yd*0.5) - vp.cam_y) * zdepth
    
    if scn_x0 = scn_x1 then exit sub
        
    C(0) = (vp.cam_x - x0) * vp.Z_PLANE * (tex_w - 1)
    C(1) = (z0 - vp.cam_z) * (tex_w - 1)
    C(2) = lvx * vp.Z_PLANE
    C(3) = -lvz
    
    row_l = scn_y0_l
    row_h = scn_y0_h
    row_l_inc = (scn_y1_l - scn_y0_l) / (scn_x1 - scn_x0)
    row_h_inc = (scn_y1_h - scn_y0_h) / (scn_x1 - scn_x0)

    soffset = pxls + tex_x0 + tex_y0*(pitch_src shr 2)
    dest_pxls += cint(vp.center_x + vp.center_y*(pitch_dest shr 2))
    
    mulConstData(0) = (mulMix and &hff) or (((mulMix shr 8) and &hff) shl 16)
    mulConstData(1) = ((mulMix shr 16) and &hff) or (((mulMix shr 24) and &hff) shl 16)    
    
    mulConst_ptr = @(mulConstData(0))
    
    xs = C(0) + C(1) * scn_x0
    zs = C(2) + C(3) * scn_x0
    for col = scn_x0 to scn_x1
        t = xs / zs
        
        texCol = int(t)
        if texCol < 0 then
            texCol = 0
        elseif texCol > tex_w - 1 then 
            texCol = tex_w - 1
        end if
        
        scn_row_l = row_l
        scn_row_h = row_h
        scn_row_height = (scn_row_h - scn_row_l) + 1
        
        src_offset = soffset + texCol
        dest_offset = dest_pxls + col + scn_row_l*(pitch_dest shr 2)
        
        if tex_h >= scn_row_height then
            D = tex_h - scn_row_height  
            N = D
            asm
                mov         esi,        [dest_offset]
                mov         edi,        [src_offset]
                mov         eax,        [N]
                mov         ecx,        [tex_y1]
                sub         ecx,        [tex_y0]
                inc         ecx
                
                mov         ebx,        [mulConst_ptr]
                movq        xmm0,       [ebx]
                pandn       xmm1,       xmm1
            
                dxq3D_tex_h_col:
                    
                cmp         eax,        [D]
                jge         dxq3D_tex_h_else
                
                add         eax,        [scn_row_height]
                
                jmp         dxq3D_tex_h_endif
                dxq3D_tex_h_else:
                
                sub         eax,        [D]
                
                movd        xmm2,       [edi]
                
                punpcklbw   xmm2,       xmm1
                pmullw      xmm2,       xmm0
                psrlw       xmm2,       8
                packuswb    xmm2,       xmm2
                
                movd        [esi],      xmm2
                
                add         esi,        [pitch_dest]
                
                dxq3D_tex_h_endif:
                
                add         edi,        [pitch_src]
                
                dec         ecx
                jnz         dxq3D_tex_h_col
            end asm
        else
            D = scn_row_height - tex_h + 1
            N = 0
            asm
                mov         esi,        [dest_offset]
                mov         edi,        [src_offset]
                mov         eax,        [N]
                mov         ecx,        [scn_row_h]
                sub         ecx,        [scn_row_l]
                inc         ecx
                
                mov         ebx,        [mulConst_ptr]
                movq        xmm0,       [ebx]
                pandn       xmm1,       xmm1
            
                dxq3D_srh_col:
                    
                cmp         eax,        [D]
                jge         dxq3D_srh_else
                
                add         eax,        [tex_h]
                
                jmp         dxq3D_srh_endif
                dxq3D_srh_else:
                
                sub         eax,        [D]
                add         edi,        [pitch_src]
                
                dxq3D_srh_endif:
                
                
                movd        xmm2,       [edi]
                
                punpcklbw   xmm2,       xmm1
                pmullw      xmm2,       xmm0
                psrlw       xmm2,       8
                packuswb    xmm2,       xmm2
                
                movd        [esi],      xmm2
                
                
                add         esi,        [pitch_dest]
                
                dec         ecx
                jnz         dxq3D_srh_col
            end asm
        end if
        
        row_l += row_l_inc
        row_h += row_h_inc
        xs += C(1)
        zs += C(3)
    next col
    
end sub

sub drawHexPrism(scnptr as integer ptr, x as integer, y as integer,_
                 angle as double, r as double, h as double,_
                 tex as integer ptr, img_w as integer, img_h as integer,_
                 dispFlags as integer)
    
    dim as integer face, i, bitNum, nFace
    dim as integer tex_x0, tex_y0
    dim as integer tex_x1, tex_y1
    dim as integer tex_w, tex_h
    dim as integer faceNum(0 to 5)
    dim as double  a, shadePerc
    dim as double  l_z_pos, l_x_pos
    dim as double  r_z_pos, r_x_pos
    dim as BasicViewport3D v
    
    imageinfo tex, tex_w, tex_h
    
    v.Z_PLANE = 256
    v.center_x = x
    v.center_y = y
    v.cam_z = -256
    
    angle = wrap(angle)
    
    bitNum = 0
    for i = 0 to 31
        if ((dispFlags shr i) and 1) = 1 then
            faceNum(bitNum) = i
            bitNum += 1
        end if
    next i
    
    face = int((-angle - 0.5236) / 1.0472)
    while face < 0 
        face += 6
    wend

    bitNum = 0   
    
    a = wrap(angle + (face - 2)*1.0472)
    l_x_pos = cos(a)*r
    l_z_pos = sin(a)*r
    
    for i = 1 to 3
        nFace = face + 1
        if nFace >= 6 then nFace -= 6
        
        
        a = wrap(angle + (nFace - 2)*1.0472)
        r_x_pos = cos(a)*r
        r_z_pos = sin(a)*r
        
        tex_x0 = (faceNum(face) * img_w) mod tex_w
        tex_y0 = int((faceNum(face) * img_w) / tex_w) * img_h
        tex_x1 = tex_x0 + img_w - 1
        tex_y1 = tex_y0 + img_h - 1
        
        
        shadePerc = abs(sin(a - 0.5236))
        
        drawXQuad3D scnptr, v, l_z_pos, r_z_pos, l_x_pos, r_x_pos, h,_
                    tex, tex_x0, tex_y0, tex_x1, tex_y1,_
                    rgb(shadePerc*255, shadePerc*255, shadePerc*255)
        
                    
        l_x_pos = r_x_pos
        l_z_pos = r_z_pos
        face = nFace
    next i
    
end sub

sub drawMode7Ceiling(dst as integer ptr, src as integer ptr,_
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
                    paddusb     mm0,            mm1
                    'por         mm0,            mm1                    
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

sub drawMode7Ground(dst as integer ptr, src as integer ptr,_
                        xOff as double, zOff as double,_
                        horiz as integer = -200, s as double = 30, fov as integer = 256)
    
    dim as integer d_offset, offset
    dim as integer x, y, colR, colG, colB
    dim as double  sx, ipz, v, vdiv, nvdiv
    dim as integer hw, hh
    dim as integer ptr srcPxls, dstPxls
    dim as integer destStride,destW, destH
    dim as integer yStart, yEnd, col
    
    imageinfo src,,,,,srcPxls
    imageinfo dst,destW,destH,,destStride,dstPxls
    
    destStride shr= 2
    
    hw = destW * 0.5
    hh = destH * 0.5

    d_offset = (hh + 30) * destStride 
    yStart = -fov
    yEnd = -fov + hh - 1 - 30
    
    for y = yStart to yEnd - 1
        if (y + fov) <> 0 then
            ipz = 1.0 / (y + fov)
            offset = (int((y * ipz) * s + zOff) and 255) shl 8
            sx = (-hw * ipz) * s + xOff
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
            d_offset += destStride
        end if
    next y
end sub