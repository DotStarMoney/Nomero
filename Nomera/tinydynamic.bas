#include "crt.bi"
#include "tinydynamic.bi"
#include "utility.bi"
#include "debug.bi"
#include "printlog.bi"

static as integer TinyDynamic.instCount = 1


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
	if segmentTags <> 0 then deallocate(segmentTags)
	if referenceTags <> 0 then deallocate(referenceTags)
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
	segmentTags = 0 
	referenceTags = 0
	base_pts = 0
	centroid = Vector2D(0,0)
end sub

sub TinyDynamic.init(proto as TinyDynamic_Prototype_e)
	dim as integer i
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
		SFX_SPINNER.angle_v = (_PI_ / 180)*64
		SFX_SPINNER.length = 480
		pointsN = 2
		cur_pts_p = allocate(sizeof(Vector2D) * pointsN)
		cur_pts_v = allocate(sizeof(Vector2D) * pointsN)
		segmentTags = allocate(sizeof(integer) * (pointsN - 1))
		referenceTags = allocate(sizeof(integer) * (pointsN - 1))
		for i = 0 to pointsN - 2
			referenceTags[i] = instCount
			instCount += 1
		next i
	case DYNA_BASICPATH
		BASICPATH.pathPoints = 0
		BASICPATH.pathPointsN = 0
		BASICPATH.type_ = BOUNCE
		BASICPATH.segment = 0
		BASICPATH.segment_pos = 0
		BASICPATH.speed = 10
		BASICPATH.path_length = 0
		BASICPATH.toggleState = 0
		BASICPATH.toggleTime = 0
		pointsN = 0
	case DYNA_PIVOTER
		PIVOTER.angle = 0
		PIVOTER.angle_v = (_PI_ / 180)*4
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
	base_pts =  allocate(sizeof(Vector2D) * ptsN)
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
	segmentTags = allocate(sizeof(integer) * (ptsN - 1))
	referenceTags = allocate(sizeof(integer) * (ptsN - 1))
	for i = 0 to ptsN - 2
        segmentTags[i] = 0
		referenceTags[i] = instCount
		instCount += 1
	next i
	if type_ <> DYNA_BASICPATH then
		if type_ <> DYNA_NONE then 
			setup = 1
			offset_time(0)
		end if
	else
		if BASICPATH.pathPointsN <> 0 then
			setup = 1
			offset_time(0)
		end if
	end if
end sub

function TinyDynamic.getNumSegs() as integer
	return pointsN - 1
end function

function TinyDynamic.getTag(i as integer) as integer
	return segmentTags[i]
end function
sub TinyDynamic.setTag(i as integer, t as integer)
	segmentTags[i] = t
end sub

function TinyDynamic.getReferenceTag(i as integer) as integer
	return referenceTags[i]
end function

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
		offset_time(0)
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
        elseif BASICPATH.toggleState = 2 then
            BASICPATH.toggleState = 1
		elseif BASICPATH.toggleState = 1 then
			BASICPATH.toggleState = 3
        elseif BASICPATH.toggleState = 3 then
            BASICPATH.toggleState = 0
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
	dim as double old_temp_dist
	dim as double temp_dist
	dim as Vector2D pathP
	dim as integer dire
	
		
	if setup = 0 then exit sub
	
	cur_t = base_t + t
	
	#ifdef DEBUG
		printlog "Computing TinyDynamic at time: " & str(cur_t)
	#endif	
	
	
	select case type_
	case DYNA_SFX_SPINNER
		SFX_SPINNER.angle = wrap(cur_t * SFX_SPINNER.angle_v)
		cur_pts_p[0].setX(-abs(cos(SFX_SPINNER.angle + _PI_) * SFX_SPINNER.length * 0.5))
		cur_pts_p[0].setY(0)
		cur_pts_p[1].setX(abs(cos(SFX_SPINNER.angle) * SFX_SPINNER.length * 0.5))
		cur_pts_p[1].setY(0)
		cur_pts_p[0] = cur_pts_p[0] + centroid
		cur_pts_p[1] = cur_pts_p[1] + centroid
				
		if wrap(SFX_SPINNER.angle+_PI_/2) >= _PI_ then
			cur_pts_v[0] = Vector2D(-sin(SFX_SPINNER.angle) * SFX_SPINNER.length * 0.5 * SFX_SPINNER.angle_v, 0)
			cur_pts_v[1] = Vector2D(sin(SFX_SPINNER.angle) * SFX_SPINNER.length * 0.5 * SFX_SPINNER.angle_v, 0)
		else
			cur_pts_v[0] = Vector2D(sin(SFX_SPINNER.angle) * SFX_SPINNER.length * 0.5 * SFX_SPINNER.angle_v, 0)
			cur_pts_v[1] = Vector2D(-sin(SFX_SPINNER.angle) * SFX_SPINNER.length * 0.5 * SFX_SPINNER.angle_v, 0)
		end if
		#ifdef DEBUG
			line (cur_pts_p[0].x(), cur_pts_p[0].y())-(cur_pts_p[1].x(), cur_pts_p[1].y())
		#endif
	case DYNA_BASICPATH
	
		temp_dist = cur_t * BASICPATH.speed
		
		
		if (BASICPATH.pathPoints[0].x <> BASICPATH.pathPoints[BASICPATH.pathPointsN - 1].x) orElse _
		   (BASICPATH.pathPoints[0].y <> BASICPATH.pathPoints[BASICPATH.pathPointsN - 1].y) then
			
			select case BASICPATH.type_
			case BOUNCE
				temp_dist = wrap(temp_dist, BASICPATH.path_length*2)
                dire = 1
                if temp_dist > BASICPATH.path_length then
                    dire = -1
                    temp_dist = BASICPATH.path_length*2 - temp_dist
                end if
			case SINUSOID
				old_temp_dist = temp_dist
				temp_dist = (sin(temp_dist) + 1) * BASICPATH.path_length
                dire = 1
                if temp_dist > BASICPATH.path_length then
                    dire = -1
                    temp_dist = BASICPATH.path_length*2 - temp_dist
                end if
			case TOGGLE
				if BASICPATH.toggleState = 0 then
					temp_dist = 0
				elseif BASICPATH.toggleState = 1 then
					temp_dist = BASICPATH.path_length - 0.0001
				else
					temp_dist = (cur_t - BASICPATH.toggleTime) * abs(BASICPATH.speed)
                    if BASICPATH.toggleState = 3 then
                        temp_dist = BASICPATH.path_length + temp_dist
                        if temp_dist > BASICPATH.path_length*2 then 
                            BASICPATH.toggleState = 0
                            temp_dist = 0
                        else
                            temp_dist = BASICPATH.path_length*2 - temp_dist
                        end if
                    elseif BASICPATH.toggleState = 2 then
                        if temp_dist > BASICPATH.path_length then 
                            BASICPATH.toggleState = 1        
                            temp_dist = BASICPATH.path_length - 0.0001
                        end if
                    end if
				end if	
                
			end select
					

			seg_dist = 0
			for i = 0 to BASICPATH.pathPointsN - 2
				seg_d = BASICPATH.pathPoints[i + 1] - BASICPATH.pathPoints[i]
				seg_dm = seg_d.magnitude()
				seg_d = seg_d / seg_dm
				seg_dist += seg_dm
				if temp_dist < seg_dist then
					BASICPATH.segment = i
					BASICPATH.segment_pos = (seg_dm - (seg_dist - temp_dist))
					pathP = centroid + BASICPATH.pathPoints[i] + seg_d * BASICPATH.segment_pos
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
					cur_pts_v[i] = seg_d * sin(old_temp_dist) * BASICPATH.speed
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
		else
			temp_dist = wrap(cur_t * BASICPATH.speed, BASICPATH.path_length)
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
				cur_pts_v[i] = seg_d * BASICPATH.speed
			next i
		end if
	
		#ifdef DEBUG
			for i = 0 to pointsN - 2
				line (cur_pts_p[i].x(), cur_pts_p[i].y())-(cur_pts_p[i+1].x(), cur_pts_p[i+1].y())
			next i
		#endif
	case DYNA_PIVOTER
		PIVOTER.angle = wrap(cur_t * PIVOTER.angle_v)
		for i = 0 to pointsN - 1 
			cur_pts_p[i] = Vector2D(base_pts[i].x * cos(PIVOTER.angle) - base_pts[i].y * sin(PIVOTER.angle),_
									base_pts[i].y * cos(PIVOTER.angle) + base_pts[i].x * sin(PIVOTER.angle))
			cur_pts_v[i] = Vector2D(-cur_pts_p[i].y * PIVOTER.angle_v, cur_pts_p[i].x * PIVOTER.angle_v)
			cur_pts_p[i] = cur_pts_p[i] + centroid
		next i		
		#ifdef DEBUG
			for i = 0 to pointsN - 2
				line (cur_pts_p[i].x(), cur_pts_p[i].y())-(cur_pts_p[i+1].x(), cur_pts_p[i+1].y())
			next i
		#endif
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
				tl_p = Vector2D(1000000,1000000)
				dr_p = Vector2D(-1000000,-1000000)
				for i = 0 to pointsN - 1
					if base_pts[i].x < tl_p.x then
						tl_p.setX(base_pts[i].x)
					elseif base_pts[i].x > dr_p.x then
						dr_p.setX(base_pts[i].x)
					end if
					if base_pts[i].y < tl_p.y then
						tl_p.setY(base_pts[i].y)
					elseif base_pts[i].y > dr_p.y then
						dr_p.setY(base_pts[i].y)
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

function TinyDynamic.circleCollide(p as Vector2D, r as double,_
								   arbList() as ArbiterData_t, byref curIndex as integer,_
								   byref maxD as double, slop as double = 0.1) as integer
	
	dim as integer  i, j
	dim as integer  oddNodes
	dim as Vector2D seg_v
	dim as Vector2D seg_vn
	dim as Vector2D seg_v_perp
	dim as double   seg_m
	dim as double   seg_i
	dim as Vector2D seg_pos
	dim as Vector2D proj_to_p
	dim as double   c_depth
	dim as Vector2D c_impulse
	dim as double   ppmag
	dim as double   maxDepth
	dim as integer  foundArbs
	dim as integer  atEndpoint

	if setup = 0 then return 0
	
	maxDepth = -1
	foundArbs = 0

	for i = 0 to pointsN - 2
		seg_v = cur_pts_p[i + 1] - cur_pts_p[i]
		seg_m = seg_v.magnitude()
		seg_vn = seg_v / seg_m
		seg_v_perp = seg_vn.iperp()
		seg_i = (seg_vn) * (p - cur_pts_p[i])
		atEndpoint = 0
		if seg_i < 0 then
			seg_i = 0
			atEndpoint = 1
		elseif seg_i > seg_m then
			seg_i = seg_m
			atEndpoint = 1
		end if		
		seg_pos = cur_pts_p[i] + seg_i * seg_vn
		proj_to_p = (p - seg_pos)
		ppmag = proj_to_p.magnitude()
		c_impulse = proj_to_p / ppmag
		if ppmag >= (r + slop) then continue for
		if atEndpoint = 0 then
			if proj_to_p * seg_v_perp > 0 then
				c_depth = r - ppmag
			else
				c_depth = ppmag + r
			end if
		else
			c_depth = r - ppmag
		end if
			
		if c_depth > maxDepth then maxDepth = c_depth
		curIndex += 1
		foundArbs += 1
		with arbList(curIndex - 1)
			.a = cur_pts_p[i]
			.b = cur_pts_p[i + 1]
			.dynamic_ = 1
			.impulse = c_impulse
			.depth = c_depth
			.velocity = (cur_pts_v[i + 1] - cur_pts_v[i]) * _
			            (seg_i / seg_m) + cur_pts_v[i]
			.dynamic_tag = referenceTags[i]
			.tag = segmentTags[i]
			.dynamic_norm = seg_v_perp
			.guide_dot = c_impulse
			.guide_axis = seg_pos + r * c_impulse			
			.ignore = 0
			.new_ = 0
		end with
	next i
                            	
	maxD = maxDepth
	if foundArbs > 0 then return foundArbs
	
	if (isComplete = 1) andAlso (foundArbs = 0) then
		oddNodes = 0
		j = pointsN - 2

		for i = 0 to pointsN - 2
			if ((((cur_pts_p[i].y < p.y) andAlso (cur_pts_p[j].y >= p.y)) orElse _
				 ((cur_pts_p[j].y < p.y) andAlso (cur_pts_p[i].y >= p.y))) andAlso _
				 ((cur_pts_p[i].x <= p.x) orElse (cur_pts_p[j].x <= p.x))) Then
				 
				oddNodes = oddNodes xor (cur_pts_p[i].x + ((p.y - cur_pts_p[i].y) / _
										(cur_pts_p[j].y - cur_pts_p[i].y)) * _
										(cur_pts_p[j].x - cur_pts_p[i].x)) < p.x
		 
			end if
			j = i
		next i
		
		if oddNodes = 1 then 
			maxDepth = 99999
			return -1
		end if
	end if

	return 0						   
end function

function TinyDynamic.getBB(byref a as Vector2d, byref b as Vector2D) as integer
	a = tl
	b = dr
	return hasBB
end function

function TinyDynamic.isClosed() as integer
	return isComplete
end function

function TinyDynamic.exportParams() as any ptr
	dim as any ptr ret
	ret = 0
	select case type_
	case DYNA_SFX_SPINNER
		ret = allocate(sizeof(TinyDynamic_SFX_SPINNER))
		memcpy(ret, @SFX_SPINNER, sizeof(TinyDynamic_SFX_SPINNER))
	case DYNA_BASICPATH
		ret = allocate(sizeof(TinyDynamic_BASICPATH))
		memcpy(ret, @BASICPATH, sizeof(TinyDynamic_BASICPATH))
	case DYNA_PIVOTER
		ret = allocate(sizeof(TinyDynamic_PIVOTER))
		memcpy(ret, @PIVOTER, sizeof(TinyDynamic_PIVOTER))
	end select
	return ret
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

sub TinyDynamic.serialize_out(pbin as PackedBinary)
    dim as integer i
    pbin.store(centroid)
    pbin.store(cur_t)
    pbin.store(base_t)
    pbin.store(pointsN)
    pbin.store(active)
    pbin.store(setup)
    pbin.store(hasBB)
    pbin.store(isComplete)
    pbin.store(tl)
    pbin.store(dr)
    for i = 0 to pointsN - 1
        pbin.store(base_pts[i])
        pbin.store(cur_pts_p[i])
        pbin.store(cur_pts_v[i])
        if i < pointsN - 1 then
            pbin.store(segmentTags[i])
            pbin.store(referenceTags[i])
        end if
    next i
    pbin.store(cint(type_))
    select case type_
    case DYNA_SFX_SPINNER
        pbin.store(SFX_SPINNER.angle)
        pbin.store(SFX_SPINNER.angle_v)
        pbin.store(SFX_SPINNER.length)
    case DYNA_BASICPATH
        pbin.store(BASICPATH.pathPointsN)
        for i = 0 to BASICPATH.pathPointsN - 1
            pbin.store(BASICPATH.pathPoints[i])
        next i
        pbin.store(cint(BASICPATH.type_))
        pbin.store(BASICPATH.speed)    
        pbin.store(BASICPATH.segment)
        pbin.store(BASICPATH.segment_pos)
        pbin.store(BASICPATH.path_length)
        pbin.store(BASICPATH.toggleState)
        pbin.store(BASICPATH.toggleTime)
    case DYNA_PIVOTER
        pbin.store(PIVOTER.angle)
        pbin.store(PIVOTER.angle_v)    
    end select    
end sub
sub TinyDynamic.serialize_in(pbin as PackedBinary)
    dim as integer i, tempInt    
    pbin.retrieve(centroid)
    pbin.retrieve(cur_t)
    pbin.retrieve(base_t)
    pbin.retrieve(pointsN)
    pbin.retrieve(active)
    pbin.retrieve(setup)
    pbin.retrieve(hasBB)
    pbin.retrieve(isComplete)
    pbin.retrieve(tl)
    pbin.retrieve(dr)
    base_pts  = allocate(sizeof(Vector2D) * pointsN)
    cur_pts_p = allocate(sizeof(Vector2D) * pointsN)
    cur_pts_v = allocate(sizeof(Vector2D) * pointsN)
    segmentTags = allocate(sizeof(Vector2D) * (pointsN - 1))
    referenceTags = allocate(sizeof(Vector2D) * (pointsN - 1))
    for i = 0 to pointsN - 1
        pbin.retrieve(base_pts[i])
        pbin.retrieve(cur_pts_p[i])
        pbin.retrieve(cur_pts_v[i])
        if i < pointsN - 1 then
            pbin.retrieve(segmentTags[i])
            pbin.retrieve(referenceTags[i])
        end if
    next i
    pbin.retrieve(tempInt)
    type_ = tempInt
    select case type_
    case DYNA_SFX_SPINNER
        pbin.retrieve(SFX_SPINNER.angle)
        pbin.retrieve(SFX_SPINNER.angle_v)
        pbin.retrieve(SFX_SPINNER.length)
    case DYNA_BASICPATH
        pbin.retrieve(BASICPATH.pathPointsN)
        BASICPATH.pathPoints = allocate(sizeof(Vector2D) * BASICPATH.pathPointsN)
        for i = 0 to BASICPATH.pathPointsN - 1
            pbin.retrieve(BASICPATH.pathPoints[i])
        next i
        pbin.retrieve(tempInt)
        BASICPATH.type_ = tempInt
        pbin.retrieve(BASICPATH.speed)    
        pbin.retrieve(BASICPATH.segment)
        pbin.retrieve(BASICPATH.segment_pos)
        pbin.retrieve(BASICPATH.path_length)
        pbin.retrieve(BASICPATH.toggleState)
        pbin.retrieve(BASICPATH.toggleTime)
    case DYNA_PIVOTER
        pbin.retrieve(PIVOTER.angle)
        pbin.retrieve(PIVOTER.angle_v)    
    end select
end sub


