#ifndef PATHTRACKER_H
#define PATHTRACKER_H

#include "enemy.bi"

#include "vector2d.bi"
#include "hashtable.bi"
#include "objectlink.bi"
#include "hash2d.bi"
#include "list.bi"

enum PathTracker_Node_Type_e
	PT_STATIC
	PT_STATIC_VOLITILE
	PT_DYNAMIC
end enum

enum PathTracker_Path_Type_e
	PT_DROP
	PT_JUMP
end enum
 
enum PathTracker_Path_Speed_e
	PT_FULLSPEED
	PT_SLOWSPEED
	PT_INTERMEDIATE
end enum

type PathTracker_Segment_t Field = 1
	as Vector2D a, b
end type

type PathTracker_Inputs_t Field = 1
	as integer dire
	as integer jump
	as integer ups
	as integer shift
end type

enum PathTracker_Child_Movement_e
	PT_ON_NODE
	PT_ON_EDGE
	PT_FREE
end enum

'requires priority queue
'for now, just manually tell it where to go,
'add priority queue with hunting logic next

type PathTracker_Node_Location_t
	as integer node
	as double  x
end type

type PathTracker_Child_t
	as Enemy ptr                    child
	as PathTracker_Child_Movement_e moveState
	as PathTracker_Node_Location_t  target
	
	'''''''
	as integer isNavigating
	'''''''

end type

type PathTracker_Edge_t Field = 1
	as PathTracker_Path_Type_e  path_type
	as PathTracker_Path_Speed_e speed_type
	as List                     frames
	as Vector2D                 startPosition
	as Vector2D                 startVelocity
	as integer                  startDirection
	as Vector2D                 start_loc
	as Vector2D                 end_loc
	as double                   start_dist
	as double                   end_dist
	as integer                  ID_start
	as integer                  ID_end
	as integer 	                ID
end type

type PathTracker_Node_t Field = 1
	as PathTracker_Segment_t ptr segments
	as integer                   segments_N
	as PathTracker_Node_Type_e   type_
	as integer                   ID
	as List                      edges
	as Vector2D                  bb_a
	as Vector2D                  bb_b
end type



type PathTracker
	public:
		declare constructor()
		declare destructor()
		declare sub init(link_p as ObjectLink)
		declare sub flush()
		
		declare sub exportGraph(byref data_ as byte ptr, byref data_bytes as integer)
		declare sub importGraph(byref data_ as byte ptr, byref data_bytes as integer)
		
		declare sub record()
		declare sub pause()
		
		declare sub step_record()
		declare sub record_draw(scnbuff as integer ptr)
		declare sub register(e_ as Enemy ptr)
	private:
		static as integer seg_count
		static as integer edge_count
		
		as ObjectLink link
		as List      edges
		as Hashtable nodes
		as Hash2d    spacialNodeIDs
		as Hash2d    spacialEdgePTRs
		
		as Hashtable children
		
		as integer onEdge
		as integer onNode
		as integer currentNode
		
		as PathTracker_Inputs_t curFrame
		as PathTracker_Inputs_t prevInputs
		as Vector2D prev_pos
		as Vector2D prev_vel
		as integer  prev_dir
		as Vector2D curNodeP
		as integer lastJump
		as integer enable
		as PathTracker_Edge_t ptr currentEdge
		as integer interestID
		as integer oldMB

		
		declare sub buildNodes()
		declare sub startEdge(type_ as PathTracker_Path_Type_e)
		declare sub endEdge()
		declare sub getNodeDist(p as Vector2D, node as integer, ret as double)		
		declare sub getNodeCoord(p as Vector2D, node as integer, ret as Vector2D)
		declare sub dumpStaticShape(segs() as PathTracker_Segment_t)
		declare sub addNode(segs() as PathTracker_Segment_t, type_ as integer)
end type		

#endif
