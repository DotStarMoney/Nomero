#ifndef TINYBODY_BI
#define TINYBODY_BI

#include "vector2d.bi"

type TinyBody
    public:
        declare constructor
        declare constructor(p_ as Vector2D, r_  as double, m_ as double)
        declare constructor(p_ as Vector2D, rx_ as double, ry_ as double, m_ as double)
        as Vector2D p
        as Vector2D v
        as Vector2D f
        as double   r
        as double   r_rat
        as double   m
        as double   elasticity
        as double   friction
        as integer  ind
        as integer  noCollide
        as integer  didCollide
        as Vector2D surfaceV
        as integer  dynaID
end type


#endif
