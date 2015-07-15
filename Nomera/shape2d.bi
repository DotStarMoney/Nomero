#ifndef SHAPE2D_BI
#define SHAPE2D_BI

#include "vector2d.bi"

type Shape2D extends Object
    public:
        declare constructor()
        declare abstract sub getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D)    
        declare sub setOffset(offset_ as Vector2D)
        declare function getOffset() as Vector2D
    protected:
        as Vector2D offset
end type

type Point2d extends Shape2D
    public:
        declare constructor()
        declare constructor(p_ as Vector2D)
        
        declare sub setP(p_ as Vector2D)
        declare function getP() as Vector2D
        
        declare sub getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D) override
    private:
        as Vector2D p
end type

type Rectangle2D extends Shape2D
    public:
        declare constructor()
        declare constructor(tl_ as Vector2D, br_ as Vector2D)
        
        declare sub set(tl_ as Vector2D, br_ as Vector2D)
        declare sub setTL(tl_ as Vector2D)
        declare sub setBR(br_ as Vector2D)
        declare function getTL() as Vector2D
        declare function getBR() as Vector2D
        
        declare sub getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D) override
    private:
        as Vector2D tl
        as Vector2D br
end type

type Circle2D extends Shape2D
    public:
        declare constructor()
        declare constructor(p_ as Vector2D, r as double)
        
        declare sub set(p_ as Vector2D, r as double)
        declare sub setP(p_ as Vector2D)
        declare sub setR(r_ as double)
        declare function getP() as Vector2D
        declare function getR() as double
        
        declare sub getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D) override
    private:
        as Vector2D p
        as double r
end type

type Polygon2D extends Shape2D
    public:
        declare constructor()
        declare destructor()
        declare constructor(points_ as Vector2D ptr, points_n_ as integer)
        
        declare sub set(points_ as Vector2D ptr, points_n_ as integer)
        declare sub setPoint(i as integer, p as Vector2D)
        declare sub setOffset(o as Vector2D)
        declare function getOffset() as Vector2D
        
        declare function getPoint_N() as integer
        declare function getPoint(i as integer) as Vector2D
        
        declare sub getBoundingBox(byref tl_ as Vector2D, byref br_ as Vector2D) override
        
    'private:
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        declare sub ensureDecomp()
        declare function getSubPoly_N() as integer
        declare function getSubPolyPoint_N(i as integer) as integer    
        declare function getSubPolyPoint(i as integer, j as integer) as Vector2D      
        declare sub forceCCW()        
    private:
        declare sub calculateDecomp()
        declare sub calculateBounds()
        declare sub clearDecomp()
        
        declare static function lineSegIntersection(p1 as Vector2D, p2 as Vector2D,_
                                             q1 as Vector2D, q2 as Vector2D) as Vector2D
        declare static function dCross(a as Vector2D, b as Vector2D, c as Vector2D) as double
        declare sub recDecomp(interestPoints as Vector2D ptr, numInterestPoints as integer, interestIndex as integer,_
                              polys_points as Vector2D ptr ptr, polys_points_n as integer ptr, _
                              byref polys_n as integer)
        
        
        as Vector2D tl
        as Vector2D br
        as integer polyHasBounds
        
        as integer hasWinding
    
        as integer points_n
        as Vector2D ptr points
        
        as integer sub_polys_n
        as integer ptr sub_points_n
        as Vector2D ptr ptr sub_points
        
end type

declare function intersect2D_pp(a as Point2D ptr, b as Point2D ptr) as integer
declare function intersect2D_ps(a as Point2D ptr, b as Rectangle2D ptr) as integer
declare function intersect2D_pc(a as Point2D ptr, b as Circle2D ptr) as integer
declare function intersect2D_py(a as Point2D ptr, b as Polygon2D ptr) as integer
declare function intersect2D_ss(a as Rectangle2D ptr, b as Rectangle2D ptr) as integer
declare function intersect2D_sc(a as Rectangle2D ptr, b as Circle2D ptr) as integer
declare function intersect2D_sy(a as Rectangle2D ptr, b as Polygon2D ptr) as integer
declare function intersect2D_cc(a as Circle2D ptr, b as Circle2D ptr) as integer
declare function intersect2D_cy(a as Circle2D ptr, b as Polygon2D ptr) as integer
declare function intersect2D_yy(a as Polygon2D ptr, b as Polygon2D ptr) as integer
declare function intersect2D(a as Shape2D ptr, b as Shape2D ptr) as integer
    
#endif