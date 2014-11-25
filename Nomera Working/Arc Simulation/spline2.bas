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

#macro ADD_ONE_BEZIER(iter)
    if bezier_N = bezier_cap then
        bezier_cap += S2_DYN_ARRAY_COARSE
        bezier = reallocate(bezier, sizeof(s2_bezier2) * bezier_cap)
        for iter = (bezier_cap - S2_DYN_ARRAY_COARSE) to bezier_cap - 1
            bezier[iter].segment_n = 0
            bezier[iter].segment = 0
        next iter
    end if
    bezier_N += 1
#endmacro

constructor Spline2()
    controlPoint = 0
    controlPoint_n = 0
    controlPoint_cap = 0
    bezier = 0
    bezier_n = 0
    bezier_cap = 0
    anchor = 0
    anchor_n = 0
    anchor_cap = 0
    lastCurve = -1
    lastTangent = Vector3D(0,0,0)
end constructor

destructor Spline2()
    flush()
end destructor

sub Spline2.addControlPoint(p as Vector3D)
    dim as integer i
    if controlPoint_n = controlPoint_cap then
        controlPoint_cap += S2_DYN_ARRAY_COARSE
        controlPoint = reallocate(controlPoint, sizeof(s2_ControlPoint) * controlPoint_cap)
    end if
    controlPoint_n += 1
    controlPoint[controlPoint_n - 1].p = p
    if controlPoint_n >= 3 then
        ADD_ONE_BEZIER(i)
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
    lastCurve = -1
    computeLength = -1
    lastTangent = Vector3D(0,0,0)
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
    lastCurve = -1
    lastTangent =Vector3D(0,0,0)
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
    if bezier[b].segment <> 0 then 
        deallocate(bezier[b].segment)
        bezier[b].segment = 0
        bezier[b].segment_n = 0
    end if
    for q = b to bezier_n-2
        bezier[q] = bezier[q+1]
    next q
    
    for i = 0 to anchor_cap-1
        if anchor[i].exist = 1 then
            if anchor[i].curve = b then
                anchor[i].exist = 0
            end if
        end if
    next i
    
    bezier_n -= 1
    for q = i+1 to controlPoint_n-1
        if controlPoint[q].curve0 <> s2_NO_CURVE then controlPoint[q].curve0 -= 1
        if controlPoint[q].curve1 <> s2_NO_CURVE then controlPoint[q].curve1 -= 1
        if controlPoint[q].curve2 <> s2_NO_CURVE then controlPoint[q].curve2 -= 1
    next q 
    
    if controlPoint[i].curve0 <> s2_NO_CURVE then bezier[controlPoint[i].curve0].mustCompute = s2_TRUE
    if controlPoint[i].curve1 <> s2_NO_CURVE then bezier[controlPoint[i].curve1].mustCompute = s2_TRUE
    if controlPoint[i].curve2 <> s2_NO_CURVE then bezier[controlPoint[i].curve2].mustCompute = s2_TRUE

    for q = i to controlPoint_n-2
        controlPoint[q] = controlPoint[q+1]
    next q
    
    controlPoint_n -= 1
    computeLength = -1
    lastCurve = -1
    lastTangent = Vector3D(0,0,0)

end sub

function Spline2.getControlPoint(i as integer) as Vector3D
    BOUNDS_CHECK_START()
        return Vector3D(0,0,0)
    BOUNDS_CHECK_END()
    return controlPoint[i].p
end function

sub Spline2.flush()
    dim as integer i
    for i = 0 to bezier_n - 1
        if bezier[i].segment <> 0 then
            deallocate(bezier[i].segment)
            bezier[i].segment = 0
            bezier[i].segment_n = 0
        end if
    next i
    if controlPoint <> 0 then deallocate(controlPoint)
    if bezier <> 0 then deallocate(bezier)
    if anchor <> 0 then deallocate(anchor)
    controlPoint = 0
    controlPoint_n = 0
    controlPoint_cap = 0
    anchor = 0
    anchor_n = 0
    anchor_cap = 0
    bezier = 0
    bezier_n = 0
    bezier_cap = 0
    lastCurve = -1
    computeLength = -1
    lastTangent = Vector3D(0,0,0)
end sub

function Spline2.getPoint(t as double) as Vector3D
    dim as double dt, rDist
    if lastCurve = -1 then
        return seekPoint(t)
    else
        dt = t - lastT
        if dt > 0 then
            if (lastST + dt) > bezier[lastCurve].segment[lastSegment].length then
                rDist = bezier[lastCurve].segment[lastSegment].length - lastST
                do
                    lastSegment += 1
                    if lastSegment >= bezier[lastCurve].segment_N then
                        lastSegment = 0
                        lastCurve += 1
                    end if
                    if lastCurve >= bezier_n then
                        lastCurve = -1
                        HCF("parameter greater than curve length")
                        return Vector3D(0,0,0)
                    else
                        if bezier[lastCurve].mustCompute = s2_TRUE then computeBezier(lastCurve)
                    end if
                    dt -= rDist
                    rDist = bezier[lastCurve].segment[lastSegment].length
                loop while dt >= rDist
                lastST = dt
            else
                lastST = lastST + dt
            end if
            lastT  = t
            lastTangent = bezier[lastCurve].segment[lastSegment].v
            return lastST * bezier[lastCurve].segment[lastSegment].v + bezier[lastCurve].segment[lastSegment].a
        elseif dt < 0 then
            rDist = lastST
            if (lastST + dt) < 0 then
                do
                    lastSegment -= 1
                    if lastSegment < 0 then
                        lastCurve -= 1
                        if lastCurve < 0 then
                            lastCurve = -1
                            HCF("parameter less than 0")
                            return Vector3D(0,0,0)
                        else
                            if bezier[lastCurve].mustCompute = s2_TRUE then computeBezier(lastCurve)
                        end if
                        lastSegment = bezier[lastCurve].segment_N - 1
                    end if
                    dt += rDist
                    rDist = bezier[lastCurve].segment[lastSegment].length
                loop while (abs(dt) - rDist) > 0.0000001
            end if
            lastST = rDist + dt
            lastT  = t
            lastTangent = bezier[lastCurve].segment[lastSegment].v
            return lastST * bezier[lastCurve].segment[lastSegment].v + bezier[lastCurve].segment[lastSegment].a       
        end if
    end if
end function

function Spline2.seekPoint(t as double) as Vector3D
    dim as integer i
    dim as integer seekS
    dim as integer seekP
    dim as double  curLength
    dim as double  loI, hiI, midI
    dim as double  ot
    
    SUFFICIENT_POINTS_START()
        return Vector3D(0,0,0)
    SUFFICIENT_POINTS_END()
    
    if t < 0 then
        HCF("parameter less than 0")
        return Vector3D(0,0,0)
    end if
    
    ot = t
    
    seekS = -1
    curLength = 0
    for i = 0 to bezier_N - 1
        if bezier[i].mustCompute = s2_TRUE then computeBezier(i)
        if (t >= curLength) andAlso (t < (curLength + bezier[i].length)) then 
            seekS = i
            exit for
        end if
        curLength += bezier[i].length
    next i

    if seekS = -1 then
        HCF("parameter greater than curve length")
        return Vector3D(0,0,0)
    end if
    t -= curLength
    
    loI = 0
    hiI = bezier[seekS].segment_N - 1
    do
        if hiI - loI >= 2 then
            midI = int((loI + hiI) * 0.5)
            if t < (bezier[seekS].segment[midI].a_length) then 
                hiI = midI
            elseif t >= (bezier[seekS].segment[midI].a_length + bezier[seekS].segment[midI].length) then
                loI = midI
            else
                seekP = midI
                exit do
            end if
        else
            if t < bezier[seekS].segment[hiI].a_length then
                seekP = loI
            else
                seekP = hiI
            end if
            exit do
        end if
    loop
    t -= bezier[seekS].segment[seekP].a_length
    
    lastST = t
    lastCurve = seekS
    lastSegment = seekP
    lastT = ot
    lastTangent = bezier[seekS].segment[seekP].v
    
    return t * bezier[seekS].segment[seekP].v + bezier[seekS].segment[seekP].a
end function

sub Spline2.computeBezier(i as integer)
    dim as Vector3D p0, p1, p2
    dim as integer q, numSegs
    dim as double segS, curS, lastL
    dim as Vector3D curP, lastP, d0, d1

    p0 = getbezierPoint(i, 0)
    p1 = getbezierPoint(i, 1)
    p2 = getbezierPoint(i, 2)
    with bezier[i]        
        .c0 = p0
        .c1 = 2*(p1 - p0)
        .c2 = p0 - 2*p1 + p2
        
        d0 = p2 - p1
        d1 = p1 - p0
        d0 = d0.normalize()
        d1 = d1.normalize()
        if abs(d0 * d1) > 0.999999 then
            if .c2 = Vector3D(0,0,0) then
                .arcConst.c = 0
                .arcConst.mag = .c1.magnitude()
                .arcConst.zero = 0
            else
                d0 = p2 - p0
                .arcConst.c = 0
                .arcConst.mag = d0.magnitude()
                .arcConst.zero = 0
            end if
        else
            computeIntegrationConstants(.c1, .c2, .arcConst)
        end if
    
        .mustCompute = s2_FALSE
        
        if .segment <> 0 then 
            deallocate(.segment)
            .segment = 0
            .segment_N = 0
        end if
                
        .segment_N = iif(.arcConst.mag < 100, 20, .arcConst.mag * 0.2)
        .segment = allocate(sizeof(s2_Segment) * .segment_N)
        segS = 1 / .segment_N
            
        lastP = .c0
        lastL = 0
        for q = 0 to .segment_N - 1
            curS = (q + 1) * segS
            curP = ((.c2 * curS) + .c1) * curS + .c0
        
            .segment[q].a = lastP
            .segment[q].b = curP
            .segment[q].v = .segment[q].b - .segment[q].a
            .segment[q].length = .segment[q].v.magnitude()
            .segment[q].v /= .segment[q].length
            .segment[q].a_length = lastL
            
            lastL += .segment[q].length
            lastP = curP
        next q
        .length = lastL
        
    end with
    
end sub

sub Spline2.computeIntegrationConstants(c1 as Vector3D,_
                                        c2 as Vector3D,_
                                        byref arcConst as s2_ArcConst)         
    dim as double deriv, mag, param
    dim as Vector3D nB, nC
    dim as double div
    
    with arcConst
        
        nB = c1
        nC = 2*c2
            
        .a = nB * nB
        .b = 2 * nB * nC
        .c = nC * nC
             
        .derivSq = .b*.b - 4*.a*.c
        .sqr2c = 2 * sqr(.c)
        .sqr3c_div = 1 / (8 * sqr(.c*.c*.c))
        div = -1 / sqr(.a - (.b*.b) / (4*.c))
                    
        .asinhx = .sqr2c * div * 0.5
        .asinh = .b / .sqr2c * div
        
        .zero = (.sqr2c*.b*Sqr(.a) + .derivSq*Log(.asinh + Sqr(.asinh*.asinh + 1))) * .sqr3c_div
                    
        deriv = .b + 2*.c
        mag = Sqr(.a + .b + .c)
        param = .asinh + .asinhx
        .mag = (.sqr2c*deriv*mag + .derivSq*Log(param + Sqr(param*param + 1))) * .sqr3c_div - .zero
     
        .inflect = (-2 * c1 * c2) / (4 * c2 * c2)
    
    end with
end sub

function Spline2.integrate(p as double, arcConst as s2_ArcConst) as double
    
    dim as double deriv, mag, param, ret

    with arcConst
        
        if .c = 0 then

            return arcConst.mag * p
            
        else
        
            deriv = .b + 2*.c*p
            mag = Sqr(.a + p*(.b + .c*p))
            param = .asinh + .asinhx*p
            ret = (.sqr2c*deriv*mag + .derivSq*Log(param + Sqr(param*param + 1))) * .sqr3c_div
            
            return ret - .zero
            
        end if
        
    end with
    
end function

function Spline2.createAnchor(pt_i as double) as s2_tag    
    dim as integer i
    dim as integer ind
    dim as integer increaseSize
    dim as double  curLength
    dim as integer seekS
    dim as double  hiP, loP, midP
    dim as double  arcTarget
    
    SUFFICIENT_POINTS_START()
        return S2_INVALID_TAG
    SUFFICIENT_POINTS_END()
    
    if pt_i < 0 then
        HCF("parameter less than 0")
        return S2_INVALID_TAG
    end if
    
    ind = -1
    increaseSize = 1
    if anchor_cap <> 0 then
        for i = 0 to anchor_cap - 1
            if anchor[i].exist = 0 then
                ind = i
                increaseSize = 0
                exit for
            end if
        next i
    end if
    if increaseSize = 1 then
        anchor_cap += S2_DYN_ARRAY_COARSE
        anchor = reallocate(anchor, sizeof(s2_Anchor) * anchor_cap)
        for i = (anchor_cap - S2_DYN_ARRAY_COARSE) to (anchor_cap - 1)
            anchor[i].exist = 0
        next i
        ind = anchor_cap - S2_DYN_ARRAY_COARSE + 1
    end if
    
    curLength = 0
    seekS = -1
    for i = 0 to bezier_N - 1
        if bezier[i].mustCompute = s2_TRUE then computeBezier(i)
        if (pt_i >= curLength) andAlso (pt_i < (curLength + bezier[i].length)) then 
            seekS = i
            exit for
        end if
        curLength += bezier[i].length
    next i
    
    if seekS = -1 then
        HCF("parameter greater than curve length")
        return S2_INVALID_TAG
    end if
    
    pt_i -= curLength

    
    anchor[ind].exist = 1
    anchor[ind].curve = seekS    
    anchor[ind].parameter = invertParameter(pt_i, bezier[seekS].arcConst)
    anchor_N += 1

    return ind
end function

sub Spline2.removeAnchor(tag as s2_tag)             
    if (tag < 0) orElse (tag >= anchor_cap) then
        HCF("tag out of range")
        exit sub
    end if
    
    if anchor[tag].exist = 1 then
        anchor[tag].exist = 0
    else
        HCF("tag does not correspond to an existing anchor")
    end if
end sub

function Spline2.getAnchor(tag as s2_tag) as Vector3D  
    dim as double p
    dim as integer curve
    dim as Vector3D ret
    if (tag < 0) orElse (tag >= anchor_cap) then
        HCF("tag out of range")
        return Vector3D(0,0,0)
    end if
    
    if anchor[tag].exist = 1 then
        p = anchor[tag].parameter
        curve = anchor[tag].curve
        if bezier[curve].mustCompute = S2_TRUE then computeBezier(curve)
        lastTangent = bezier[curve].c2*p*2 + bezier[curve].c1
        lastTangent = lastTangent.normalize()
        return ((bezier[curve].c2*p) + bezier[curve].c1)*p + bezier[curve].c0
    else
        HCF("tag does not correspond to an existing anchor")
        return Vector3D(0,0,0)
    end if   
end function

function Spline2.getAnchorArc(tag as s2_tag) as double  
    dim as double p
    dim as integer curve
    dim as Vector3D ret
    dim as double curLength
    dim as integer i
    
    if (tag < 0) orElse (tag >= anchor_cap) then
        HCF("tag out of range")
        return 0
    end if
    
    if anchor[tag].exist = 1 then
        
        curLength = 0
        for i = 0 to anchor[tag].curve - 2
            if bezier[i].mustCompute = s2_TRUE then computeBezier(i)
            curLength += bezier[i].length
        next i
        
        return curLength + integrate(anchor[tag].parameter, bezier[anchor[tag].curve].arcConst)
        
    else
        HCF("tag does not correspond to an existing anchor")
        return 0
    end if      
end function

function Spline2.getTangent() as Vector3D
    SUFFICIENT_POINTS_START()
        return Vector3D(0,0,0)
    SUFFICIENT_POINTS_END()
    
    if lastTangent = Vector3D(0,0,0) then
        HCF("no tangent computed")
    end if
    
    return lastTangent
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


function Spline2.invertParameter(arc_i as double, arcConst as s2_ArcConst) as double
    dim as double loP, hiP, midP
    dim as double arcTarget
    dim as integer i
    
    hiP = 1
    loP = 0
    i = 0
    do
        midP = (loP + hiP) * 0.5
        arcTarget = integrate(midP, arcConst)
        if abs(arcTarget - arc_i) < 0.000001 then
            return midP
        elseif arcTarget > arc_i then
            hiP = midP
        else
            loP = midP
        end if
        i += 1
    loop until i >= 100
    
    HCF("root finding failed")
    
    return 0
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

