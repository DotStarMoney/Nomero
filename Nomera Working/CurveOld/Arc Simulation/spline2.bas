#include "Spline2.bi"
#include "vector2d.bi"

#define S2_DYN_ARRAY_COARSE 8
#macro BOUNDS_CHECK_START()
    if (i < 0) orElse (controlPoint_n < 1) orElse (i >= controlPoint_n) then
        HCF("bad index")
#endmacro
#macro BOUNDS_CHECK_END() 
    end if
#endmacro

#macro SUFFICIENT_POINTS_START()
    if (controlPoint_n < 3) then
        HCF("insufficient control points")
#endmacro
#macro SUFFICIENT_POINTS_END() 
    end if
#endmacro

constructor Spline2()
    controlPoint = 0
    controlPoint_n = 0
    controlPoint_cap = 0
    bezier = 0
    bezier_n = 0
    bezier_cap = 0
    lastSample = -1
end constructor

destructor Spline2()
    flush()
end destructor

sub Spline2.addControlPoint(p as Vector3D)
    if controlPoint_n = controlPoint_cap then
        controlPoint_cap += S2_DYN_ARRAY_COARSE
        controlPoint = reallocate(controlPoint, sizeof(s2_ControlPoint) * controlPoint_cap)
    end if
    controlPoint_n += 1
    controlPoint[controlPoint_n - 1].p = p
    if controlPoint_n >= 3 then
        if bezier_N = bezier_cap then
            bezier_cap += S2_DYN_ARRAY_COARSE
            bezier = reallocate(bezier, sizeof(s2_bezier2) * bezier_cap)
        end if
        bezier_N += 1
        if controlPoint_n > 3 then
            bezier[bezier_N - 2].mustCompute = s2_TRUE
            bezier[bezier_N - 1].mustCompute = s2_TRUE
            controlPoint[controlPoint_n - 3].curve2 = bezier_N - 1
            controlPoint[controlPoint_n - 2].curve1 = bezier_N - 1
            controlPoint[controlPoint_n - 1].curve0 = bezier_N - 1
            controlPoint[controlPoint_n - 1].curve1 = s2_NO_CURVE
            controlPoint[controlPoint_n - 1].curve2 = s2_NO_CURVE
        else
            bezier[bezier_N - 1].mustCompute = s2_TRUE
            controlPoint[0].curve0 = s2_NO_CURVE
            controlPoint[0].curve1 = s2_NO_CURVE
            controlPoint[0].curve2 = 0
            controlPoint[1].curve0 = s2_NO_CURVE
            controlPoint[1].curve1 = 0
            controlPoint[1].curve2 = s2_NO_CURVE
            controlPoint[2].curve0 = 0
            controlPoint[2].curve1 = s2_NO_CURVE
            controlPoint[2].curve2 = s2_NO_CURVE
        end if
    end if
    lastSample = -1
    computeLength = -1
end sub

function Spline2.getControlPointN() as integer
    return controlPoint_n
end function

sub Spline2.setControlPoint(i as integer, p as Vector3D)
    BOUNDS_CHECK_START()
        exit sub
    BOUNDS_CHECK_END()
    controlPoint[i].p = p
    if controlPoint[i].curve0 <> s2_NO_CURVE then bezier[controlPoint[i].curve0].mustCompute = s2_TRUE
    if controlPoint[i].curve1 <> s2_NO_CURVE then bezier[controlPoint[i].curve1].mustCompute = s2_TRUE
    if controlPoint[i].curve2 <> s2_NO_CURVE then bezier[controlPoint[i].curve2].mustCompute = s2_TRUE
    lastSample = -1
    computeLength = -1
end sub

sub Spline2.removeControlPoint(i as integer)
    dim as integer q, b, i_p
    BOUNDS_CHECK_START()
        exit sub
    BOUNDS_CHECK_END()
    
    b = controlPoint[i].curve1
    if b = s2_NO_CURVE then
        b = controlPoint[i].curve0
        if b = s2_NO_CURVE then
            b = controlPoint[i].curve2
        end if
    end if
    for q = b to bezier_n-2
        bezier[q] = bezier[q+1]
    next q
    bezier_n -= 1
    for q = i+1 to controlPoint_n-1
        if controlPoint[q].curve0 <> s2_NO_CURVE then controlPoint[q].curve0 -= 1
        if controlPoint[q].curve1 <> s2_NO_CURVE then controlPoint[q].curve1 -= 1
        if controlPoint[q].curve2 <> s2_NO_CURVE then controlPoint[q].curve2 -= 1
    next q 
    
    if controlPoint[i].curve0 <> s2_NO_CURVE then bezier[controlPoint[i].curve0].mustCompute = s2_TRUE
    if controlPoint[i].curve2 <> s2_NO_CURVE then bezier[controlPoint[i].curve2].mustCompute = s2_TRUE
    for q = i to controlPoint_n-2
        controlPoint[q] = controlPoint[q+1]
    next q
    controlPoint_n -= 1
    computeLength = -1
    lastSample = -1
end sub

function Spline2.getControlPoint(i as integer) as Vector3D
    BOUNDS_CHECK_START()
        return Vector3D(0,0,0)
    BOUNDS_CHECK_END()
    return controlPoint[i].p
end function

sub Spline2.flush()
    if controlPoint <> 0 then deallocate(controlPoint)
    if bezier <> 0 then deallocate(bezier)
    controlPoint = 0
    controlPoint_n = 0
    controlPoint_cap = 0
    bezier = 0
    bezier_n = 0
    bezier_cap = 0
    lastSample = -1
    computeLength = -1
end sub

function Spline2.getNextPoint(td as double) as Vector3D
    dim as double t
    SUFFICIENT_POINTS_START()
        return Vector3D(0,0,0)
    SUFFICIENT_POINTS_END()
    if td < 0 then
        HCF("point trace offset must be positive")
        return Vector3D(0,0,0)
    end if
    
    if lastSample = -1 then
        lastSample = 0
        lastLength = 0
        lastT = 0
        t = lastT
        if bezier[lastSample].mustCompute = s2_TRUE then computebezier(lastSample)
    else
        t = lastT + td
    end if
    
    while t >= (lastLength + bezier[lastSample].length)
        if lastSample = bezier_n - 1 then
            return Vector3D(0,0,0)
        end if
        if bezier[lastSample].mustCompute = s2_TRUE then computebezier(lastSample)
        lastLength += bezier[lastSample].length
        lastSample += 1
    wend
    lastT = t
    
    return computePoint(lastSample, lastT)
end function

function Spline2.getPoint(t as double) as Vector3D
    dim as integer curS
    dim as double hi, lastHi
    SUFFICIENT_POINTS_START()
        return Vector3D(0,0,0)
    SUFFICIENT_POINTS_END()
    
    if t < 0 then
        HCF("parameter less than 0")
        return Vector3D(0,0,0)
    end if
    
    hi = 0
    curS = 0
    do
        if bezier[curS].mustCompute = s2_TRUE then computebezier(curS)
        lastHi = hi
        hi += bezier[curS].length
        if t < hi then exit do
        curS += 1
        if curS = bezier_n then
            HCF("parameter greater than length")
            return Vector3D(0,0,0)  
        end if
    loop
   
    lastT = t
    lastSample = curS
    lastLength = lastHi
    
    t = (t - lastHi) / bezier[curS].length
    
    return computePoint(curS, t)
end function

sub Spline2.computeBezier(i as integer)
    dim as Vector3D p0, p1, p2
    dim as double d_curve(0 to 2)
    dim as double s0, s1, s2
    dim as double sx0, sx1
    dim as Vector2D repar(0 to 1)
    p0 = getbezierPoint(i, 0)
    p1 = getbezierPoint(i, 1)
    p2 = getbezierPoint(i, 2)
    with bezier[i]        
        .c0 = p0
        .c1 = 2*(p1 - p0)
        .c2 = p0 - 2*p1 + p2
        integrate(.c1, .c2, s0, s1, s2, sx0, sx1)
        s0 /= s2
        s1 /= s2
        repar(0) = Vector2D(s0, (18*sx0 - 9*sx1 + 2) / 6)
        repar(1) = Vector2D(s1, (-9*sx0 + 18*sx1 - 5) / 6)
        .q1 = 3*repar(0)
        .q2 = -6*repar(0) + 3*repar(1)
        .q3 = 3*(repar(0) - repar(1)) + Vector2D(1, 1)
        .length = s2
        .mustCompute = s2_FALSE
    end with
end sub

sub Spline2.integrate(c1 as Vector3D,_
                      c2 as Vector3D,_
                      byref d0 as double,_
                      byref d1 as double,_
                      byref d2 as double,_
                      byref dx0 as double,_
                      byref dx1 as double)
                      
    #macro ARC_L(x_, y_)
        deriv = b + 2*c*x_
        mag = Sqr(a + x_*(b + c*x_))
        param = asinh + asinhx*x_
        y_ = (sqr2c*deriv*mag + derivSq*Log(param + Sqr(param*param + 1))) * sqr3c_div
    #endmacro
                      
    dim as Vector3D nB, nC
    dim as double a, b, c
    dim as double deriv, mag
    dim as double sqr2c, sqr3c_div
    dim as double derivSq
    dim as double asinh, asinhx
    dim as double param
    dim as double div
    dim as double zero
    dim as double t
    dim as double inflect
    
    nB = c1
    nC = 2*c2
        
    a = nB * nB
    b = 2 * nB * nC
    c = nC * nC
        
    derivSq = b*b - 4*a*c
    sqr2c = 2 * sqr(c)
    sqr3c_div = 1 / (8 * sqr(c*c*c))
    div = -1 / sqr(a - (b*b) / (4*c))
    asinhx = sqr2c * div * 0.5
    asinh = b / sqr2c * div
    inflect = (-2 * c1 * c2) / (4 * c2 * c2)
    
    zero = (sqr2c*b*Sqr(a) + derivSq*Log(asinh + Sqr(asinh*asinh + 1))) * sqr3c_div
    
    ARC_L(1, d2)
    d2 -= zero
    
    dx0 = inflect*0.5
    dx1 = (inflect + 1)*0.5
    
    ARC_L(dx0, d0)
    ARC_L(dx1, d1)
    
    d0 -= zero
    d1 -= zero
    
    
    dim as double d = 0
    dim as double yz
    while d < 1
        ARC_L(d, yz) 
        yz -= zero
        yz /= d2
        pset (yz*256,(1-d)*256), rgb(0,255,0)
        d += 0.01
    wend


    circle (d0/d2*256,(1-dx0)*256), 4, rgb(0,255,0)
    circle (d1/d2*256,(1-dx1)*256), 4, rgb(0,255,0)
    
    flip
    sleep
    
end sub

function Spline2.computePoint(curve as integer, t as double) as Vector3D
    dim as Vector2d tp
    /'
    if bezier[curve].mustCompute = s2_TRUE then
        HCF("cannot get point from unprocessed curve")
        return Vector3D(0,0,0)
    end if
    '/
    
    dim as double x=0
    while x<1
        tp = ((bezier[curve].q3*x + bezier[curve].q2)*x + bezier[curve].q1)*x
        pset (tp.x * 256,(1 - tp.y) * 256), rgb(255,0,0)
        x+=0.01

    wend
    print t
    
    
    tp = ((bezier[curve].q3*t + bezier[curve].q2)*t + bezier[curve].q1)*t
    t = tp.y
    
    return (bezier[curve].c2*t + bezier[curve].c1)*t + bezier[curve].c0
end function

function Spline2.getLength() as double
    dim as integer i
    SUFFICIENT_POINTS_START()
        return 0
    SUFFICIENT_POINTS_END()

    if computeLength < 0 then
        computeLength = 0
        for i = 0 to bezier_n - 1
            if bezier[i].mustCompute = s2_TRUE then computeBezier(i)
            computeLength += bezier[i].length
        next i
    end if
    return computeLength
end function

function Spline2.subdivide(method as s2_const = S2_SUBDIVIDE_ALL,_
                           length as double = 0) as Vector3D ptr
    SUFFICIENT_POINTS_START()
        return 0
    SUFFICIENT_POINTS_END()
    computeLength = -1
    lastSample = -1
    '''''
end function

function Spline2.getBezierPoint(curve as integer, pt_i as integer) as Vector3D
    dim as integer i
    SUFFICIENT_POINTS_START()
        return Vector3D(0,0,0)
    SUFFICIENT_POINTS_END()
    if curve = 0 then
        if pt_i = 0 then 
            return controlPoint[0].p
        elseif pt_i = 1 then
            return controlPoint[1].p
        else
            if controlPoint_n = 3 then
                return controlPoint[2].p
            else
                return (controlPoint[1].p + controlPoint[2].p)*0.5
            end if
        end if
    elseif curve = bezier_n - 1 then
        if pt_i = 0 then
            if controlPoint_n = 3 then
                return controlPoint[0].p
            else
                return (controlPoint[controlPoint_n - 3].p + controlPoint[controlPoint_n - 2].p)*0.5
            end if        
        elseif pt_i = 1 then
            return controlPoint[controlPoint_n - 2].p
        else
            return controlPoint[controlPoint_n - 1].p
        end if
    else
        i = curve
        if pt_i = 0 then
            return (controlPoint[i].p + controlPoint[i+1].p) * 0.5
        elseif pt_i = 1 then
            return controlPoint[i+1].p
        else
            return (controlPoint[i+1].p + controlPoint[i+2].p) * 0.5
        end if
    end if
end function

