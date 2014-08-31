#ifndef SNOWGENERATOR_BI
#define SNOWGENERATOR_BI

#include "vector2d.bi"

enum sgFlakeType_
    LARGE
    MEDIUM
    SMALL
end enum

type sgFlake_t_
    as sgFlakeType_ flake_t
    as double  depth
    as Vector2D p
    as Vector2D v
    as Vector2D f
    as sgFlake_t_ ptr prev_
    as sgFlake_t_ ptr next_
end type

type SnowGenerator
    public:
        declare constructor()
        declare destructor()
        
        declare sub setFreq(f as integer, q as integer)
        declare sub setDepth(d1 as double, d2 as double)
        declare sub setSpeed(s as double)
        declare sub setType(tp as sgFlakeType_)
        declare sub setSize(levelWidth as integer,_
                            levelHeight as integer)
        declare sub setDrift(drift as double)
                            
        declare sub stepFlakes(cam as Vector2D, t as double)
        declare sub drawFlakes(scnbuff as uinteger ptr, cam as Vector2D)
    private:
        as sgFlake_t_ ptr head_
        as integer numFlakes
        
        as double  flakeDrift
        as integer freq
        as integer fcnt
        as integer quant
        as double  depth_lo
        as double  speed
        as double  depth_hi
        as sgFlakeType_ flakeType
        as integer w
        as integer h
end type



#endif