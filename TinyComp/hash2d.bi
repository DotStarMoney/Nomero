#ifndef HASH2D_BI
#define HASH2D_BI

#include "vector2d.bi"
#include "hashtable.bi"
#include "list.bi"

#define CELL_WIDTH 128
#define CELL_HEIGHT 128

type Hash2dData_t
    as any ptr data_
    as List parentNodesList
end type

type Hash2dNode_t
    as Hash2dData_t ptr data_
    as Hash2dNode_t ptr next_
    as Vector2D a, b
end type

type Hash2D
    public:
        declare constructor()
        declare destructor()
        
        declare sub init(spaceWidth as double, spaceHeight as double, dataSizeBytes as integer)
        declare sub insert(a as Vector2D, b as Vector2D, data_ as any ptr)
        declare function search(a as Vector2D, b as Vector2D,_
                                byref ret_ as any ptr ptr) as integer
        declare sub remove(data_ptr as any ptr)
        
        declare sub rollReset()
        declare function roll() as any ptr
        declare sub flush(clr as integer = 0)
        
    private:
        declare function getBounds(byref a as Vector2D, byref b as Vector2D,_
                                   byref tl_x as integer, byref tl_y as integer,_
                                   byref br_x as integer, byref br_y as integer) as integer
        
        as integer dataSizeBytes
        
        as integer          curRollX
        as integer          curRollY
        as Hash2dNode_t ptr curRollNode
        as HashTable        curRollFoundNodes
        as integer          curRollEnd
    
        as double  spaceWidth
        as double  spaceHeight
        as double  cellWidth
        as double  cellHeight
        as integer cellRows_N
        as integer cellCols_N
        
        as Hash2dNode_t ptr ptr spacialHash
        
        as HashTable pointerToHashData
end type

#endif