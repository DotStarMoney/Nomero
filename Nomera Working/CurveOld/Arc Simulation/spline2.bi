#ifndef SPLINE2_BI
#define SPLINE2_BI

#include "vector3d.bi"
#include "vector2d.bi"
#include "errlog.bi"

type s2_const as integer 
type s2_bool as integer

const as s2_const S2_SUBDIVIDE_ALL       = 0
const as s2_const S2_SUBDIVIDE_BY_LENGTH = 1
const as s2_const S2_FALSE               = 0
const as s2_const S2_TRUE                = 1
const as s2_const S2_NO_CURVE            = -1

type s2_Bezier2
    as double length
    as s2_const mustCompute
    as Vector3D c0, c1, c2
    as Vector2D q1, q2, q3
end type

type s2_ControlPoint
    as Vector3D p
    as integer curve0
    as integer curve1
    as integer curve2
end type

type Spline2 extends ErrLog
    public:
        declare constructor()
        declare destructor()
        
        declare sub addControlPoint(p as Vector3D)
        declare function getControlPointN() as integer
        declare sub setControlPoint(i as integer, p as Vector3D)
        declare sub removeControlPoint(i as integer)
        declare function getControlPoint(i as integer) as Vector3D
        
        declare sub flush()
        
        declare function getPoint(t as double) as Vector3D
        declare function getNextPoint(td as double) as Vector3D
        declare function getLength() as double
        
        declare function subdivide(method as s2_const = S2_SUBDIVIDE_ALL,_
                                   length as double = 0) as Vector3D ptr
    private:
        declare function getBezierPoint(curve as integer, pt_i as integer) as Vector3D
        declare sub computeBezier(i as integer)
        declare function computePoint(curve as integer, t as double) as Vector3D
        declare sub integrate(c1 as Vector3D,_
                              c2 as Vector3D,_
                              byref d0 as double,_
                              byref d1 as double,_
                              byref d2 as double,_
                              byref dx0 as double,_
                              byref dx1 as double)
        
        as integer lastSample
        as double lastLength
        as double lastT
        as double computeLength
        
        as s2_ControlPoint ptr controlPoint
        as integer             controlPoint_N
        as integer             controlPoint_cap
        
        as s2_bezier2 ptr bezier
        as integer        bezier_N
        as integer        bezier_cap
end type


#endif