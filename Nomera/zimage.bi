#ifndef ZIMAGE_BI
#define ZIMAGE_BI

#include "pointlight.bi"

type zImage
    public:
        declare constructor()
        declare constructor(filename as string)
        declare destructor()
        
        declare sub flush()
        declare sub load(filename as string)
        declare sub create(wp as integer, hp as integer, diffuse_ as integer ptr, normal_ as integer ptr)
        
        declare function getWidth() as integer
        declare function getHeight() as integer
        declare function getData() as integer ptr
        declare function getNorm() as integer ptr

        
        declare sub putTRANS(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                             x0 as integer, y0 as integer, x1 as integer, y1 as integer)
        declare sub putGLOW(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                             x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                             colOffset as integer = &h00000000)
                             
        declare sub putPREALPHA_TARGET(dest_fbimg as integer ptr, prealphasource_fbimg as integer ptr, _
                                       posX as integer, posY as integer,_
                                       x0 as integer, y0 as integer, x1 as integer, y1 as integer)                     
                                                          
        declare sub putPREALPHA(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                                x0 as integer, y0 as integer, x1 as integer, y1 as integer)
                                                          
        declare sub putTRANS_0xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                                     x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                                     ambientLight as integer = &h00000000)                     
                             
        declare sub putTRANS_1xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                                     x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                                     ambientLight as integer = &h00000000,_
                                     light1 as PointLight)
        declare sub putTRANS_2xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                                     x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                                     ambientLight as integer = &h00000000,_
                                     light1 as PointLight, light2 as PointLight)
        declare sub putTRANS_3xLight(dest_fbimg as integer ptr, posX as integer, posY as integer,_
                                     x0 as integer, y0 as integer, x1 as integer, y1 as integer,_
                                     ambientLight as integer = &h00000000,_
                                     light1 as PointLight, light2 as PointLight, light3 as PointLight)
    private:
        as integer isEmpty
        as integer isPng
        as integer isCopy
        as integer hasNorm
        as integer ptr diffuse_fbimg
        as integer ptr norm_fbimg   
        as integer w
        as integer h 
end type


#endif