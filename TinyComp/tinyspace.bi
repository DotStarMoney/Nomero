#ifndef TINYSPACE_BI
#define TINYSPACE_BI


#include "tinyblock.bi"
#include "tinybody.bi"
#include "vector2d.bi"
#include "debug.bi"

#define MAX_BODIES 256
#define MAX_SEGS 128
#define MAX_ARBS 6
#define DEFAULT_GRAV 620.0
#define MIN_DEPTH 0.1
#define TERM_VEL 800.0
#define MAX_ITERATIONS 8
#define MAX_RESOLUTIONS 5
#define MIN_TRIG_FRIC_V 0.1
#define MIN_TRIG_ELAS_DV 20


type BlockEndpointData_t
    as Vector2D a
    as Vector2D b
    as integer  tag
end type

type ArbiterData_t
    as Vector2D a
    as Vector2D b
    as Vector2D impulse
    as double   depth
    as integer  ignore
    as integer  new_
end type

type TinySpace
    public:
        declare constructor
        declare destructor
        declare sub setBlockData(byval d as TinyBlock ptr, _
                                 byval w as integer, _
                                 byval h as integer, _
                                 byval l as double)
        declare function addBody(body_ as TinyBody ptr) as integer
        declare sub removeBody(index as integer)
        declare sub step_time(byval t as double)
        declare function isGrounded(bod as integer, dot as double) as integer
        declare function getArbiterN(bod as integer) as integer
        declare function getArbiter(bod as integer, i as integer) as ArbiterData_t
        declare function getGroundingNormal(bod as integer,_
                                            dire as Vector2D ,_
                                            prox as Vector2D ,_
                                            dot as double) as Vector2D
        declare function raycast(p as Vector2D, v as Vector2D,_
								 byref in_pt as Vector2D) as double
        declare function getGravity() as Vector2D
    private:
        declare static sub dividePosition(p as Vector2D, size as Vector2D)
        declare sub refactorArbiters(arb_i as integer, seg() as BlockEndpointData_t, seg_n as integer)
        
        declare function getBlock(xp as integer, yp as integer) as TinyBlock
        declare function block_getPoint(pt as integer,_
                                        p as Vector2D) as Vector2D
        declare function block_getRingPoint(block_type as integer,_
                                            pnt as integer) as integer
        declare sub traceRing(      x           as integer,_
                                    y           as integer,_
                                    segList()   as BlockEndpointData_t,_
                              byref curIndx     as integer,_
                                    usedArray() as integer)
        declare function lineCircleCollide(a as Vector2D, b as Vector2D,_
                                           p as Vector2D, r as double,_
                                           byref depth as double,_
                                           norm as Vector2D,_
                                           impulse as Vector2D) as integer
        
        declare function lineAAEllipseCollide(a as Vector2D, b as Vector2D,_
                                              p as Vector2D,_
                                              rw as double, rh as double,_
                                              byref depth as double,_
                                              impulse as Vector2D) as integer


        declare sub vectorListImpulse(vecs() as Vector2D, v as Vector2D,_
                                      res as Vector2D, byref fullCancel as integer)
        declare function bodyN(inst as integer) as integer
                                    
        as TinyBody ptr  bodies(0 to MAX_BODIES-1)
        as integer       bodies_n
        as integer       bcount
        
        as ArbiterData_t arbiters(0 to MAX_BODIES-1, 0 to MAX_ARBS-1)
        as integer       arbiters_n(0 to MAX_BODIES-1)
                              
        as integer       roi_x0
        as integer       roi_y0
        as integer       roi_x1
        as integer       roi_y1
                              
        as double        t
        as TinyBlock ptr block_data
        as integer       block_n_rows
        as integer       block_n_cols
        as integer       block_l
        
        as double        gravity
        as integer       framesGone
end type



#endif
