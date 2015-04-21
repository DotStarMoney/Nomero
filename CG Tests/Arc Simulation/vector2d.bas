#include "vector2d.bi"
#include "vbcompat.bi"

constructor Vector2D
    this.isNAN = 0
    this.xs = 0.0
    this.ys = 0.0
end constructor

constructor Vector2D(xt as double, yt as double)
    this.isNAN = 0
    this.xs = xt
    this.ys = yt
end constructor

constructor Vector2D(byref v as Vector2D)
    this.xs = v.x()
    this.ys = v.y()
    this.isNAN = v.NAN()
end constructor

function Vector2D.magnitude() as double
    return sqr(this.xs*this.xs + this.ys*this.ys)
end function

sub Vector2D.normalize()
    dim as double m
    m = this.magnitude
    if m = 0 then 
        this.isNAN = 1
        exit sub
    end if
    this.xs = this.xs / m
    this.ys = this.ys/ m
end sub

operator Vector2D.let ( byref rhs as Vector2D )
    if rhs.isNAN = 1 then
        this.isNan = 1
    else
        this.isNan = 0
    end if
    this.xs = rhs.xs
    this.ys = rhs.ys
end operator

operator Vector2D.cast() as string
    return "(" & format(this.xs, ".####") & ", " & format(this.ys, ".####") & ")"
end operator

function Vector2D.cross(byref rhs as Vector2D) as double
    return (this.xs * rhs.ys) - (rhs.xs * this.ys)
end function

function Vector2D.angle() as double
    return atan2(-this.y(), -this.x()) + 3.14159265359
end function

function Vector2D.perp() as Vector2D
    return Vector2D(-this.y(), this.x())
end function

function Vector2D.iperp() as Vector2D
    return Vector2D(this.y(), -this.x())
end function
        
function Vector2D.x() as double
    return this.xs
end function

function Vector2D.y() as double
    return this.ys
end function

sub Vector2D.setX(xt as double)
    this.xs = xt
end sub

sub Vector2D.setY(yt as double)
    this.ys = yt
end sub
       
function Vector2D.NAN() as integer
    return this.isNAN
end function

operator <> ( byref lhs as Vector2D, byref rhs as Vector2D ) as integer
    if (lhs.x() <> rhs.x()) orElse (lhs.y() <> rhs.y()) then return 1
	return 0
end operator

operator = ( byref lhs as Vector2D, byref rhs as Vector2D ) as integer
    if (lhs.x() = rhs.x()) andAlso (lhs.y() = rhs.y()) then return 1
	return 0
end operator

operator + ( byref lhs as Vector2D, byref rhs as Vector2D ) as Vector2D
    return Type(lhs.x() + rhs.x(), lhs.y() + rhs.y())
end operator

operator - ( byref lhs as Vector2D, byref rhs as Vector2D ) as Vector2D
    return Type(lhs.x() - rhs.x(), lhs.y() - rhs.y())
end operator

operator - ( byref lhs as Vector2D) as Vector2D
    return Type(-lhs.x(), -lhs.y())
end operator

operator * ( byref lhs as Vector2D, byref rhs as Vector2D ) as double
    return (lhs.x() * rhs.x()) + (lhs.y() * rhs.y())
end operator

operator * ( byref lhs as Vector2D, rhs as double ) as Vector2D
    return Type(lhs.x() * rhs, lhs.y() * rhs)
end operator

operator * ( lhs as double, byref rhs as Vector2D ) as Vector2D
    return Type(rhs.x() * lhs, rhs.y() * lhs)
end operator

operator / ( byref lhs as Vector2D, rhs as double ) as Vector2D
    return Type(lhs.x() / rhs, lhs.y() / rhs)
end operator



















