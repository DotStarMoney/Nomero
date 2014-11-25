#include "vector3d.bi"
#include "vbcompat.bi"

constructor Vector3D()
    this.isNAN = 0
    this.xs = 0.0
    this.ys = 0.0
    this.zs = 0.0
    r       = -1.0
    theta_  = -1.0
    phi_    = -1.0
end constructor

constructor Vector3D(xt as const double, yt as const double, zt as const double)
    this.isNAN = 0
    this.xs = xt
    this.ys = yt
    this.zs = zt
    r       = -1.0
    theta_  = -1.0
    phi_    = -1.0
end constructor

destructor Vector3D()
    ''
end destructor

constructor Vector3D(byref v as const Vector3D)
    this = v
end constructor

function Vector3D.magnitude() as double
    if this.r = -1.0 then
        this.r = sqr(this.xs*this.xs + this.ys*this.ys + this.zs*this.zs)
    end if
    return this.r 
end function

function Vector3D.normalize() as Vector3D
    dim as double m
    dim as Vector3D ret
    m = this.magnitude
    if m = 0 then 
        ret.isNAN = 1
        return ret
    end if
    ret.r = 1
    ret.xs = this.xs / m
    ret.ys = this.ys / m
    ret.zs = this.zs / m
    return ret
end function

operator Vector3D.let ( byref rhs as Vector3D )
    this.xs     = rhs.xs
    this.ys     = rhs.ys
    this.zs     = rhs.zs
    this.r      = rhs.r
    this.theta_ = rhs.theta_
    this.phi_   = rhs.phi_
    this.isNan  = rhs.isNan
end operator

operator Vector3D.cast() as string
    if isNan then
        return "NAN"
    else
        return "(" & format(this.xs, ".####") & ", " & format(this.ys, ".####") & ", " & format(this.zs, ".####") & ")"
    end if
end operator

function cross( byref lhs as Vector3D, byref rhs as Vector3D ) as Vector3D
    dim as Vector3D ret
    if lhs.Nan or rhs.Nan then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    ret.setX(lhs.y * rhs.z - lhs.z * rhs.y)
    ret.setY(lhs.z * rhs.x - lhs.x * rhs.z)
    ret.setZ(lhs.x * rhs.y - lhs.y * rhs.x)
    return ret
end function

function Vector3D.theta() as double
    if theta_ = -1 then
        theta_ = acos(this.z / this.magnitude)
    end if
    return theta_
end function

function Vector3D.phi() as double
    if phi_ = -1 then
        phi_ = atan2(-this.y(), -this.x())
    end if
    return phi_
end function
        
function Vector3D.x() as double
    return this.xs
end function

function Vector3D.y() as double
    return this.ys
end function

function Vector3D.z() as double
    return this.zs
end function

sub Vector3D.setX(xt as double)
    this.xs = xt
    r       = -1.0
    theta_  = -1.0
    phi_    = -1.0
end sub

sub Vector3D.setY(yt as double)
    this.ys = yt
    r       = -1.0
    theta_  = -1.0
    phi_    = -1.0
end sub

sub Vector3D.setZ(zt as double)
    this.zs = zt
    r       = -1.0
    theta_  = -1.0
    phi_    = -1.0
end sub

function Vector3D.rotate(p as Vector3D, v as Vector3D, a as double) as Vector3D
    dim as Vector3D ret
    dim as double sinA, cosA
    dim as double mdot
    dim as Vector3D vsm
    dim as Vector3D csm
    dim as Vector3D pt
    dim as Vector3D vN
    if v.Nan orElse (v.magnitude() = 0) then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    vN = v.normalize()
    sinA = sin(a)
    cosA = cos(a)
    mdot = -(this * v)
    vsm = Vector3D(p.x()*(v.y()*v.y() + v.z()*v.z()),_
                   p.y()*(v.x()*v.x() + v.z()*v.z()),_
                   p.z()*(v.x()*v.x() + v.y()*v.y()))
    csm = Vector3D(v.x()*(p.y()*v.y() + p.z()*v.z() - mdot),_
                   v.y()*(p.x()*v.x() + p.z()*v.z() - mdot),_
                   v.z()*(p.x()*v.x() + p.y()*v.y() - mdot))
    pt  = Vector3D(-p.z()*v.y() + p.y()*v.z() - v.z()*this.y + v.y()*this.z,_
                   -p.x()*v.z() + p.z()*v.x() + v.z()*this.x - v.x()*this.z,_
                   -p.y()*v.x() + p.x()*v.y() - v.y()*this.x + v.x()*this.y)
    ret = (vsm - csm)*(1 - cosA) + this*cosA + pt*sinA
    return ret
end function
       
function Vector3D.NAN() as integer
    return this.isNAN
end function

operator <> ( byref lhs as Vector3D, byref rhs as Vector3D ) as integer
    if (lhs.x() <> rhs.x()) orElse (lhs.y() <> rhs.y()) orElse (lhs.z() <> rhs.z()) then return 1
	return 0
end operator

operator = ( byref lhs as Vector3D, byref rhs as Vector3D ) as integer
    if (lhs.x() = rhs.x()) andAlso (lhs.y() = rhs.y()) andAlso (lhs.z() = rhs.z()) then return 1
	return 0
end operator

operator + ( byref lhs as Vector3D, byref rhs as Vector3D ) as Vector3D
    dim as Vector3D ret
    if lhs.Nan or rhs.Nan then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    ret = Vector3D(lhs.x() + rhs.x(), lhs.y() + rhs.y(), lhs.z() + rhs.z())
    return ret
end operator

operator - ( byref lhs as Vector3D, byref rhs as Vector3D ) as Vector3D
    dim as Vector3D ret
    if lhs.Nan or rhs.Nan then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    ret = Vector3D(lhs.x() - rhs.x(), lhs.y() - rhs.y(), lhs.z() - rhs.z())
    return ret
end operator

operator - ( byref lhs as Vector3D) as Vector3D
    dim as Vector3D ret
    if lhs.Nan then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    ret = Vector3D(-lhs.x(), -lhs.y(), -lhs.z())
    return ret
end operator

operator * ( byref lhs as Vector3D, byref rhs as Vector3D ) as double
    return (lhs.x() * rhs.x()) + (lhs.y() * rhs.y()) + (lhs.z() * rhs.z())
end operator

operator * ( byref lhs as Vector3D, rhs as double ) as Vector3D
    dim as Vector3D ret
    if lhs.Nan then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    ret = Vector3D(lhs.x() * rhs, lhs.y() * rhs, lhs.z() * rhs)
    return ret
end operator

operator * ( lhs as double, byref rhs as Vector3D ) as Vector3D
    dim as Vector3D ret
    if rhs.Nan then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    ret = Vector3D(rhs.x() * lhs, rhs.y() * lhs, rhs.z() * lhs)
    return ret
end operator

operator / ( byref lhs as Vector3D, rhs as double ) as Vector3D
    dim as Vector3D ret
    if lhs.Nan orElse (rhs = 0) then 
        ret = Vector3D(0,0,0)
        return ret.normalize()
    end if
    ret = Vector3D(lhs.x() / rhs, lhs.y() / rhs, lhs.z() / rhs)
    return ret
end operator



function perspective( byref v as Vector3D,_
                      byref camera as Vector3D,_
                      z_plane as double,_
                      planeDimension as Vector2D,_
                      windowDimension as Vector2D ) as Vector2D
    dim as Vector2D ret
    dim as double zmul
    if camera.Nan orElse planeDimension.Nan orElse windowDimension.Nan orElse v.Nan orElse (v.z - camera.z = 0) then 
        ret = Vector2D(0,0)
        ret.normalize()
        return ret
    end if
    zmul = z_plane / (v.z - camera.z)
    ret.setX((v.x - camera.x) * zmul * (windowDimension.x() / planeDimension.x()) + windowDimension.x * 0.5)
    ret.setY((v.y - camera.y) * zmul * (windowDimension.y() / planeDimension.y()) + windowDimension.y * 0.5)   
    return ret
end function

