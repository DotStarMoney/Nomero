#ifndef VECTOR2D_BI
#define VECTOR2D_BI

type Vector2D
    public:
        declare constructor
        declare constructor(xt as double, yt as double)
        declare constructor(byref v as Vector2D)
        
        declare sub normalize()
        declare function magnitude() as double
        declare function cross(byref rhs as Vector2D) as double
        declare function angle() as double
        declare function perp() as Vector2D
        declare function iperp() as Vector2D
        
        declare function x() as double
        declare function y() as double
        declare sub setX(x as double)
        declare sub setY(y as double)
        
        declare operator cast() as string
        declare operator let ( byref rhs as Vector2D)
        
        declare function NAN() as integer
        
        as double xs, ys
    private:
        as integer isNAN
end type
    
declare operator <> ( byref lhs as Vector2D, byref rhs as Vector2D ) as integer
declare operator = ( byref lhs as Vector2D, byref rhs as Vector2D ) as integer
declare operator + ( byref lhs as Vector2D, byref rhs as Vector2D ) as Vector2D
declare operator - ( byref lhs as Vector2D, byref rhs as Vector2D ) as Vector2D
declare operator - ( byref lhs as Vector2D) as Vector2D

declare operator * ( byref lhs as Vector2D, byref rhs as Vector2D ) as double
declare operator * ( byref lhs as Vector2D, rhs as double ) as Vector2D
declare operator * ( lhs as double, byref rhs as Vector2D ) as Vector2D

declare operator / ( byref lhs as Vector2D, rhs as double ) as Vector2D


#endif
