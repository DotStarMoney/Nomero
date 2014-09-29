#ifndef PATHTRACKER_H
#define PATHTRACKER_H

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

type PathTracker_Segment_t
	as Vector2D a, b
end type

type PathTracker_Inputs_t
	as integer dire
	as integer jump
	as integer ups
	as integer shift
end type

type PathTracker_Edge_t
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
end type

type PathTracker_Node_t
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
		declare sub buildNodes()
		
		declare sub record()
		declare sub pause()
		
		declare sub step_record()
	private:
		static as integer seg_count
		as ObjectLink link
		as List      edges
		as Hashtable nodes
		as Hash2d    spacialNodeIDs
		
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
		
		declare sub startEdge(type_ as PathTracker_Path_Type_e)
		declare sub endEdge()

		declare sub getNodeDist(p as Vector2D, node as integer, ret as double)		
		declare sub getNodeCoord(p as Vector2D, node as integer, ret as Vector2D)
		declare sub dumpStaticShape(segs() as PathTracker_Segment_t)
		declare sub addNode(segs() as PathTracker_Segment_t, type_ as integer)
end type		

#endif
