#ifndef VECTOR3D_BI
#define VECTOR3D_BI

#include "Vector2D.bi"

type Vector3D
    public:
        declare constructor()
        declare constructor(xt as const double, yt as const double, zt as const double)
        declare constructor(byref v as const Vector3D)
        declare destructor()
        
        declare function normalize() as Vector3D
        declare function magnitude() as double
        declare function theta() as double
        declare function phi() as double
        declare function rotate(p as Vector3D, v as Vector3D, a as double) as Vector3D
        
        declare function x() as double
        declare function y() as double
        declare function z() as double
        declare sub setX(x as double)
        declare sub setY(y as double)
        declare sub setZ(z as double)
        
        declare operator cast() as string
        declare operator let ( byref rhs as Vector3D )
        
        declare function NAN() as integer
    private:
        as double xs, ys, zs
        as double r, theta_, phi_
        as integer isNAN
end type
    
declare operator <> ( byref lhs as Vector3D, byref rhs as Vector3D ) as integer
declare operator = ( byref lhs as Vector3D, byref rhs as Vector3D ) as integer
declare operator + ( byref lhs as Vector3D, byref rhs as Vector3D ) as Vector3D
declare operator - ( byref lhs as Vector3D, byref rhs as Vector3D ) as Vector3D
declare operator - ( byref lhs as Vector3D) as Vector3D

declare operator * ( byref lhs as Vector3D, byref rhs as Vector3D ) as double
declare operator * ( byref lhs as Vector3D, rhs as double ) as Vector3D
declare function cross( byref lhs as Vector3D, byref rhs as Vector3D ) as Vector3D
declare operator * ( lhs as double, byref rhs as Vector3D ) as Vector3D

declare operator / ( byref lhs as Vector3D, rhs as double ) as Vector3D
declare function perspective( byref v as Vector3D,_
                              byref camera as Vector3D,_
                              z_plane as double,_
                              planeDimension as Vector2D,_
                              windowDimension as Vector2D ) as Vector2D

#endif
