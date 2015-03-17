#ifndef TREE2D_BI
#define TREE2D_BI

#include "vector2d.bi"
#define MAX_STACK_DEPTH 32

#macro BEGIN_TREE2D(x, y)
	y.resetRoll()
	do
		x = y.roll()
		if x then
#endmacro

#macro BEGIN_SEARCH_TREE2D(x, y, z)
	y.setSearch(z)
	do
		x = y.getSearch()
		if x then
#endmacro
#macro ABORT_TREE2D()
	exit do
#endmacro

#macro END_TREE2D()
		else
			exit do
		end if
	loop
#endmacro

#macro END_SEARCH_TREE2D()
    END_TREE2D()
#endmacro
#macro ABORT_SEARCH_TREE2D()
    ABORT_TREE2D()
#endmacro

type Tree2D_Square
    declare constructor()
    declare constructor(tl_p as Vector2D, br_p as Vector2D, x0_p as integer=0, y0_p as integer=0, x1_p as integer=0, y1_p as integer=0)
    as Vector2D tl, br
    as integer x0, y0, x1, y1
end type

type Tree2D_node
    as double area
    as Tree2D_node ptr left_, right_, parent_
    as Tree2D_Square square
end type


type Tree2D
    public:
        declare constructor(maxNodes as integer)
        declare destructor()
        
        declare function insert(newSquare as Tree2D_Square) as Tree2D_Node ptr
        declare sub flush()
        declare sub splitNode(splitSquare as Tree2D_Square, byref node_ as Tree2D_Node ptr)
        declare sub setSearch(searchSquare_p as Tree2D_Square)
        declare function getSearch() as Tree2D_Square ptr
        declare function getRoot() as Tree2D_Node ptr
        
        declare sub resetRoll()
        declare function roll() as Tree2D_Square ptr
        
        declare function consistencyCheck(node_ as Tree2D_Node ptr, testNode_ as Tree2D_Node ptr) as integer
    private:
        
        as Tree2D_node ptr root_
        
        as Tree2D_node ptr nodePool
        as integer nodePool_capacity
        as integer nodePool_usage
        
        as Tree2D_node ptr searchStack(0 to MAX_STACK_DEPTH-1)
        as Tree2D_node ptr curSearchNode
        as Tree2D_square searchSquare
        as integer searchStackPointer 
        as integer searchTerm
        
        as Tree2D_node ptr rollStack(0 to MAX_STACK_DEPTH-1)
        as Tree2D_node ptr curRollNode
        as integer rollStackPointer 
        as integer rollTerm
        
        as Tree2D_node ptr splitStack(0 to MAX_STACK_DEPTH-1)
        as integer splitStackPointer

end type

declare sub Tree2DDebugPrint(node as Tree2D_node ptr, isLeft as integer=0, level as integer=0)


#endif