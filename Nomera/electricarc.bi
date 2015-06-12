#ifndef ELECTRICARC_BI
#define ELECTRICARC_BI

#include "vector2d.bi"
#include "hashtable.bi"

#define BLOCK_SIZE 16
#define BLOCK_SIZE_SHIFT 4

#define MAX_SPLITS 1023

#define DEFAULT_PERIOD_MIN 1
#define DEFAULT_PERIOD_MAX 40

#define USE_640x480 

'divide in final composite

type ElectricArc_ArcData_t
    as Vector2D a
    as Vector2D b
    as Vector2D ptr splits
    as Vector2D ptr drifts
    as integer curSplit
    as integer period_min
    as integer period_max
    as integer p
end type

type ElectricArc_Stack_t
    as Vector2D a
    as Vector2D b
    as Vector2D m
    as integer  node
end type

type ElectricArc
    public:
        declare constructor()
        declare constructor(planeW as integer, planeH as integer)    
        declare destructor()
        declare sub init(planeW as integer, planeH as integer)
        declare function create() as integer
        declare sub setPoints(id as integer, a as Vector2D, b as Vector2D)
        declare sub getPoints(id as integer, byref a as Vector2D, byref b as Vector2D)
        declare sub resetArc(id as integer)
        declare sub setSnapPeriod(id as integer, period_min as integer, period_max as integer)
        declare sub destroy(id as integer)
        declare sub flush()
        declare sub drawArcs(scnbuff as integer ptr)
        declare function isSnapFrame(id as integer) as integer
        declare sub stepArcs(timestep as double)
    private:
        declare sub wipeMemory()
        declare sub clean()
        declare sub reset_construct()
        declare sub drawArcLine(x1 as integer, y1 as integer,_
                                x2 as integer, y2 as integer)
                                
        declare sub accSquareR5()
        declare sub accSquareR5_XH(src as integer ptr, dest as integer ptr,_
                                   bx as integer, by as integer, r as integer)
        declare sub accSquareR5_XV(src as integer ptr, dest as integer ptr,_
                                   bx as integer, by as integer, r as integer)

        declare sub compSquareR1(pxldata as integer ptr)
        declare sub compSquareR1_XH(bx as integer, by as integer)
        declare sub compSquareR1_XV(pxldata as integer ptr, bx as integer, by as integer)        
        
        static as integer toneMap(0 to 255)
        static as integer toneMap_setup
        as integer planeWidth
        as integer planeHeight
        as integer blockW
        as integer blockH
        as integer ptr arcSpineData_alloc
        as integer ptr arcSmoothData_alloc
        as integer ptr arcGlowData_alloc
        as integer ptr arcSpineData
        as integer ptr arcSmoothData
        as integer ptr arcGlowData
        
        as integer blocks_N
        as integer ptr activeBlockFiles
        as integer ptr activeBlockList
        as integer activeBlockList_N
        as integer generate
        
        as Hashtable ArcHash
        
end type


#endif