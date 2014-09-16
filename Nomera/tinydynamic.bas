#include "crt.bi"
#include "tinydynamic.bi"
#include "utility.bi"

constructor TinyDynamic()
	construct()
end constructor

constructor TinyDynamic(proto as TinyDynamic_Prototype_e)
	construct()
	init(proto)
end constructor

constructor TinyDynamic(proto as TinyDynamic_Prototype_e, pts as Vector2D ptr, ptsN as integer)
	construct()
	init(proto)
	importShape(pts, ptsN)
end constructor

destructor TinyDynamic()
	clearShapeData()
	if type_ = DYNA_BASICPATH then
		if BASICPATH.pathPoints <> 0 then
			deallocate(BASICPATH.pathPoints)
			BASICPATH.pathPoints = 0
		end if
	end if
end destructor

sub TinyDynamic.clearShapeData()
	if cur_pts_p <> 0 then deallocate(cur_pts_p)
	if cur_pts_v <> 0 then deallocate(cur_pts_v)
	if base_pts <> 0 then deallocate(base_pts)
	pointsN = 0
end sub

sub TinyDynamic.construct()
	ind = -1
	type_ = DYNA_NONE
	setup = 0
	cur_t = 0
	base_t = 0
	isComplete = 0
	pointsN = 0
	active = 0
	cur_pts_p = 0
	cur_pts_v = 0
	hasBB = 0
	base_pts = 0
	centroid = Vector2D(0,0)
end sub

sub TinyDynamic.init(proto as TinyDynamic_Prototype_e)
	if type_ = DYNA_BASICPATH then
		if BASICPATH.pathPoints <> 0 then
			deallocate(BASICPATH.pathPoints)
		end if
	end if
	type_ = proto
	select case proto
	case DYNA_SFX_SPINNER
		clearShapeData()
		isComplete = 0
		SFX_SPINNER.angle = 0
		SFX_SPINNER.angle_v = PI / 180
		SFX_SPINNER.length = 480
		pointsN = 2
		cur_pts_p = allocate(sizeof(Vector2D) * pointsN)
		cur_pts_v = allocate(sizeof(Vector2D) * pointsN)
	case DYNA_BASICPATH
		BASICPATH.pathPoints = 0
		BASICPATH.pathPointsN = 0
		BASICPATH.type_ = BOUNCE
		BASICPATH.segment = 0
		BASICPATH.segment_pos = 0
		BASICPATH.speed = 1
		BASICPATH.path_length = 0
		BASICPATH.toggleState = 0
		BASICPATH.toggleTime = 0
	case DYNA_PIVOTER
		PIVOTER.angle = 0
		PIVOTER.angle_v = PI / 180
	end select
	if pointsN <> 0 then
		setup = 1
		offset_time(0)
	end if
end sub

sub TinyDynamic.importShape(pts as Vector2D ptr, ptsN as integer)
	dim as integer i
	
	if (type_ = DYNA_SFX_SPINNER) then 
		exit sub
	end if
	
	clearShapeData()
	pointsN = ptsN
	base_pts = allocate(sizeof(Vector2D) * ptsN)
	cur_pts_p = allocate(sizeof(Vector2D) * ptsN)
	cur_pts_v = allocate(sizeof(Vector2D) * ptsN)
	memcpy(base_pts, pts, sizeof(Vector2D) * ptsN)
	memcpy(cur_pts_p, pts, sizeof(Vector2D) * ptsN)
	memcpy(cur_pts_v, pts, sizeof(Vector2D) * ptsN)
	if (pts[0].x = pts[ptsN-1].x) andAlso (pts[0].y = pts[ptsN-1].y) then 
		isComplete = 1
	else
		isComplete = 0
	end if
	if type_ <> DYNA_NONE then 
		setup = 1
		offset_time(0)
	end if
end sub

sub TinyDynamic.setCentroid(c_p as Vector2D)
	centroid = c_p
end sub

function TinyDynamic.getCentroid() as Vector2D
	return centroid
end function

function TinyDynamic.getPointsN() as integer
	return pointsN
end function

function TinyDynamic.getPointP(i as integer) as Vector2D
	return cur_pts_p[i]
end function

function TinyDynamic.getPointV(i as integer) as Vector2D
	return cur_pts_v[i]
end function

sub TinyDynamic.step_time(t as double) 
	base_t += t
	if setup and active then 
		offset_time(0)
	else
		cur_t = base_t
	end if
end sub

function TinyDynamic.getToggleState() as integer
	if type_ = DYNA_BASICPATH then
		return BASICPATH.toggleState
	else
		return -1
	end if
end function
sub TinyDynamic.togglePath()
	if type_ = DYNA_BASICPATH then
		if BASICPATH.toggleState = 0 then
			BASICPATH.toggleState = 2 
		elseif BASICPATH.toggleState = 1 then
			BASICPATH.toggleState =  3
		end if
		BASICPATH.toggleTime = base_t
	end if
end sub

sub TinyDynamic.offset_time(t as double)	
	dim as double ang_offset
	dim as double ang_dist
	dim as double ang_final
	dim as integer i
	dim as Vector2D seg_d
	dim as double seg_dm
	dim as double seg_dist
	dim as double temp_dist
	dim as Vector2D pathP
	dim as integer dire
	
	cur_t = base_t + t
	select case type_
	case DYNA_SFX_SPINNER
		SFX_SPINNER.angle = wrap(cur_t * SFX_SPINNER.angle_v)
		cur_pts_p[0].setX(cos(SFX_SPINNER.angle + PI) * SFX_SPINNER.length * 0.5)
		cur_pts_p[0].setY(0)
		cur_pts_p[1].setX(cos(SFX_SPINNER.angle) * SFX_SPINNER.length * 0.5)
		cur_pts_p[1].setY(0)
		cur_pts_p[0] = cur_pts_p[0] + centroid
		cur_pts_p[1] = cur_pts_p[1] + centroid
				
		cur_pts_v[0] = Vector2D(sin(SFX_SPINNER.angle + PI) * SFX_SPINNER.length * 0.5 * SFX_SPINNER.angle_v, 0)
		cur_pts_v[1] = Vector2D(sin(SFX_SPINNER.angle) * SFX_SPINNER.length * 0.5 * SFX_SPINNER.angle_v, 0)	
	case DYNA_BASICPATH
	
		temp_dist = cur_t * BASICPATH.speed
		
		select case BASICPATH.type_
		case BOUNCE
			temp_dist = wrap(temp_dist, BASICPATH.path_length*2)
		case SINUSOID
			temp_dist = (sin(temp_dist) + 1) * BASICPATH.path_length
		case TOGGLE
			if BASICPATH.toggleState = 0 then
				temp_dist = 0
			elseif BASICPATH.toggleState = 1 then
				temp_dist= BASICPATH.path_length - 0.001
			else
				temp_dist = (cur_t - BASICPATH.toggleTime) * BASICPATH.speed * BASICPATH.path_length
				if temp_dist < 0 then BASICPATH.toggleTime = 0
				
				if t = 0 then
					if temp_dist > BASICPATH.path_length then 
						if BASICPATH.toggleState = 2 then
							BASICPATH.toggleState = 1
							temp_dist = BASICPATH.path_length - 0.001
						else
							BASICPATH.toggleState = 0
							temp_dist = 0
						end if
					end if
				end if
				
			end if			
		end select
		
		dire = 1
		if temp_dist > BASICPATH.path_length then
			dire = -1
			temp_dist = BASICPATH.path_length*2 - temp_dist
		end if
		seg_dist = 0
		for i = 0 to BASICPATH.pathPointsN - 2
			seg_d = BASICPATH.pathPoints[i + 1] - BASICPATH.pathPoints[i]
			seg_dm = seg_d.magnitude()
			seg_d = seg_d / seg_dm
			seg_dist += seg_dm
			if temp_dist < seg_dist then
				BASICPATH.segment = i
				BASICPATH.segment_pos = (seg_dm - (seg_dist - temp_dist))
				pathP = centroid + seg_d * BASICPATH.segment_pos
				exit for
			end if
		next i			
		for i = 0 to pointsN - 1 
			cur_pts_p[i] = pathP + base_pts[i]
		next i
			
		select case BASICPATH.type_
		case BOUNCE				
			if dire = -1 then 
				for i = 0 to pointsN - 1 
					cur_pts_v[i] = seg_d * -BASICPATH.speed
				next i
			else
				for i = 0 to pointsN - 1 
					cur_pts_v[i] = seg_d * BASICPATH.speed
				next i
			end if
		case SINUSOID
			for i = 0 to pointsN - 1 
				cur_pts_v[i] = seg_d * sin(temp_dist) * BASICPATH.speed
			next i
		case TOGGLE
			if BASICPATH.toggleState < 2 then
				for i = 0 to pointsN - 1 
					cur_pts_v[i] = Vector2D(0,0)
				next i
			else
				if BASICPATH.toggleState = 2 then
					for i = 0 to pointsN - 1 
						cur_pts_v[i] = seg_d * BASICPATH.speed
					next i
				else
					for i = 0 to pointsN - 1 
						cur_pts_v[i] = seg_d * -BASICPATH.speed
					next i
				end if
			end if
		end select
	case DYNA_PIVOTER
		PIVOTER.angle = wrap(cur_t * PIVOTER.angle_v)
		for i = 0 to pointsN - 1 
			cur_pts_p[i] = Vector2D(base_pts[i].x * cos(PIVOTER.angle) - base_pts[i].y * sin(PIVOTER.angle),_
									base_pts[i].y * cos(PIVOTER.angle) + base_pts[i].x * sin(PIVOTER.angle))
									
			cur_pts_v[i] = Vector2D(-cur_pts_p[i].y * PIVOTER.angle_v, cur_pts_p[i].x * PIVOTER.angle_v)
		next i		
	end select
end sub

sub TinyDynamic.importParams(p as any ptr)
	dim as TinyDynamic_SFX_SPINNER ptr SFX_SPINNER_
	dim as TinyDynamic_BASICPATH   ptr BASICPATH_
	dim as TinyDynamic_PIVOTER     ptr PIVOTER_
	dim as Vector2D path_d
	dim as integer i
	if type_ = DYNA_BASICPATH then
		if BASICPATH.pathPoints <> 0 then deallocate(BASICPATH.pathPoints)
	end if
	select case type_
	case DYNA_SFX_SPINNER
		SFX_SPINNER_ = p
		SFX_SPINNER  = *SFX_SPINNER_
	case DYNA_BASICPATH
		BASICPATH_ = p
		BASICPATH  = *BASICPATH_
		BASICPATH.pathPoints = allocate(sizeof(Vector2D) * BASICPATH.pathPointsN)
		memcpy(BASICPATH.pathPoints, (*BASICPATH_).pathPoints, sizeof(Vector2D) * BASICPATH.pathPointsN)
		BASICPATH.path_length = 0
		for i = 0 to BASICPATH.pathPointsN - 2
			path_d = BASICPATH.pathPoints[i + 1] - BASICPATH.pathPoints[i]
			BASICPATH.path_length += path_d.magnitude()
		next i
	case DYNA_PIVOTER
		PIVOTER_ = p
		PIVOTER = *PIVOTER_
	end select
end sub

sub TinyDynamic.calcBB()
	dim as integer i
	dim as double dmag, cmag
	dim as double up_, down_, left_, right_
	dim as Vector2D tl_p, dr_p
	
	tl = Vector2D(0,0)
	dr = Vector2D(0,0)
	
	if setup then
		hasBB = 1
		select case type_
		case DYNA_SFX_SPINNER
			tl = centroid - Vector2D(SFX_SPINNER.length * 0.5 + 1, 1)
			dr = centroid + Vector2D(SFX_SPINNER.length * 0.5 + 1, 1)
		case DYNA_BASICPATH
			if BASICPATH.pathPointsN <> 0 then
				up_    = BASICPATH.pathPoints[0].y
				right_ = BASICPATH.pathPoints[0].x
				down_  = BASICPATH.pathPoints[0].y
				left_  = BASICPATH.pathPoints[0].x
				for i = 1 to BASICPATH.pathPointsN - 1
					if BASICPATH.pathPoints[i].x < left_ then
						left_ = BASICPATH.pathPoints[i].x
					elseif BASICPATH.pathPoints[i].x > right_ then
						right_ = BASICPATH.pathPoints[i].x
					end if
					if BASICPATH.pathPoints[i].y < up_ then
						up_ = BASICPATH.pathPoints[i].y
					elseif BASICPATH.pathPoints[i].y > down_ then
						down_ = BASICPATH.pathPoints[i].y
					end if					
				next i	
				for i = 0 to pointsN - 1
					if cur_pts_p[i].x < tl_p.x then
						tl_p.setX(cur_pts_p[i].x)
					elseif cur_pts_p[i].x > dr_p.x then
						dr_p.setX(cur_pts_p[i].x)
					end if
					if cur_pts_p[i].y < tl_p.y then
						tl_p.setY(cur_pts_p[i].y)
					elseif cur_pts_p[i].y > dr_p.y then
						dr_p.setY(cur_pts_p[i].y)
					end if			
				next i	
				
				tl = Vector2D(tl_p.x + left_, tl_p.y + up_) + centroid
				dr = Vector2D(dr_p.x + right_, dr_p.y + down_) + centroid
			end if
		case DYNA_PIVOTER
			cmag = -1
			for i = 0 to pointsN - 1
				dmag = cur_pts_p[i].magnitude
				if dmag > cmag then cmag = dmag
			next i
			tl = centroid - Vector2D(cmag, cmag)
			dr = centroid + Vector2D(cmag, cmag)
		end select
	end if
end sub

function TinyDynamic.circleCollide(p as Vector2D, v as Vector2D, r as double,_
								   byref depth as double, byref impuse as Vector2D,_
							       byref pt_vel as Vector2D) as integer
	dim as integer i
	
	return 0						   
end function

function TinyDynamic.getBB(byref a as Vector2d, byref b as Vector2D) as integer
	a = tl
	b = dr
	return hasBB
end function

function TinyDynamic.exportParams() as any ptr
	select case type_
	case DYNA_SFX_SPINNER
		return @SFX_SPINNER
	case DYNA_BASICPATH
		return @BASICPATH
	case DYNA_PIVOTER
		return @PIVOTER
	end select
	return 0
end function

sub TinyDynamic.activate()
	active = 1
end sub

sub TinyDynamic.deactivate()
	active = 0
end sub

function TinyDynamic.isActive() as integer
	return active
end function
