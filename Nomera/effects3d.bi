#ifndef EFFECTS3D_BI
#define EFFECTS3D_BI

type BasicViewport3D
    Z_PLANE as double
    center_x as double
    center_y as double
    cam_x as double
    cam_y as double
    cam_z as double
end type                       
            
declare sub drawXQuad3D(scnptr as integer ptr, vp as BasicViewport3D,_
                        z0 as double, z1 as double,_
                        x0 as double, x1 as double,_
                        yd as double,_
                        tex as integer ptr,_
                        tex_x0 as integer, tex_y0 as integer,_
                        tex_x1 as integer, tex_y1 as integer,_
                        mulMix as integer)     
                        
declare sub drawHexPrism(scnptr as integer ptr, x as integer, y as integer,_
                         angle as double, r as double, h as double,_
                         tex as integer ptr, img_w as integer, img_h as integer,_
                         dispFlags as integer)
       
declare sub drawMode7Ground(dstPxls as integer ptr, srcPxls as integer ptr,_
                        xOff as double, zOff as double,_
                        horiz as integer = -200, s as double = 30, fov as integer = 256)
    
    
#endif