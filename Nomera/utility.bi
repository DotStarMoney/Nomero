#ifndef UTILITY_BI
#define UTILITY_BI

#include "vector2d.bi"

#define PI 3.14159265359

declare function min overload(x as double, y as double) as double
declare function min overload(x as integer, y as integer) as integer
declare function max overload(x as double, y as double) as double
declare function max overload(x as integer, y as integer) as integer

declare function wrap(v as double, v_w as double = 6.28318530718) as double
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

declare sub drawStringShadow(scnbuff as integer ptr,_
							 x as integer, y as integer,_
							 text as string,_
							 col as integer)
							 
declare sub bitblt_alphaGlow(dest as uinteger ptr,_
							 xpos as integer, ypos as integer,_
							 src  as uinteger ptr,_
                             src_x0 as integer, src_y0 as integer,_
                             src_x1 as integer, src_y1 as integer,_
                             colOffset as integer = &h00000000)
                             
declare sub triangle_AHS(dest as integer ptr = 0,_
						 x0 as double, y0 as double,_
						 x1 as double, y1 as double,_
						 x2 as double, y2 as double,_
						 col as integer)

declare sub vTriangle(dest as integer ptr = 0,_
					  p0 as Vector2D, p1 as Vector2D, p2 as Vector2D, _
				      col as integer)
				      
declare function boxbox(a0 as Vector2D, b0 as Vector2D, a1 as Vector2D, b1 as Vector2D) as integer

declare sub vLine(scnbuff as integer ptr, a as Vector2D, b as Vector2D, col as integer)

declare sub addColor(byref a as integer, byref b as integer)
declare sub subColor(byref ac as integer, byref bc as integer)

#endif
