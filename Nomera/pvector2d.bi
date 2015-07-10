#ifndef PVECTOR2D_BI
#define PVECTOR2D_BI

type Vector2D_ as Vector2D

type pVector2D
    public:
        
        declare sub normalize()
        declare function magnitude() as double
        declare function cross(byref rhs as pVector2D) as double
        declare function angle() as double
        declare function perp() as pVector2D
        declare function iperp() as pVector2D
        
        declare function x() as double
        declare function y() as double
        declare sub setX(x as double)
        declare sub setY(y as double)
        
        declare operator cast() as string
        declare operator let (byref rhs as Vector2D_)
        
        as double xs, ys
end type
    
declare operator <> ( byref lhs as pVector2D, byref rhs as pVector2D ) as integer
declare operator = ( byref lhs as pVector2D, byref rhs as pVector2D ) as integer
declare operator + ( byref lhs as pVector2D, byref rhs as pVector2D ) as pVector2D
declare operator - ( byref lhs as pVector2D, byref rhs as pVector2D ) as pVector2D
declare operator - ( byref lhs as pVector2D) as pVector2D

declare operator * ( byref lhs as pVector2D, byref rhs as pVector2D ) as double
declare operator * ( byref lhs as pVector2D, rhs as double ) as pVector2D
declare operator * ( lhs as double, byref rhs as pVector2D ) as pVector2D

declare operator / ( byref lhs as pVector2D, rhs as double ) as pVector2D


#endif
