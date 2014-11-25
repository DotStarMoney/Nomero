#ifndef SPLINE2_BI
#define SPLINE2_BI

#include "vector3d.bi"
#include "vector2d.bi"
#include "errlog.bi"

type s2_const as integer 
type s2_bool as integer
type s2_tag as integer

const as s2_const S2_FALSE               = 0
const as s2_const S2_TRUE                = 1
const as s2_const S2_NO_CURVE            = -1
const as s2_tag   S2_INVALID_TAG         = -1

type s2_ArcConst
    as double asinh
    as double asinhx
    as double sqr2c
    as double sqr3c_div
    as double a, b, c
    as double derivSq
    as double zero
    as double mag
    as double inflect
end type

type s2_Segment
    as Vector3D a, b
    as double   length
    as Vector3D v
    as double   a_length
end type

type s2_Bezier2
    as s2_const       mustCompute
    as double         length
    as s2_Segment ptr segment
    as integer        segment_N
    as Vector3D       c0, c1, c2
    as s2_ArcConst    arcConst
end type

type s2_Anchor
    as integer curve
    as double  parameter
    as integer exist
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
        
        declare sub addControlPoint(p as Vector3D)                                     'done
        declare function getControlPointN() as integer                                 'done
        declare sub setControlPoint(i as integer, p as Vector3D)                       'done
        declare sub removeControlPoint(i as integer)                                   'done
        declare function getControlPoint(i as integer) as Vector3D                     'done
        
        declare sub flush()                                                            'done
        
        declare function seekPoint(t as double) as Vector3D                            'done
        declare function getPoint(t as double) as Vector3D                             'done
        declare function getLength() as double                                         'done
        declare function getTangent() as Vector3D
                                           
        declare function createAnchor(pt_i as double) as s2_tag                         'done
        declare sub removeAnchor(tag as s2_tag)                                         'done
        declare function getAnchor(tag as s2_tag) as Vector3D                           'done
        declare function getAnchorArc(tag as s2_tag) as double                          'done

    private:
        declare function getBezierPoint(curve as integer, pt_i as integer) as Vector3D  'done
        declare sub computeBezier(i as integer)                                         'done        
        declare function integrate(p as double, arcConst as s2_ArcConst) as double      'done
        declare sub computeIntegrationConstants(c1 as Vector3D,_                        
                                                c2 as Vector3D,_
                                                byref arcConst as s2_ArcConst)          'done
        declare function invertParameter(arc_i as double, arcConst as s2_ArcConst) as double
        
        as integer lastCurve
        as integer lastSegment
        as double  lastT
        as double  lastST
        as Vector3D lastTangent
        
        as double computeLength
        
        as s2_ControlPoint ptr controlPoint
        as integer             controlPoint_N
        as integer             controlPoint_cap
        
        as s2_Bezier2 ptr bezier
        as integer        bezier_N
        as integer        bezier_cap
        
        as s2_Anchor ptr anchor
        as integer       anchor_N
        as integer       anchor_cap
end type


#endif