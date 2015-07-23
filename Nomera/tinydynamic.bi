#ifndef TINYDYNAMIC_BI
#define TINYDYNAMIC_BI

#include "vector2d.bi"
#include "arbiter.bi"

enum TinyDynamic_Prototype_e
	DYNA_NONE
	DYNA_SFX_SPINNER
	DYNA_BASICPATH
	DYNA_PIVOTER
end enum

enum TinyDynamic_BASICPATH_PathType_e
	BOUNCE
	SINUSOID
	TOGGLE
end enum

type TinyDynamic_SFX_SPINNER
	as double angle
	as double angle_v
	as double length
end type


type TinyDynamic_BASICPATH
	as Vector2D ptr pathPoints
	as integer pathPointsN
    as TinyDynamic_BASICPATH_PathType_e type_
	as double speed
    
	as integer segment
	as double  segment_pos
	as double  path_length
	as integer toggleState
	as double toggleTime
end type

type TinyDynamic_PIVOTER
	as double angle
	as double angle_v
end type

type TinyDynamic
	public:
		declare constructor()
		declare constructor(proto as TinyDynamic_Prototype_e)
		declare constructor(proto as TinyDynamic_Prototype_e, pts as Vector2D ptr, ptsN as integer)
		declare destructor()
		
		declare sub init(proto as TinyDynamic_Prototype_e)
		declare function getPointsN() as integer
		declare function getPointP(i as integer) as Vector2D
		declare function getPointV(i as integer) as Vector2D

		declare function getToggleState() as integer
		declare sub togglePath()

		declare sub step_time(t as double) 
		declare sub offset_time(t as double)
		declare sub importParams(p as any ptr)
		declare function exportParams() as any ptr
		declare sub activate()
		declare sub deactivate()
		declare function isActive() as integer
		declare function isClosed() as integer
		declare sub importShape(pts as Vector2D ptr, ptsN as integer)
		declare sub setCentroid(c_p as Vector2D)
		declare function getCentroid() as Vector2D
		declare function getBB(byref a as Vector2d, byref b as Vector2D) as integer
		declare sub calcBB()
		declare function circleCollide(p as Vector2D, r as double,_
									   arbList() as ArbiterData_t, byref curIndex as integer,_
									   byref maxD as double, slop as double = 0.1) as integer
		declare function getNumSegs() as integer
		declare function getReferenceTag(i as integer) as integer
		declare function getTag(i as integer) as integer
		declare sub setTag(i as integer, t as integer)
		
		as integer ind
	private:
		static as integer instCount
		declare sub construct()
		declare sub clearShapeData()
		as Vector2D centroid
		as double cur_t
		as double base_t
		as integer pointsN
		as integer active
		as integer setup
		as integer hasBB
		as integer isComplete
		as Vector2D tl, dr
		
		as Vector2D ptr base_pts
		as Vector2D ptr cur_pts_p
		as Vector2D ptr cur_pts_v
		as integer ptr  segmentTags
		as integer ptr  referenceTags
		
		as TinyDynamic_Prototype_e type_

		union
			as TinyDynamic_SFX_SPINNER SFX_SPINNER
			as TinyDynamic_BASICPATH   BASICPATH
			as TinyDynamic_PIVOTER     PIVOTER
		end union
	 
end type



#endif
