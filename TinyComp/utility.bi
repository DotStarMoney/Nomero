#ifndef UTILITY_BI
#define UTILITY_BI

#define PI 3.14159265359

declare function min overload(x as double, y as double) as double
declare function min overload(x as integer, y as integer) as integer
declare function max overload(x as double, y as double) as double
declare function max overload(x as integer, y as integer) as integer

declare function wrap(v as double) as double
declare Sub Split(Text As String, Delim As String = " ", Count As Long = -1, Ret() As String)

declare sub parallaxAdjust(byref p_x as double, byref p_y as double,_
                           cam_x as double, cam_y as double,_
                           lvlWidth as integer, lvlHeight as integer,_
                           depth as double)
    
declare function rndRange(a as double, b as double) as double
declare sub stall(mili as integer)
declare sub roundDbl(byref v as double, r as integer)
declare sub scale2sync(img as uinteger ptr)
declare function trimwhite(s as string) as string
declare sub bitblt_FalloutMix(dest as uinteger ptr,_
                              xpos as integer, ypos as integer,_
                              src  as uinteger ptr,_
                              src_x0 as integer, src_y0 as integer,_
                              src_x1 as integer, src_y1 as integer)

declare sub bitblt_FalloutToFalloutMix(dest as uinteger ptr,_
                                       xpos as integer, ypos as integer,_
                                       src  as uinteger ptr,_
                                       src_x0 as integer, src_y0 as integer,_
                                       src_x1 as integer, src_y1 as integer)
                                       
declare function ScreenClip(px as integer, py as integer ,_
                            sx as integer, sy as integer ,_
                            byref npx  as integer, byref npy  as integer ,_
                            byref sdx1 as integer, byref sdy1 as integer ,_
                            byref sdx2 as integer, byref sdy2 as integer) as integer
                           
 
declare function circleBox(px as double, py as double, rad as double,_
						   x1 as double, y1 as double,_
						   x2 as double, y2 as double) as integer


#endif
