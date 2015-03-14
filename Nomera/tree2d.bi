#ifndef TREE2D_BI
#define TREE2D_BI

#include "vector2d.bi"
#define MAX_STACK_DEPTH 32

type Tree2D_Square
    declare constructor()
    declare constructor(tl_p as Vector2D, br_p as Vector2D, x0_p as integer, y0_p as integer, x1_p as integer, y1_p as integer)
    as Vector2D tl, br
    as integer x0, y0, x1, y1
end type

type Tree2D_node
    as double area
    as Tree2D_node ptr left_, right_, parent_
    as Tree2D_Square square
end type


'iterate through tree A (visible) squares
    'iterate through squares in B (mask) touched by A square (can keep pointer from last time since we'll be close by, instead of starting at root)
        'split A square node (split at) by B
    '}
'}


'need flush
'insert one, returns node where inserted
'split at node (provide splitting square and node to split)
'set current search
'reset search
'get next search

type Tree2D
    public:
        declare constructor(maxNodes as integer)
        declare destructor()
        
        declare function insert(newSquare as Tree2D_Square) as Tree2D_Node ptr
        declare sub flush()
        declare sub splitNode(splitSquare as Tree2D_Square, node_ as Tree2D_Node ptr)
        declare sub setSearch(searchSquare as Tree2D_Square)
        declare function getSearch() as Tree2D_Square ptr
        declare function getRoot() as Tree2D_Node ptr
        
        declare sub resetRoll()
        declare function roll() as Tree2D_Square ptr
        
    private:
        as Tree2D_node ptr root_
        
        as Tree2D_node ptr nodePool
        as integer nodePool_capacity
        as integer nodePool_usage
        
        as Tree2D_node ptr searchStack(0 to MAX_STACK_DEPTH-1)
        as integer searchStackPointer 
        
        as Tree2D_node ptr rollStack(0 to MAX_STACK_DEPTH-1)
        as integer rollStackPointer 
        
        as Tree2D_node ptr splitStack(0 to MAX_STACK_DEPTH-1)
        as integer splitStackPointer

end type

declare sub Tree2DDebugPrint(node as Tree2D_node ptr, isLeft as integer, level as integer)


#endif