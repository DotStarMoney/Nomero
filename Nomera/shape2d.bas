#include "shape2d.bi"
#include "vector2d.bi"

constructor Point2D()
end constructor
constructor Point2D(p_ as Vector2D)
    setP(p_)
end constructor
sub Point2D.setP(p_ as Vector2D)
    p = p_
end sub
function Point2D.getP() as Vector2D
    return p
end function
sub Point2D.getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D)
    tl_ = p
    br_ = p
end sub
constructor Rectangle2D()
end constructor
constructor Rectangle2D(tl_ as Vector2D, br_ as Vector2D)
    set(tl_, br_)
end constructor
sub Rectangle2D.set(tl_ as Vector2D, br_ as Vector2D)
    tl = tl_
    br = br_
end sub
sub Rectangle2D.setTL(tl_ as Vector2D)
    tl = tl_
end sub
sub Rectangle2D.setBR(br_ as Vector2D)
    br = br_
end sub
function Rectangle2D.getTL() as Vector2D
    return tl
end function
function Rectangle2D.getBR() as Vector2D
    return br
end function
sub Rectangle2D.getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D)
    tl_ = tl
    br_ = br
end sub
constructor Circle2D()
end constructor
constructor Circle2D(p_ as Vector2D, r_ as double)
    set(p_, r_)
end constructor
sub Circle2D.set(p_ as Vector2D, r_ as double)
    p = p_
    r = r_
end sub
sub Circle2D.setP(p_ as Vector2D)
    p = p_
end sub
sub Circle2D.setR(r_ as double)
    r = r_
end sub
function Circle2D.getP() as Vector2D
    return P
end function
function Circle2D.getR() as double
    return r
end function
sub Circle2D.getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D)
    tl_ = p - Vector2D(r, r)
    br_ = p + Vector2D(r, r)
end sub
constructor Polygon2D()
    points_n = 0
    points = 0 
    sub_points_n = 0
    sub_points = 0
    sub_polys_n = 0
    hasWinding = 0
    hasBounds = 0
end constructor
constructor Polygon2D(points_ as Vector2D ptr, points_n_ as integer)
    points_n = 0
    points = 0 
    sub_points_n = 0
    sub_points = 0
    sub_polys_n = 0
    hasWinding = 0
    hasBounds = 0
    set(points_, points_n_)
end constructor
destructor Polygon2D()
    clearDecomp()
    if points_n then deallocate(points)
    if sub_points then deallocate(sub_points)
    if sub_points_n then deallocate(sub_points_n)
end destructor
sub Polygon2D.clearDecomp()
    dim as integer i
    if sub_polys_n then
        for i = 0 to sub_polys_n - 1
            deallocate(sub_points[i])
        next i
        sub_polys_n = 0
    end if
end sub
sub Polygon2D.set(points_ as Vector2D ptr, points_n_ as integer)
    dim as integer i
    clearDecomp()
    points_n = points_n_ + 1
    points = reallocate(points, sizeof(Vector2D) * points_n)
    for i = 0 to points_n - 2
        points[i] = points_[i]
    next i
    points[points_n - 1] = points[0]
    forceCCW()
    calculateDecomp()
    calculateBounds()
end sub
sub Polygon2D.forceCCW()
    #define AT_MINUS_ONE(_I_) iif((_I_ = 0), points[points_n - 2], points[_I_ - 1 ])
    #define AT_PLUS_ONE(_I_) points[_I_ + 1]
    #define AT(_I_) points[_I_]
    
    dim as integer br, i
    if hasWinding then exit sub
    br = 0
    for i = 0 to points_n - 2
        if (points[i].y < points[br].y) orElse ((points[i].y = points[br].y) andAlso (points[i].x > points[br].x)) then
            br = i
        end if
    next i
    if dCross(AT_MINUS_ONE(br), AT(br), AT_PLUS_ONE(br)) <= 0 then
        for i = 0 to (points_n - 1) * 0.5
            swap AT(i), AT(points_n - i)
        next i
    end if
    hasWinding = 1
end sub
sub Polygon2D.setPoint(i as integer, p as Vector2D)
    points[i] = p
    clearDecomp()
    hasBounds = 0
    hasWinding = 0
end sub
sub Polygon2D.offset(o as Vector2D)
    dim as integer i, j
    for i = 0 to points_n - 1
        points[i] += o
    next i
    if sub_polys_n then
        for i = 0 to sub_polys_n - 1
            for j = 0 to sub_points_n[i] - 1
                sub_points[i][j] += o
            next j
        next i
    end if    
    if hasBounds then
        tl += o
        br += o
    end if
end sub
function Polygon2D.getPoint_N() as integer
    return points_n 
end function
function Polygon2D.getPoint(i as integer) as Vector2D
    return points[i]
end function
function Polygon2D.lineSegIntersection(p1 as Vector2D, p2 as Vector2D,_
                                       q1 as Vector2D, q2 as Vector2D) as Vector2D
    dim as Vector2d ret
    dim as double a1, b1, c1, a2, b2, c2, det
    ret = Vector2D(0,0)
    a1 = p2.y - p1.y
    b1 = p1.x - p2.x
    c1 = a1 * p1.x + b1 * p1.y
    a2 = q2.y - q1.y
    b2 = q1.x - q2.x
    c2 = a2 * q1.x + b2 * q1.y
    det = a1 * b2 - a2*b1
    if abs(det) > 1e-8 then
        ret.xs = (b2 * c1 - b1 * c2) / det
        ret.ys = (a1 * c2 - a2 * c1) / det        
    end if
    return ret             
end function
function Polygon2D.dCross(a as Vector2D, b as Vector2D, c as Vector2D) as double
    dim as Vector2D v0, v1
    v0 = b - a
    v1 = c - a
    return v0.cross(v1)
end function
sub Polygon2D.recDecomp(interestPoints as Vector2D ptr, numInterestPoints as integer, interestIndex as integer, _
                        polys_points as Vector2D ptr ptr, polys_points_n as integer ptr, _
                        byref polys_n as integer)
    #define AT_MINUS_ONE(_I_) iif((_I_ = 0), interestPoints[numInterestPoints - 2], interestPoints[_I_ - 1])
    #define AT_PLUS_ONE(_I_) iif((_I_ = (numInterestPoints - 2)), interestPoints[0], interestPoints[_I_ + 1])
    #define AT(_I_) interestPoints[_I_]
                        
    dim as Vector2D v0, v1
    dim as Vector2D upperInt, lowerInt, p, closestVert
    dim as Vector2D ptr upperPoly, lowerPoly
    dim as Vector2D dv
    dim as double upperDist, lowerDist, d, closestDist
    dim as integer upperIndex, lowerIndex, closestIndex, lowerPoly_n, upperPoly_n
    dim as integer i, j, jr
    
    for i = 0 to numInterestPoints - 2
        if dCross(AT_MINUS_ONE(i), AT(i), AT_PLUS_ONE(i)) < 0 then
            polys_points[polys_n] = allocate(sizeof(Vector2D) * (numInterestPoints - 1))
            polys_points[polys_n + 1] = allocate(sizeof(Vector2D) * (numInterestPoints - 1))
            lowerPoly = polys_points[polys_n]
            lowerPoly_n = 0
            upperPoly = polys_points[polys_n + 1]  
            upperPoly_n = 0
            upperDist = 1.797693134862316e+308
            lowerDist = 1.797693134862316e+308
            'cls
            'print "i = " + str(i)
            for j = 0 to numInterestPoints - 2
            
                'circle (AT(i).x, AT(i).y), 5, &h0000ff,,,,F
                'circle (AT(j).x, AT(j).y), 6, &h00ffff
                'print "i and j"
                'sleep

                if (dCross(AT_MINUS_ONE(i), AT(i), AT(j)          ) >  0) andAlso _
                   (dCross(AT_MINUS_ONE(i), AT(i), AT_MINUS_ONE(j)) <= 0) then
                    p = lineSegIntersection(AT_MINUS_ONE(i), AT(i), AT(j), AT_MINUS_ONE(j))
                   
                    'line (AT_MINUS_ONE(i).x, AT_MINUS_ONE(i).y)-(AT(i).x, AT(i).y), &hffff00
                    'line (AT(j).x, AT(j).y)-(AT_MINUS_ONE(j).x, AT_MINUS_ONE(j).y), &h00ff00
                    'circle (p.x, p.y), 3, &h0000ff
                    'print "lowerDist intersection at j = " + str(j)       
                    'sleep
                    
                    if (dCross(AT_PLUS_ONE(i), AT(i), p) < 0) then
                        dv = AT(i) - p
                        d = dv.magnitude()
                        if d < lowerDist then
                            lowerDist = d
                            lowerInt = p
                            lowerIndex = j
                        end if
                    end if
                end if
                if (dCross(AT_PLUS_ONE(i), AT(i), AT_PLUS_ONE(j)) >  0) andAlso _
                   (dCross(AT_PLUS_ONE(i), AT(i), AT(j)         ) <= 0) then
                    p = lineSegIntersection(AT_PLUS_ONE(i), AT(i), AT(j), AT_PLUS_ONE(j))
                    
                    'line (AT_PLUS_ONE(i).x, AT_PLUS_ONE(i).y)-(AT(i).x, AT(i).y), &hffff00
                    'line (AT(j).x, AT(j).y)-(AT_PLUS_ONE(j).x, AT_PLUS_ONE(j).y), &h00ff00
                    'circle (p.x, p.y), 3, &h0000ff
                    'print "upperDist intersection at j = " + str(j)
                    'sleep
                    
                    if (dCross(AT_MINUS_ONE(i), AT(i), p) > 0) then
                        dv = AT(i) - p
                        d = dv.magnitude()
                        if d < upperDist then
                            upperDist = d
                            upperInt = p
                            upperIndex = j
                        end if
                    end if
                end if
            next j
            
            'circle (AT(lowerIndex).x, AT(lowerIndex).y), 4, &h00FFff,,,,F
            'circle (AT(upperIndex).x, AT(upperIndex).y), 5, &hff00ff,,,,F    
            'print "lower ("+str(lowerIndex)+") and upper (" + str(upperIndex) + ") index"
            'sleep
            
            if lowerIndex = ((upperIndex + 1) mod (numInterestPoints - 1)) then
                'print "lower and upper index adjacent"
                'sleep
                
                p.xs = (lowerInt.x + upperInt.x) * 0.5
                p.ys = (lowerInt.y + upperInt.y) * 0.5
                if i < upperIndex then
                    for j = i to upperIndex
                        lowerPoly[lowerPoly_n + (j - i)] = interestPoints[j]
                    next j
                    lowerPoly_n += (upperIndex - i) + 2
                    lowerPoly[lowerPoly_n - 1] = p
                    upperPoly[upperPoly_n] = p
                    upperPoly_n += 1
                    if lowerIndex <> 0 then
                        for j = lowerIndex to numInterestPoints - 2
                            upperPoly[upperPoly_n + (j - lowerIndex)] = interestPoints[j]
                        next j                    
                        upperPoly_n += (numInterestPoints - 2 - lowerIndex) + 1
                    end if
                    for j = 0 to i
                        upperPoly[upperPoly_n + j] = interestPoints[j]
                    next j                    
                    upperPoly_n += i + 1                    
                else
                    if i <> 0 then
                        for j = i to numInterestPoints - 3
                            lowerPoly[lowerPoly_n + (j - i)] = interestPoints[j]
                        next j
                        lowerPoly_n += (numInterestPoints - 3 - i) + 1                       
                    end if
                    for j = 0 to upperIndex
                        lowerPoly[lowerPoly_n + j] = interestPoints[j]
                    next j
                    lowerPoly_n += upperIndex + 2                      
                    lowerPoly[lowerPoly_n - 1] = p
                    upperPoly[upperPoly_n] = p
                    upperPoly_n += 1
                    for j = lowerIndex to i
                        upperPoly[upperPoly_n + (j - lowerIndex)] = interestPoints[j]
                    next j                    
                    upperPoly_n += i - lowerIndex + 1   
                end if
            else
                'print "lower and upper index are not adjacent"
                'sleep
                
                'if lowerIndex > upperIndex then
                '    print "lower index greater than upper index"
                '    sleep   
                'end if
                
                if lowerIndex > upperIndex then upperIndex += numInterestPoints - 1
                
                closestDist = 1.797693134862316e+308
                for j = lowerIndex to upperIndex
                    jr = j mod (numInterestPoints - 1)
                    if jr <> (numInterestPoints - 1) then
                        'print "testing point " + str(jr) + " for closeness."
                        'print jr, numInterestPoints - 2
                        'circle (AT(jr).x, AT(jr).y), 5, &hff7fff,,,,F
                        'sleep
                        if (dCross(AT_MINUS_ONE(i), AT(i), AT(jr)) >= 0) andALso _
                           (dCross(AT_PLUS_ONE(i) , AT(i), AT(jr)) <= 0) then
                            'print "checking candidate point " + str(jr) + " for closeness."
                            'circle (AT(jr).x, AT(jr).y), 2, &hff,,,,F
                            'sleep
                            dv = AT(i) - AT(jr)
                            d = dv.magnitude()
                            if d < closestDist then
                                closestDist  = d
                                closestVert  = AT(jr)
                                closestIndex = jr 
                            end if
                        end if      
                    end if
                next j
                
                'circle (AT(closestIndex).x, AT(closestIndex).y), 7, &hff7f00 ,,,,F
                'print "closest index"
                'sleep
                
                if i < closestIndex then
                    'circle (AT(i).x, AT(i).y), 9, &hff0000,,,,F
                    'circle (AT(closestIndex).x, AT(closestIndex).y), 10, &hffff00,,,,F
                    'print "i and closest index, i < closest index"
                    'sleep 
                    
                    for j = i to closestIndex
                        lowerPoly[lowerPoly_n + (j - i)] = interestPoints[j]
                        'circle (interestPoints[j].x, interestPoints[j].y), 8, &hff00ff,,,,F
                        'print "adding " + str(j) + " to lowerPoly[" + str(j - i + lowerPoly_n) + "]"
                        'sleep          
                    next j
                    lowerPoly_n += closestIndex - i + 1
                    'print "lowerPoly_n = " + str(lowerPoly_n)
                    'sleep
                    if closestIndex <> 0 then
                        for j = closestIndex to numInterestPoints - 2
                            upperPoly[upperPoly_n + (j - closestIndex)] = interestPoints[j]
                        next j                    
                        upperPoly_n += numInterestPoints - 2 - closestIndex + 1                     
                    end if
                    for j = 0 to i
                        upperPoly[upperPoly_n + j] = interestPoints[j]
                    next j                    
                    upperPoly_n += i + 1  
                else
                    'circle (AT(i).x, AT(i).y), 2, &hff0000
                    'circle (AT(closestIndex).x, AT(closestIndex).y), 2, &hffff00
                    'print "i and closest index, i > closest index"
                    'sleep
                    
                    
                    if i <> 0 then 
                        for j = i to numInterestPoints - 2
                            lowerPoly[lowerPoly_n + (j - i)] = interestPoints[j]
                        next j
                        lowerPoly_n += numInterestPoints - 2 - i + 1                    
                    end if
                    for j = 0 to closestIndex
                        lowerPoly[lowerPoly_n + j] = interestPoints[j]
                    next j
                    lowerPoly_n += closestIndex + 1
                    for j = closestIndex to i
                        upperPoly[upperPoly_n + (j - closestIndex)] = interestPoints[j]
                    next j                    
                    upperPoly_n += (i - closestIndex) + 1
                end if
            end if
            
            upperPoly = reallocate(upperPoly, sizeof(Vector2D)*(upperPoly_n + 1))
            upperPoly[upperPoly_n] = upperPoly[0]
            upperPoly_n += 1
            
            lowerPoly = reallocate(lowerPoly, sizeof(Vector2D)*(lowerPoly_n + 1))
            lowerPoly[lowerPoly_n] = lowerPoly[0]
            'circle (lowerPoly[lowerPoly_n].x, lowerPoly[lowerPoly_n].y), 4, &hffffff,,,,F
            'print "adding first point to lowerPoly[" + str(lowerPoly_n) + "] to form ring"
            'sleep
            lowerPoly_n += 1
            'print "lowerPoly_n = " + str(lowerPoly_n)
            'sleep           
            
            /'
            dim as integer col 
            col = rnd * &hffffff
            for j = 0 to lowerPoly_n - 2
                line (lowerPoly[j].x, lowerPoly[j].y)-_
                     (lowerPoly[j + 1].x, lowerPoly[j + 1].y), &h0000ff
                sleep
            next j
             col = rnd * &hffffff
            for j = 0 to upperPoly_n - 2
                line (upperPoly[j].x, upperPoly[j].y)-_
                     (upperPoly[j + 1].x, upperPoly[j + 1].y), &hff7f00
                sleep
            next j
            '/
            
            deallocate(interestPoints) 
            polys_points[interestIndex] = upperPoly
            polys_points_n[interestIndex] = upperPoly_n
            polys_points_n[polys_n] = lowerPoly_n
            
            polys_n += 1
            
            if lowerPoly_n <= upperPoly_n then
                recDecomp(lowerPoly, lowerPoly_n, polys_n - 1, polys_points, polys_points_n, polys_n)
                recDecomp(upperPoly, upperPoly_n, interestIndex, polys_points, polys_points_n, polys_n)                
            else
                recDecomp(upperPoly, upperPoly_n, interestIndex, polys_points, polys_points_n, polys_n) 
                recDecomp(lowerPoly, lowerPoly_n, polys_n - 1, polys_points, polys_points_n, polys_n)                
            end if
            exit sub
        end if
    next i
end sub
sub Polygon2D.calculateDecomp()
    dim as integer i
    sub_points = reallocate(sub_points, sizeof(Vector2D ptr) * (points_n / 3 + 2))
    sub_points_n =  reallocate(sub_points_n, sizeof(integer) * (points_n / 3 + 2))
    
    sub_polys_n = 1
    sub_points_n[0] = points_n
    sub_points[0] = allocate(sizeof(Vector2D) * points_n)
    for i = 0 to points_n - 1
        sub_points[0][i] = points[i]
    next i
    
    recDecomp(sub_points[0], sub_points_n[0], 0, sub_points, sub_points_n, sub_polys_n)
    
    sub_points = reallocate(sub_points, sizeof(Vector2D ptr) * sub_polys_n)
    sub_points_n = reallocate(sub_points_n, sizeof(integer) * sub_polys_n)
end sub
sub Polygon2D.ensureDecomp()
    if sub_polys_n = 0 then
        forceCCW()
        calculateDecomp()
    end if
end sub
function Polygon2D.getSubPoly_N() as integer
    return sub_polys_n 
end function
function Polygon2D.getSubPolyPoint_N(i as integer) as integer    
    return sub_points_n[i]
end function
function Polygon2D.getSubPolyPoint(i as integer, j as integer) as Vector2D   
    return sub_points[i][j]
end function
sub Polygon2D.calculateBounds()
    dim as double min_x, max_x
    dim as double min_y, max_y
    dim as integer i
    if points then
        min_x = points[0].x
        max_x = min_x
        min_y = points[0].y
        max_y = min_y
        for i = 1 to points_n - 2
            if points[i].x < min_x then 
                min_x = points[i].x
            elseif points[i].x > max_x then
                max_x = points[i].x
            end if
            if points[i].y < min_y then 
                min_y = points[i].y
            elseif points[i].y > max_y then
                max_y = points[i].y
            end if
        next i
        tl = Vector2D(min_x, min_y)
        br = Vector2D(max_x, max_y)
        hasBounds = 1
    end if
end sub
sub Polygon2D.getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D)
    if hasBounds = 0 then calculateBounds()
    tl_ = tl
    br_ = br
end sub


function intersect2D(a as Shape2D, b as Shape2D) as integer
    if a is Point2D then
        if b is Point2D then
            return intersect2D_pp(cast(Point2D ptr, @a), cast(Point2D ptr, @b))
        elseif b is Rectangle2D then
            return intersect2D_ps(cast(Point2D ptr, @a), cast(Rectangle2D ptr, @b))        
        elseif b is Circle2D then
            return intersect2D_pc(cast(Point2D ptr, @a), cast(Circle2D ptr, @b))                
        elseif b is Polygon2D then
            return intersect2D_py(cast(Point2D ptr, @a), cast(Polygon2D ptr, @b))                        
        end if    
    elseif a is Rectangle2D then
        if b is Point2D then
            return intersect2D_ps(cast(Point2D ptr, @b), cast(Rectangle2D ptr, @a))
        elseif b is Rectangle2D then
            return intersect2D_ss(cast(Rectangle2D ptr, @a), cast(Rectangle2D ptr, @b))        
        elseif b is Circle2D then
            return intersect2D_sc(cast(Rectangle2D ptr, @a), cast(Circle2D ptr, @b))                
        elseif b is Polygon2D then
            return intersect2D_sy(cast(Rectangle2D ptr, @a), cast(Polygon2D ptr, @b))                        
        end if        
    elseif a is Circle2D then
        if b is Point2D then
            return intersect2D_pc(cast(Point2D ptr, @b), cast(Circle2D ptr, @a))
        elseif b is Rectangle2D then
            return intersect2D_sc(cast(Rectangle2D ptr, @b), cast(Circle2D ptr, @a))        
        elseif b is Circle2D then
            return intersect2D_cc(cast(Circle2D ptr, @a), cast(Circle2D ptr, @b))                
        elseif b is Polygon2D then
            return intersect2D_cy(cast(Circle2D ptr, @a), cast(Polygon2D ptr, @b))                        
        end if       
    elseif a is Polygon2D then
        if b is Point2D then
            return intersect2D_py(cast(Point2D ptr, @b), cast(Polygon2D ptr, @a))
        elseif b is Rectangle2D then
            return intersect2D_sy(cast(Rectangle2D ptr, @b), cast(Polygon2D ptr, @a))        
        elseif b is Circle2D then
            return intersect2D_cy(cast(Circle2D ptr, @b), cast(Polygon2D ptr, @a))                
        elseif b is Polygon2D then
            return intersect2D_yy(cast(Polygon2D ptr, @a), cast(Polygon2D ptr, @b))                        
        end if           
    end if
    return 0
end function

function intersect2D_pp(a as Point2D ptr, b as Point2D ptr) as integer
    if (a->getP().x = b->getP().x) andAlso (a->getP().y = b->getP().y) then return 1
    return 0
end function
function intersect2D_ps(a as Point2D ptr, b as Rectangle2D ptr) as integer
    if (a->getP().x >= b->getTL().x) andAlso (a->getP().y >= b->getTL().y) andAlso _
       (a->getP().x <= b->getBR().x) andAlso (a->getP().y <= b->getBR().y) then
        return 1
    end if
    return 0
end function
function intersect2D_pc(a as Point2D ptr, b as Circle2D ptr) as integer
    dim as Vector2D d
    d = a->getP() - b->getP()
    if d.magnitude() <= b->getR() then return 1
    return 0
end function
function intersect2D_py(a as Point2D ptr, b as Polygon2D ptr) as integer
    dim as integer winding
    dim as integer i
    dim as Vector2D v0, v1
    winding = 0
    b->forceCCW()
    for i = 0 to b->getPoint_N() - 2
        if (b->getPoint(i).y <= a->getP().y()) then
            if (b->getPoint(i + 1).y > a->getP().y()) then
                v0 = b->getPoint(i + 1) - b->getPoint(i)
                v1 = a->getP() - b->getPoint(i)
                if v0.cross(v1) > 0 then winding += 1
            end if
        else
            if (b->getPoint(i + 1).y <= a->getP().y()) then
                v0 = b->getPoint(i + 1) - b->getPoint(i)
                v1 = a->getP() - b->getPoint(i)
                if v0.cross(v1) < 0 then winding -= 1
            end if        
        end if
    next i
    if winding then
        return 1
    else
        return 0
    end if
end function

function intersect2D_ss(a as Rectangle2D ptr, b as Rectangle2D ptr) as integer
    if (a->getBR().x >= b->getTL().x) andAlso (a->getTL().x <= b->getBR().x) andALso _
       (a->getBR().y >= b->getTL().y) andAlso (a->getTL().y <= b->getBR().y) then
        return 1
    end if
    return 0
end function
function intersect2D_sc(a as Rectangle2D ptr, b as Circle2D ptr) as integer
    dim as double dx, dy, x, y, rad
    dim as integer c
    c = 0
    x = b->getP().x
    rad = b->getR() * b->getR()
    if x < a->getTL().x then
        x = a->getTL().x
        c = 1
    elseif x > a->getBR().x then
        x = a->getBR().x
        c = 1
    end if
    x = x - b->getP().x
    x *= x
    dy = a->getTL().y - b->getP().y
    dy *= dy
    if x + dy <= rad then return 1
    dy = a->getBR().y - b->getP().y
    dy *= dy
    if x + dy <= rad then return 1
    y = b->getP().y
    if y < a->getTL().y then
        y = a->getTL().y
        c = 1
    elseif y > a->getBR().y then
        y = a->getBR().y
        c = 1
    end if
    y = y - b->getP().y
    y *= y
    dx = a->getTL().x - b->getP().x
    dx *= dx
    if y + dx <= rad then return 1
    dx = a->getBR().x - b->getP().x
    dx *= dx
    if y + dx <= rad then return 1
    if c = 0 then return 1
    return 0
end function

function intersect2D_sy(a as Rectangle2D ptr, b as Polygon2D ptr) as integer
    dim as integer i, j, q
    dim as Vector2D pnt
    dim as Vector2D bse
    dim as Vector2D vec
    dim as Vector2D perp
    dim as Vector2D proj
    dim as integer failed
    b->forceCCW()
    for i = 0 to b->getSubPoly_N() - 1
        for q = 0 to 3
            select case q
            case 0
                bse = a->getTL()
                vec = Vector2D(1, 0)
                perp = Vector2D(0, 1)
            case 1
                bse = Vector2D(a->getBR().x, a->getTL().y)
                vec = Vector2D(0, 1)
                perp = Vector2D(-1, 0)
            case 2
                bse = a->getBR()
                vec = Vector2D(-1, 0)
                perp = Vector2D(0, -1)            
            case 3
                bse = Vector2D(a->getTL().x, a->getBR().y)
                vec = Vector2D(0, -1)
                perp = Vector2D(1, 0) 
            end select
            failed = 0
            for j = 0 to b->getSubPolyPoint_N(i) - 2
                pnt = b->getSubPolyPoint(i, j)
                proj = (((pnt - bse) * vec) * vec + bse)
                if (proj - pnt) * perp <= 0 then
                    failed = 1
                    exit for
                end if
            next j
            if failed = 0 then exit for
        next q
        if failed = 1 then
            for q = 0 to b->getSubPolyPoint_N(i) - 2
                bse = b->getSubPolyPoint(i, q)
                vec = b->getSubPolyPoint(i, q + 1) - bse
                vec.normalize()
                perp = vec.perp()
                failed = 0
                for j = 0 to 3
                    select case j
                    case 0
                        pnt = a->getTL()
                    case 1
                        pnt = Vector2D(a->getBR().x, a->getTL().y)
                    case 2
                        pnt = a->getBR()        
                    case 3
                        pnt = Vector2D(a->getTL().x, a->getBR().y)
                    end select   
                    proj = (((pnt - bse) * vec) * vec + bse)                    
                    if (proj - pnt) * perp <= 0 then
                        failed = 1
                        exit for
                    end if                    
                next j
                if failed = 0 then exit for
            next q     
        end if
        if failed = 1 then return 1
    next i
    return 0
end function

function intersect2D_cc(a as Circle2D ptr, b as Circle2D ptr) as integer
    dim as Vector2D d
    d = a->getP() - b->getP()
    if d.magnitude() <= (b->getR() + a->getR()) then return 1   
    return 0
end function

    
function intersect2D_cy(a as Circle2D ptr, b as Polygon2D ptr) as integer
    b->forceCCW()

    return 0
end function

function intersect2D_yy(a as Polygon2D ptr, b as Polygon2D ptr) as integer
    b->forceCCW()

    return 0
end function


screenres 640,480,32

dim as Vector2D samplePoly(0 to 10) = {Vector2D(183, 88), Vector2D(411, 117), Vector2D(329, 252), _
                                       Vector2D(497, 373), Vector2D(297, 418), Vector2D(264, 275), _
                                       Vector2D(100, 416), Vector2D(166, 303), Vector2D(74, 204), _
                                       Vector2D(92, 94), Vector2D(180, 216)}

Dim as Polygon2D test
Dim as Point2D p
dim as Circle2D c
dim as Rectangle2D r
dim as Vector2D tl, br
dim as integer i, j, col, mx, my,x , y

test.set(@samplePoly(0), 11)
do
    cls
    getmouse mx, my
    randomize 13
    for i = 0 to test.getSubPoly_N() - 1
        col = rgb(128 + rnd*128, 128+rnd * 128, 128+rnd*128)
        for j = 0 to test.getSubPolyPoint_n(i) - 2
            line (test.getSubPolyPoint(i, j).x, test.getSubPolyPoint(i, j).y)-_
                 (test.getSubPolyPoint(i, j + 1).x, test.getSubPolyPoint(i, j + 1).y), col
        next j
    next i
    test.getBoundingBox(tl, br)

    c.setR(40)
    c.setP(Vector2D(mx, my))
    'circle (mx, my), 40

    r.setTL(Vector2D(mx, my) - Vector2D(50, 33))
    r.setBR(Vector2D(mx, my) + Vector2D(50, 33))
    line (r.getTl().x, r.getTL().y)-(r.getBR().x, r.getBR().y), &h00ff00, B
    if intersect2D(r, test) then print "IN"
    
    'print intersect2D(p, test)
    line (tl.x, tl.y)-(br.x, br.y), &hffff00, B
    sleep 16
loop until multikey(1)



