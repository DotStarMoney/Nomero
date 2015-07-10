#include "pVector2D.bi"
#include "vector2d.bi"
#include "vbcompat.bi"

function pVector2D.magnitude() as double
    return sqr(this.xs*this.xs + this.ys*this.ys)
end function

sub pVector2D.normalize()
    dim as double m
    m = this.magnitude
    this.xs = this.xs / m
    this.ys = this.ys/ m
end sub

operator pVector2D.let(byref rhs as Vector2D_)
    this.xs = rhs.xs
    this.ys = rhs.ys
end operator

operator pVector2D.cast() as string
    return "(" & format(this.xs, ".####") & ", " & format(this.ys, ".####") & ")"
end operator

function pVector2D.cross(byref rhs as pVector2D) as double
    return (this.xs * rhs.ys) - (rhs.xs * this.ys)
end function

function pVector2D.angle() as double
    return atan2(-this.y(), -this.x()) + 3.14159265359
end function

function pVector2D.perp() as pVector2D
    return Type(-this.y(), this.x())
end function

function pVector2D.iperp() as pVector2D
    return Type(this.y(), -this.x())
end function
        
function pVector2D.x() as double
    return this.xs
end function

function pVector2D.y() as double
    return this.ys
end function

sub pVector2D.setX(xt as double)
    this.xs = xt
end sub

sub pVector2D.setY(yt as double)
    this.ys = yt
end sub
       
operator <> ( byref lhs as pVector2D, byref rhs as pVector2D ) as integer
    if (lhs.x() <> rhs.x()) orElse (lhs.y() <> rhs.y()) then return 1
	return 0
end operator

operator = ( byref lhs as pVector2D, byref rhs as pVector2D ) as integer
    if (lhs.x() = rhs.x()) andAlso (lhs.y() = rhs.y()) then return 1
	return 0
end operator

operator + ( byref lhs as pVector2D, byref rhs as pVector2D ) as pVector2D
    return Type(lhs.x() + rhs.x(), lhs.y() + rhs.y())
end operator

operator - ( byref lhs as pVector2D, byref rhs as pVector2D ) as pVector2D
    return Type(lhs.x() - rhs.x(), lhs.y() - rhs.y())
end operator

operator - ( byref lhs as pVector2D) as pVector2D
    return Type(-lhs.x(), -lhs.y())
end operator

operator * ( byref lhs as pVector2D, byref rhs as pVector2D ) as double
    return (lhs.x() * rhs.x()) + (lhs.y() * rhs.y())
end operator

operator * ( byref lhs as pVector2D, rhs as double ) as pVector2D
    return Type(lhs.x() * rhs, lhs.y() * rhs)
end operator

operator * ( lhs as double, byref rhs as pVector2D ) as pVector2D
    return Type(rhs.x() * lhs, rhs.y() * lhs)
end operator

operator / ( byref lhs as pVector2D, rhs as double ) as pVector2D
    return Type(lhs.x() / rhs, lhs.y() / rhs)
end operator



