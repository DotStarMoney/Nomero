
type BasicViewport3D
    Z_PLANE as double
    center_x as double
    center_y as double
    cam_x as double
    cam_y as double
    cam_z as double
end type                       
                                 

sub drawXQuad3D(scnptr as integer ptr, vp as BasicViewport3D,_
                                       z0 as double, z1 as double,_
                                       x0 as double, x1 as double,_
                                       yd as double,_
                                       tex as integer ptr,_
                                       tex_x0 as integer, tex_y0 as integer,_
                                       tex_x1 as integer, tex_y1 as integer,_
                                       mulMix as integer)
    dim as integer scn_x0
    dim as integer scn_x1
    dim as double scn_y0_l, scn_y0_h
    dim as double scn_y1_l, scn_y1_h
    dim as double zdepth, t
    dim as double C(0 to 3)
    dim as double lvx, lvz
    dim as integer col, texCol
    dim as double  row_l, row_h, row_l_inc, row_h_inc
    dim as integer scn_row_l, scn_row_h, N, D, scn_row_height
    dim as integer tex_w, tex_h, row, cur_y, pitch_src, pitch_dest
    dim as integer ptr pxls, soffset, src_offset, dest_offset, dest_pxls
    
    lvx = x1 - x0
    lvz = z1 - z0
    
    if lvx = 0 then exit sub
    
    imageinfo tex,,,,pitch_src,pxls
    imageinfo scnptr,,,,pitch_dest,dest_pxls
    tex_w = tex_x1 - tex_x0 + 1
    tex_h = tex_y1 - tex_y0 + 1
    pitch_src shr= 2
    pitch_dest shr= 2
    
    zdepth = vp.Z_PLANE / (z0 - vp.cam_z)
    scn_x0   = (x0 - vp.cam_x) * zdepth
    scn_y0_l = ((-yd*0.5) - vp.cam_y) * zdepth
    scn_y0_h = (( yd*0.5) - vp.cam_y) * zdepth
    
    zdepth = vp.Z_PLANE / (z1 - vp.cam_z)
    scn_x1   = (x1 - vp.cam_x) * zdepth
    scn_y1_l = ((-yd*0.5) - vp.cam_y) * zdepth
    scn_y1_h = (( yd*0.5) - vp.cam_y) * zdepth
        
    C(0) = (vp.cam_x - x0) * vp.Z_PLANE * (tex_w - 1)
    C(1) = (z0 - vp.cam_z) * (tex_w - 1)
    C(2) = lvx * vp.Z_PLANE
    C(3) = -lvz
    
    row_l = scn_y0_l
    row_h = scn_y0_h
    row_l_inc = (scn_y1_l - scn_y0_l) / (scn_x1 - scn_x0)
    row_h_inc = (scn_y1_h - scn_y0_h) / (scn_x1 - scn_x0)

    soffset = pxls + tex_x0 + tex_y0*pitch_src
    dest_pxls += cint(vp.center_x + vp.center_y*pitch_dest)
    
    for col = scn_x0 to scn_x1
        t = (C(0) + C(1)*col) / (C(2) + C(3)*col)
        
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
        dest_offset = dest_pxls + col + scn_row_l*pitch_dest
        
        if tex_h >= scn_row_height then
            D = tex_h - scn_row_height  
            N = 0
            for row = tex_y0 to tex_y1
                if N < D then
                    N += scn_row_height
                else
                    N -= D
                    *dest_offset = *src_offset
                    dest_offset += pitch_dest
                end if
                src_offset += pitch_src
            next row
        else
            D = scn_row_height - tex_h
            N = 0
            row = tex_y0
            for cur_y = scn_row_l to scn_row_h
                *dest_offset = *src_offset
                if N < D then
                    N += tex_h
                else
                    N -= D
                    src_offset += pitch_src
                end if
                dest_offset += pitch_dest
            next cur_y            
        end if
            
        
        row_l += row_l_inc
        row_h += row_h_inc
    next col
    
    
    
end sub




screenres 640,480,32

dim as BasicViewport3D v
dim as integer ptr image, buffer
v.Z_PLANE = 256
v.center_x = 320
v.center_y = 240

image = imagecreate(288, 96)
buffer = imagecreate(640,480, 0)
bload "HUD turnstyle.bmp", image

drawXQuad3D buffer, v, 500, 300, -20, 40, 90, image, 192, 0, 239, 47, 0
drawXQuad3D buffer, v, 300, 300, 40, 120, 90, image, 192, 0, 239, 47, 0


put (0,0), buffer, PSET

sleep
end



