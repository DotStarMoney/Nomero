#include "tinyspace.bi"
#include "utility.bi"
#include "debug.bi"
#include "crt.bi"
#include "printlog.bi"

#define OWP_INDEX_START 56
#define OWP_INDEX_END 70

#define TS_GETDYN(x, i) (*(x[i]))

constructor TinySpace
    dim as integer i
    this.t = 0.0
    block_n_rows = 0
    block_n_cols = 0
    block_data = 0
    bcount = 0
    dcount = 0
    dynamics_n = 0
    bodies_n = 0
    gravity = DEFAULT_GRAV
    for i = 0 to MAX_ARBS-1
        arbiters_n(i) = 0
    next i
    framesGone = 0
    lockID = -1
end constructor

destructor TinySpace
    if block_data <> 0 then
        deallocate(block_data)
    end if
end destructor

sub TinySpace.dividePosition(p as Vector2D, size as Vector2D)
    p.setX(int(p.x() / size.x()))
    p.setY(int(p.y() / size.y()))
end sub

function TinySpace.addBody(body_ as TinyBody ptr) as integer
    bodies(bodies_n) = body_
    bodies(bodies_n)->ind = bcount
    bodies_n += 1
    bcount += 1
    return bcount - 1
end function

sub TinySpace.setLock(id as integer)
	lockID = id
end sub
sub TinySpace.setUnlock()
	lockID = -1
end sub
function TinySpace.bodyN(b as integer) as integer
    dim as integer i
    for i = 0 to bodies_n - 1
        if bodies(i)->ind = b then return i
    next i
    return -1
end function

sub TinySpace.removeBody(index as integer) 
    dim as integer i, q, j
    i = 0
    index = bodyN(index)
    while i < bodies_n
        if i = index then
            arbiters_n(index) = 0
            for q = i to bodies_n - 2
                bodies(q) = bodies(q + 1)
                arbiters_n(q) = arbiters_n(q + 1)
                for j = 0 to arbiters_n(q + 1)
                    arbiters(q, j) = arbiters(q + 1, j)
                next j
            next q
            bodies_n -= 1
            exit while
        else 
            i += 1
        end if
    wend
end sub

function TinySpace.addDynamic(dyna_ as TinyDynamic ptr) as integer
	dim as Vector2D a, b
	
	if dyna_->getBB(a, b) = 0 then
		return -1
	end if
	
    dynamics(dynamics_n) = dyna_
    dynamics(dynamics_n)->ind = dcount
    spacialHash.insert(a, b, @dyna_)
    
    dynamics_n += 1
    dcount += 1
    return dcount - 1
end function

sub TinySpace.removeDynamic(index as integer)
	dim as TinyDynamic ptr dyn_ptr
	dim as integer i, q
	spacialHash.rollReset()
	do
		dyn_ptr = spacialHash.roll()
		if dyn_ptr <> 0 then
			if index = dyn_ptr->ind then 
				spacialHash.remove(dyn_ptr)
				exit do
			end if
		else
			exit do
		end if
	loop
    i = 0
    index = dynamicN(index)
    while i < dynamics_n
        if i = index then
            for q = i to dynamics_n - 2
                dynamics(q) = dynamics(q + 1)
            next q
            dynamics_n -= 1
            exit while
        else 
            i += 1
        end if
    wend
	
	
	'''''''''''''''''''''''''''
	'CLEAN UP ANY ARBITERS
	
	
end sub
function TinySpace.dynamicN(inst as integer) as integer
    dim as integer i
    for i = 0 to dynamics_n - 1
        if dynamics(dynamics_n)->ind = inst then return i
    next i
    return -1
end function

sub TinySpace.setBlockData(byval d as TinyBlock ptr, _
                           byval w as integer, _
                           byval h as integer, _
                           byval l as double)
                 
    dim as integer d_cnt
    
    this.block_n_rows = h
    this.block_n_cols = w
    this.block_l      = l
    this.block_data   = reallocate(this.block_data, h*w*sizeof(TinyBlock))
    
    for d_cnt = 0 to h*w - 1

            this.block_data[d_cnt].cModel        = d[d_cnt].cModel
            this.block_data[d_cnt].surface_speed = d[d_cnt].surface_speed
            this.block_data[d_cnt].elasticity    = d[d_cnt].elasticity
            this.block_data[d_cnt].friction      = d[d_cnt].friction
            
    next d_cnt 
    spacialHash.init(w * 16, h * 16, sizeof(TinyDynamic ptr))
    deallocate(d)
end sub

function TinySpace.getGroundingNormal(bod as integer,_
                                      dire as Vector2D,_
                                      prox as Vector2D,_
                                      dot as double) as Vector2D
    dim as Vector2D ret
    dim as integer i
    dim as double mdot
    ret = Vector2D(0,0)
    mdot = -2
    bod = bodyN(bod)
    for i = 0 to arbiters_n(bod) - 1
        if arbiters(bod, i).impulse * dire > dot then
            if -arbiters(bod, i).impulse * prox > mdot then
                ret = arbiters(bod, i).impulse
                mdot = arbiters(bod, i).impulse * prox
            end if
        end if
    next i
    return ret
end function

sub TinySpace.exportLevelGeometry(byref segsPtr as Vector2D ptr, byref segsN as integer)
	dim as integer scan_x, scan_y, i
    dim as BlockEndpointData_t segment(0 to 513)
    dim as integer             segment_n
    
    segment_n = 0
    
	redim as integer usedSpace(0 to block_n_cols-1, 0 to block_n_rows-1)
	
	
	for scan_y = 0 to block_n_rows-1
		for scan_x = 0 to block_n_cols-1
			usedSpace(scan_x, scan_y) = 0
		next scan_x
	next scan_y
	
	roi_x0 = 0
	roi_y0 = 0
	roi_x1 = block_n_cols
	roi_y1 = block_n_rows
	
	for scan_y = 0 to block_n_rows-1
		for scan_x = 0 to block_n_cols-1
			if usedSpace(scan_x, scan_y) = 0 then
				
				if getBlock(scan_x, scan_y).cModel <> EMPTY AndAlso _
				   getBlock(scan_x, scan_y-1).cModel = EMPTY then
 
					traceRing(scan_x, scan_y, _
							  segment(), segment_n, _
							  usedSpace())					
				end if
				
			end if
		next scan_x
	next scan_y 
	

	segsPtr = allocate(sizeof(Vector2D) * segment_n * 2)
	segsN = segment_n * 2
	for i = 0 to segment_n - 1
		segsPtr[i*2] = segment(i).a
		segsPtr[i*2+1] = segment(i).b
	next i
end sub

function TinySpace.lineAAEllipseCollide(a as Vector2D, b as Vector2D,_
                                        p as Vector2D,_
                                        rw as double, rh as double,_
                                        byref depth as double,_
                                        impulse as Vector2D) as integer
    dim as double   i 
    dim as double   r2h
    dim as double   r2w
    dim as Vector2D lineV
    dim as double   lmag
    dim as Vector2D lpoint
    dim as Vector2D epoint
    dim as Vector2D iperp
    dim as Vector2D cvec
    dim as double   cxmag
    
    lineV = b - a
    lmag = lineV.magnitude()
    lineV = lineV / lmag
    iperp = lineV.iperp()
    r2w = 1/(rw*rw)
    r2h = 1/(rh*rh)
    
    i = (p.y() - a.y())*lineV.y()*r2h + (p.x() - a.x())*lineV.x()*r2w
    i = i / (lineV.x()*lineV.x()*r2w + lineV.y()*lineV.y()*r2h)
    
    if i < 0 then 
        i = 0
    elseif i > lmag then
        i = lmag
    end if
    
    lpoint = a + lineV * i
    epoint = lpoint - p
    epoint = Vector2D(epoint.x() / rw, epoint.y() / rh)
    epoint.normalize()
    epoint = Vector2D(epoint.x() * rw, epoint.y() * rh) + p
    
    cvec  = epoint - lpoint
    cxmag = cvec * iperp
    
    if ((p - lpoint) * iperp < 0) orElse (cxmag > MIN_DEPTH) then
        return 0
    else
        depth = cxmag
        cvec.normalize()
        impulse = cvec
        return 1
    end if

                                            
end function

function TinySpace.lineCircleCollide(a as Vector2D, b as Vector2D,_
                                     p as Vector2D, r as double,_
                                     byref depth as double,_
                                     norm as Vector2D,_
                                     impulse as Vector2D,_
                                     byref ppos as Vector2D) as integer
                                     
    dim as Vector2D v_norm
    dim as Vector2D v_norm_iperp
    dim as double   proj_mag
    dim as double   seg_mag
    dim as Vector2D proj

    v_norm = b - a
    seg_mag = v_norm.magnitude()
    v_norm = v_norm / seg_mag
    v_norm_iperp = Vector2D(v_norm.y(), -v_norm.x())
        
    proj_mag = (p - a) * v_norm
    if proj_mag < 0 then 
        proj_mag = 0
    elseif proj_mag > seg_mag then
        proj_mag = seg_mag
    end if
    
    proj = a + proj_mag * v_norm
    ppos = proj
    depth = r - (p - proj).magnitude()
    impulse = p - proj
    impulse.normalize()
    
    norm = v_norm_iperp
    if (depth < -MIN_DEPTH) then
        return 0
    else
        return 1
    end if
end function

function TinySpace.block_getPoint(pt as integer,_
                                  p as Vector2D) as Vector2D
    dim as Vector2D np
    select case pt
    case 0
        np = p
    case 1
        np = p + Vector2D(0.25, 0)
    case 2
        np = p + Vector2D(0.5, 0)
    case 3
        np = p + Vector2D(0.75, 0)
    case 4
        np = p + Vector2D(1, 0)
    case 5
        np = p + Vector2D(1, 0.25)
    case 6
        np = p + Vector2D(1, 0.5)
    case 7
        np = p + Vector2D(1, 0.75)
    case 8
        np = p + Vector2D(1, 1)
    case 9
        np = p + Vector2D(0.75, 1)
    case 10
        np = p + Vector2D(0.5, 1)
    case 11
        np = p + Vector2D(0.25, 1)
    case 12
        np = p + Vector2D(0, 1)
    case 13
        np = p + Vector2D(0, 0.75)
    case 14
        np = p + Vector2D(0, 0.5)
    case 15
        np = p + Vector2D(0, 0.25)     
    end select
    return np * block_l
end function

function TinySpace.block_getRingPoint(block_type as integer,_
                                      pnt as integer) as integer
    
    static ring_table(1 to 71, 0 to 15) as integer = {_
        {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0},_
		{1, 2, 3, 4, 12, -1, -1, -1, -1, -1, -1, -1, 13, 14, 15, 0},_
		{1, 2, 3, 4, 5, 6, 7, 8, 0, -1, -1, -1, -1, -1, -1, -1},_
		{8, -1, -1, -1, -1, -1, -1, -1, 9, 10, 11, 12, 13, 14, 15, 0},_
		{-1, -1, -1, -1, 5, 6, 7, 8, 9, 10, 11, 12, 4, -1, -1, -1},_
		{6, -1, -1, -1, -1, -1, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0},_
		{-1, -1, -1, -1, -1, -1, -1, -1, 9, 10, 11, 12, 13, 14, 8, -1},_
		{-1, -1, -1, -1, -1, -1, 7, 8, 9, 10, 11, 12, 6, -1, -1, -1},_
		{-1, -1, -1, -1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 4, -1},_
		{1, 2, 3, 4, 5, 6, 12, -1, -1, -1, -1, -1, 13, 14, 15, 0},_
		{1, 2, 3, 4, 14, -1, -1, -1, -1, -1, -1, -1, -1, -1, 15, 0},_
		{1, 2, 3, 4, 5, 6, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1},_
		{1, 2, 3, 4, 5, 6, 7, 8, 14, -1, -1, -1, -1, -1, 15, 0},_
		{1, 2, 3, 4, 10, -1, -1, -1, -1, -1, 11, 12, 13, 14, 15, 0},_
		{1, 2, 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, 14, 15, 0},_
		{-1, -1, 3, 4, 5, 6, 7, 8, 2, -1, -1, -1, -1, -1, -1, -1},_
		{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0, -1, -1, -1, -1, -1},_
		{1, 2, 8, -1, -1, -1, -1, -1, 9, 10, 11, 12, 13, 14, 15, 0},_
		{10, -1, -1, -1, -1, -1, -1, -1, -1, -1, 11, 12, 13, 14, 15, 0},_
		{-1, -1, -1, -1, 5, 6, 7, 8, 9, 10, 4, -1, -1, -1, -1, -1},_
		{-1, -1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 2, -1, -1, -1},_
		{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0},_
		{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0},_
		{-1, -1, -1, -1, -1, -1, -1, -1, 9, 10, 11, 12, 13, 8, -1, -1},_
		{-1, -1, -1, -1, -1, -1, -1, 8, 9, 10, 11, 12, 13, 14, 7, -1},_
		{-1, -1, -1, -1, -1, -1, 7, 8, 9, 10, 11, 12, 13, 14, 15, 6},_
		{5, -1, -1, -1, -1, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0},_
		{-1, -1, -1, -1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 4},_
		{-1, -1, -1, -1, -1, 6, 7, 8, 9, 10, 11, 12, 13, 14, 5, -1},_
		{-1, -1, -1, -1, -1, -1, 7, 8, 9, 10, 11, 12, 13, 6, -1, -1},_
		{-1, -1, -1, -1, -1, -1, -1, 8, 9, 10, 11, 12, 7, -1, -1, -1},_
		{1, 2, 3, 4, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0},_
		{1, 2, 3, 4, 5, 14, -1, -1, -1, -1, -1, -1, -1, -1, 15, 0},_
		{1, 2, 3, 4, 5, 6, 13, -1, -1, -1, -1, -1, -1, 14, 15, 0},_
		{1, 2, 3, 4, 5, 6, 7, 12, -1, -1, -1, -1, 13, 14, 15, 0},_
		{1, 2, 3, 4, 5, 6, 7, 8, 13, -1, -1, -1, -1, 14, 15, 0},_
		{1, 2, 3, 4, 5, 6, 7, 14, -1, -1, -1, -1, -1, -1, 15, 0},_
		{1, 2, 3, 4, 5, 6, 15, -1, -1, -1, -1, -1, -1, -1, -1, 0},_
		{1, 2, 3, 4, 5, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},_
		{1, 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, 14, 15, 0},_
		{1, 2, 11, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, 14, 15, 0},_
		{1, 2, 3, 10, -1, -1, -1, -1, -1, -1, 11, 12, 13, 14, 15, 0},_
		{1, 2, 3, 4, 9, -1, -1, -1, -1, 10, 11, 12, 13, 14, 15, 0},_
		{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, -1, -1, -1, -1},_
		{-1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, -1, -1, -1, -1, -1},_
		{-1, -1, 3, 4, 5, 6, 7, 8, 9, 2, -1, -1, -1, -1, -1, -1},_
		{-1, -1, -1, 4, 5, 6, 7, 8, 3, -1, -1, -1, -1, -1, -1, -1},_
		{11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 12, 13, 14, 15, 0},_
		{1, 10, -1, -1, -1, -1, -1, -1, -1, -1, 11, 12, 13, 14, 15, 0},_
		{1, 2, 9, -1, -1, -1, -1, -1, -1, 10, 11, 12, 13, 14, 15, 0},_
		{1, 2, 3, 8, -1, -1, -1, -1, 9, 10, 11, 12, 13, 14, 15, 0},_
		{-1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, -1, -1, -1},_
		{-1, -1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 2, -1, -1, -1, -1},_
		{-1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 3, -1, -1, -1, -1, -1},_
		{-1, -1, -1, -1, 5, 6, 7, 8, 9, 4, -1, -1, -1, -1, -1, -1},_
		{1, 2, 3, 4, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},_
		{8, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1},_
		{-1, -1, -1, -1, 12, -1, -1, -1, -1, -1, -1, -1, 4, -1, -1, -1},_
		{6, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1},_
		{-1, -1, -1, -1, -1, -1, -1, -1, 14, -1, -1, -1, -1, -1, 8, -1},_
		{-1, -1, -1, -1, -1, -1, 12, -1, -1, -1, -1, -1, 6, -1, -1, -1},_
		{-1, -1, -1, -1, 14, -1, -1, -1, -1, -1, -1, -1, -1, -1, 4, -1},_
		{5, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},_
		{-1, -1, -1, -1, -1, -1, 15, -1, -1, -1, -1, -1, -1, -1, -1, 6},_
		{-1, -1, -1, -1, -1, -1, -1, 14, -1, -1, -1, -1, -1, -1, 7, -1},_
		{-1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 8, -1, -1},_
		{-1, -1, -1, -1, -1, -1, -1, 12, -1, -1, -1, -1, 7, -1, -1, -1},_
		{-1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, -1, -1, 6, -1, -1},_
		{-1, -1, -1, -1, -1, 14, -1, -1, -1, -1, -1, -1, -1, -1, 5, -1},_
		{-1, -1, -1, -1, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 4},_
		{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0}}

	if block_type <= 0 then
		return -1
	else
		return ring_table(block_type, pnt)
	end if
end function

sub TinySpace.vectorListImpulse(vecs_p() as Vector2D, v as Vector2D,_
                                res as Vector2D, byref fullCancel as integer,_
                                norm_skip() as integer, refactor as integer)
                           
    dim as integer i, j
    dim as double ang, w_ang, curMin, curMax
    dim as integer minIndex, maxIndex
    dim as Vector2D minVec, maxVec
    dim as Vector2D vecs(0 to ubound(vecs_p))
    
    
    if refactor = 0 then
		for i = 0 to ubound(vecs_p)
			vecs(i) = vecs_p(i)
		next i	
    else
    	j = 0
    	for i = 0 to ubound(vecs_p)
			if norm_skip(i) = 0 then
				vecs(j) = vecs_p(i)
				j += 1
			end if
		next i	
		if j = 0 then
			res = Vector2D(0,0)
		else
			redim preserve as Vector2D vecs(0 to j-1)
		end if
    end if
    
    if ubound(vecs) < 1 then
        if v * -vecs(0) < 0 orElse (vecs(0).x() = 0 andAlso vecs(0).y() = 0) then
            res = Vector2D(0,0)
            #ifdef DEBUG
				PRINTLOG "VLISTImpulse: Ignoring V"
			#endif
        else
            res = (v * -vecs(0)) * vecs(0)
            #ifdef DEBUG
				PRINTLOG "VLISTImpulse: Resolving V "
			#endif
        end if
        return
    end if
    
    curMin   = vecs(0).angle()
    curMax   = curMin
    minIndex = 0
    maxIndex = 0
    for i = 1 to ubound(vecs)
        if not (vecs(0).x() = 0 andAlso vecs(0).y() = 0) then
            ang = vecs(i).angle()
            w_ang = wrap(ang - curMin)
            if w_ang >= _PI_ then 
                curMin = ang
                minIndex = i
            elseif w_ang > wrap(curMax - curMin) then
                curMax = ang
                maxIndex = i
            end if
        end if
    next i

    

    maxVec = -vecs(maxIndex)
    minVec = -vecs(minIndex)
    

    #ifdef DEBUG
        PRINTLOG "VLISTImpulse: Data: " & v & maxVec & minVec
    #endif

    if (minVec.perp() * v) > 0 andAlso (maxVec.iperp() * v) > 0 then
        res = -v
        fullCancel = 1
        #ifdef DEBUG
            PRINTLOG "VLISTImpulse: Reversing V"
        #endif
    elseif (-minVec * v) > 0 andAlso (-maxVec * v) > 0 then
        res = Vector2D(0,0)
        fullCancel = 0
        #ifdef DEBUG
            PRINTLOG "VLISTImpulse: Ignoring V"
        #endif
    else
        #ifdef DEBUG
            PRINTLOG "VLISTImpulse: Resolving V ", 1
        #endif
        fullCancel = 0
        if (minVec * v) > (maxVec * v) then
            res = -(v * minVec) * minVec
            #ifdef DEBUG
                PRINTLOG "minVec"
            #endif
        else
            res = -(v * maxVec) * maxVec
            #ifdef DEBUG
                PRINTLOG "maxVec"
            #endif
        end if
    end if
                                            
end sub

sub TinySpace.traceRing(      x           as integer,_
                              y           as integer,_
                              segList()   as BlockEndpointData_t,_
                        byref curIndx     as integer,_
                              usedArray() as integer)
              
    #define VALID_BLOCK 1 '((block.cModel > 0) andAlso (block.cModel < 22))
    dim as integer   curPt 
    dim as integer   startPt
    dim as integer   curBlock
    dim as integer   i
    dim as integer   valid
    dim as integer   xs, ys
    dim as integer   xs_o, ys_o
    dim as integer   xs_prev, ys_prev
    dim as integer   xs_line, ys_line
    dim as integer   newPt
    dim as integer   oldPt
    dim as TinyBlock block
    dim as integer   blockChange
    dim as Vector2D  a_pt, b_pt
    dim as Vector2D  oldSlope, curSlope
    dim as Vector2D  firstSlope, lastSlope
    dim as integer   lastSwitch
    dim as integer   skipOWP
    dim as integer   noWrite
    dim as integer   startIndex
    dim as integer   firstCheck
    
    firstCheck = 1
    
    startIndex = curIndx
    firstSlope = Vector2D(0,0)
    'if curIndx = MAX_SEGS then exit sub
     
    xs = x
    ys = y

    curBlock = getBlock(xs, ys).cModel      
    for i = 0 to 15
        if block_getRingPoint(curBlock, i) > -1 then
            curPt = i
            exit for
        end if
    next i
      
    startPt = curPt
    oldPt = -1
    a_pt = block_getPoint(startPt, Vector2D(xs, ys))
    oldSlope = Vector2D(0,0)
    lastSwitch = 0
    skipOWP = 0
	xs_prev = xs
	ys_prev = ys
    do
        xs_o = xs
        ys_o = ys
        blockChange = 0
        curBlock = getBlock(xs, ys).cModel
        if lastSwitch = 0 then
            select case curPt
            case 0
                block = getBlock(xs - 1, ys)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 4) > -1) andAlso (oldPt <> -1) then
                    blockChange = 1
                    newPt = 4
                    xs -= 1
                end if
                block = getBlock(xs - 1, ys - 1)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 8) > -1) andAlso (oldPt <> -1) then
                    blockChange = 1
                    newPt = 8
                    ys -= 1
                    xs -= 1
                end if
                block = getBlock(xs, ys - 1)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 12) > -1) then
                    blockChange = 1
                    newPt = 12
                    ys -= 1
                end if
            case 1
				block = getBlock(xs, ys - 1)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 11) > -1) then
                    blockChange = 1
                    newPt = 11
                    ys -= 1
                end if
            case 2
                block = getBlock(xs, ys - 1)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 10) > -1) then
                    blockChange = 1
                    newPt = 10
                    ys -= 1
                end if
            case 3
				block = getBlock(xs, ys - 1)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 9) > -1) then
                    blockChange = 1
                    newPt = 9
                    ys -= 1
                end if	 
            case 4
                block = getBlock(xs, ys - 1)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 8) > -1) then
                    blockChange = 1
                    newPt = 8
                    ys -= 1
                end if
                block = getBlock(xs + 1, ys - 1)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 12) > -1) then
                    blockChange = 1
                    newPt = 12
                    ys -= 1
                    xs += 1
                end if
                block = getBlock(xs + 1, ys)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 0) > -1) then
                    blockChange = 1
                    newPt = 0
                    xs += 1
                end if        
            case 5
				block = getBlock(xs + 1, ys)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 15) > -1) then
                    blockChange = 1
                    newPt = 15
                    xs += 1
                end if  	
            case 6
                block = getBlock(xs + 1, ys)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 14) > -1) then
                    blockChange = 1
                    newPt = 14
                    xs += 1
                end if 
            case 7 
                block = getBlock(xs + 1, ys)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 13) > -1) then
                    blockChange = 1
                    newPt = 13
                    xs += 1
                end if                  
            case 8
                block = getBlock(xs + 1, ys)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 12) > -1) then
                    blockChange = 1
                    newPt = 12
                    xs += 1
                end if
                block = getBlock(xs + 1, ys + 1)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 0) > -1) then
                    blockChange = 1
                    newPt = 0
                    ys += 1
                    xs += 1
                end if
                block = getBlock(xs, ys + 1)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 4) > -1) then
                    blockChange = 1
                    newPt = 4
                    ys += 1
                end if  
            case 9
                block = getBlock(xs, ys + 1)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 3) > -1) then
                    blockChange = 1
                    newPt = 3
                    ys += 1
                end if      
            case 10
                block = getBlock(xs, ys + 1)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 2) > -1) then
                    blockChange = 1
                    newPt = 2
                    ys += 1
                end if   
            case 11
                block = getBlock(xs, ys + 1)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 1) > -1) then
                    blockChange = 1
                    newPt = 1
                    ys += 1
                end if              
            case 12
                block = getBlock(xs, ys + 1)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 0) > -1) then
                    blockChange = 1
                    newPt = 0
                    ys += 1
                end if
                block = getBlock(xs - 1, ys + 1)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 4) > -1) andAlso (oldPt <> -1) then
                    blockChange = 1
                    newPt = 4
                    ys += 1
                    xs -= 1
                end if
                block = getBlock(xs - 1, ys)
                if (blockChange = 0) andAlso VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 8) > -1) andAlso (oldPt <> -1) then
                    blockChange = 1
                    newPt = 8
                    xs -= 1
                end if      
            case 13
                block = getBlock(xs - 1, ys)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 7) > -1) andAlso (oldPt <> -1) then
                    blockChange = 1
                    newPt = 7
                    xs -= 1
                end if 
            case 14
                block = getBlock(xs - 1, ys)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 6) > -1) andAlso (oldPt <> -1) then
                    blockChange = 1
                    newPt = 6
                    xs -= 1
                end if    
            case 15
                block = getBlock(xs - 1, ys)
                if VALID_BLOCK andAlso _
                   (block_getRingPoint(block.cModel, 5) > -1) andAlso (oldPt <> -1) then
                    blockChange = 1
                    newPt = 5
                    xs -= 1
                end if                 
            end select
        end if
        
        if blockChange = 0 then
            newPt = block_getRingPoint(curBlock, curPt)
            
            lastSwitch = 0
            curSlope = block_getPoint(newPt, Vector2D(xs, ys)) - _
                       block_getPoint(curPt, Vector2D(xs_o, ys_o))
            if curIndx = startIndex andAlso oldPt <> -1 andAlso _
               ((firstSlope.x() = 0) and (firstSlope.y() = 0)) then
				firstSlope = curSlope
            end if
              
            if skipOWP = 0 then	
				if oldPt <> -1 then
					if (oldSlope.x() <> 0) orElse (oldSlope.y() <> 0) then
						if (oldSlope.x() <> curSlope.x()) orElse _
						   (oldSlope.y() <> curSlope.y()) then
						   
							b_pt = block_getPoint(curPt, Vector2D(xs_o, ys_o))
							
							if (b_pt.x() <> a_pt.x()) orElse (b_pt.y() <> a_pt.y()) then
							
								noWrite = 0
								if (getBlock(xs_prev, ys_prev).cModel >= OWP_INDEX_START andAlso _
								   getBlock(xs_prev, ys_prev).cModel <= OWP_INDEX_END) orElse _ 
								   (getBlock(xs_line, ys_line).cModel >= OWP_INDEX_START andAlso _
								   getBlock(xs_line, ys_line).cModel <= OWP_INDEX_END) then
								   if (oldSlope.x() < 0) then noWrite = 1
								end if
								
								if noWrite = 0 then
									#ifdef DEBUG_VERBOSE
										printlog "TRACERING: ", 1
										printlog "writing " &  a_pt & ", " & b_pt & ", " & _
										          xs_prev & ", " & ys_prev & ", " & xs_o & ", " & ys_o
									#endif

									segList(curIndx).a = a_pt
									segList(curIndx).b = b_pt
									segList(curIndx).tag = -1
									curIndx += 1   

									if curIndx = MAX_SEGS then exit sub
									
									xs_line = xs
									ys_line = ys     
								end if
								#ifdef DEBUG_VERBOSE
									printlog "TRACERING: ", 1
									printlog curSlope & ", " & oldSlope
								#endif
								if (sgn(curSlope.x()) = -1) andAlso _
								   (sgn(oldSlope.x()) = 1) andAlso _
								   (curSlope.y() = -oldSlope.y()) then
									
									usedArray(xs_o, ys_o) = 2
									
									#ifdef DEBUG_VERBOSE
										line (xs_o*16, ys_o*16)-(xs_o*16+15, ys_o*16+15), 93284834 +  usedArray(xs_o, ys_o) * 84390309288, B
									#endif
								end if
																
								a_pt = b_pt
							end if   
					
						end if
					end if
				end if
			end if
        else 
        	xs_prev = xs
			ys_prev = ys
            block = getBlock(xs, ys)
            if usedArray(xs, ys) = 2 then

				if skipOWP = 0 andAlso _
				  ((getBlock(xs_o, ys_o).cModel < OWP_INDEX_START) orElse _ 
				  (getBlock(xs_o, ys_o).cModel > OWP_INDEX_END)) then
					
					b_pt = block_getPoint(curPt, Vector2D(xs_o, ys_o))
					segList(curIndx).a = a_pt
					segList(curIndx).b = b_pt
					segList(curIndx).tag = -1
					
					if curIndx = MAX_SEGS then exit sub
					
					#ifdef DEBUG_VERBOSE
						printlog "TRACERING: ", 1
						printlog "writing 2, " & a_pt & ", " & b_pt
					#endif
					
					a_pt = b_pt
					curIndx += 1 
				end if
				
				skipOWP = 1
            else
				if skipOWP = 1 then
					a_pt = block_getPoint(curPt, Vector2D(xs_o, ys_o))
				end if
				skipOWP = 0
			end if
			
			
			if (getBlock(xs_o, ys_o).cModel >= OWP_INDEX_START) andAlso _
			   (getBlock(xs_o, ys_o).cModel <= OWP_INDEX_END) then
			   
				#ifdef DEBUG_VERBOSE
					printlog "TRACERING: ", 1
					printlog str(curSlope.x())
				#endif
				if (firstCheck = 0) andAlso (curSlope.x() >= 0) then 
					usedArray(xs_o, ys_o) = 2
					
					#ifdef DEBUG_VERBOSE
						line (xs_o*16, ys_o*16)-(xs_o*16+15, ys_o*16+15), 93284834 +  usedArray(xs_o, ys_o) * 84390309288, B
						printlog "TRACERING: ", 1
						printlog str(curSlope.x())
					#endif

				end if
			else
				usedArray(xs_o, ys_o) = 1
			end if
            lastSwitch = 1

			#ifdef DEBUG_VERBOSE
				'printlog "TRACERING: updating"
			#endif
        end if
		
		#ifdef DEBUG
			circle (block_getPoint(curPt, Vector2D(xs_o, ys_o)).x(), block_getPoint(curPt, Vector2D(xs_o, ys_o)).y()),1,&hffffff*rnd,,,,F
		#endif
		
        oldPt = curPt    
        curPt = newPt
        oldSlope = curSlope
        firstCheck = 0            
    loop until (xs = x) andAlso (ys = y) andAlso _
               (curPt = startPt) andAlso _
               ((not(sgn(firstSlope.x()) = -sgn(curSlope.x()))) or (blockChange = 0)) 
               
               
               
    if skipOWP = 0 andAlso (usedArray(xs, ys) <> 2) then
		b_pt = block_getPoint(curPt, Vector2D(xs, ys))
		
		segList(curIndx).a = a_pt
		segList(curIndx).b = b_pt
		segList(curIndx).tag = -1
				
		if (segList(startIndex).b.x() = segList(curIndx).a.x()) andAlso _
		   (segList(startIndex).b.y() = segList(curIndx).a.y()) andAlso _
		   (segList(startIndex).a.x() = segList(curIndx).b.x()) andAlso _
		   (segList(startIndex).a.y() = segList(curIndx).b.y()) then
		   
		   segList(startIndex).a = segList(curIndx).a
		   segList(startIndex).b = segList(curIndx).b
		   #ifdef DEBUG_VERBOSE
				printlog "TRACERING:", 1
				printlog "Swapping first and last owp..."
		   #endif
		else
			curIndx += 1
		end if
		
		
		if curIndx = MAX_SEGS then exit sub
		
		#ifdef DEBUG_VERBOSE
			printlog "TRACERING: ", 1
			printlog "writing 3, " & a_pt & ", " & b_pt
		#endif
		#ifdef DEBUG_VERBOSE
	else
		printlog "TRACERING: Finishing up, no final write: ", 1
		printlog str(skipOWP) & ", " & usedArray(xs_o, ys_o) 
		
		#endif
	end if
	lastSlope = curSlope
	if (curIndx - startIndex) > 1 then
		if (firstSlope.x() = lastSlope.x()) andAlso _
		   (firstSlope.y() = lastSlope.y()) then
			segList(startIndex).a = segList(curIndx - 1).a
			curIndx -= 1
			#ifdef DEBUG_VERBOSE
				printlog "TRACERING: connecting"
			#endif
		end if
	end if
end sub

function TinySpace.getArbiterN(bod as integer) as integer
    return arbiters_n(bodyN(bod))
end function

function TinySpace.getArbiter(bod as integer, i as integer) as ArbiterData_t
    return arbiters(bodyN(bod), i)
end function

function TinySpace.isGrounded(bod as integer, dot as double) as integer
    dim as integer i
    dim as Vector2D ground = Vector2D(0, -1)
    bod = bodyN(bod)
    if arbiters_n(bod) = 0 then exit function
    for i = 0 to arbiters_n(bod)-1
        if (ground * arbiters(bod, i).impulse) > dot andAlso (arbiters(bod, i).ignore = 0) then 
            return 1
        end if
    next i
    return 0
end function

function TinySpace.getBlock(xp as integer, yp as integer) as TinyBlock
    dim as TinyBlock ret
    if (xp >= block_n_cols) orElse (yp >= block_n_rows) orElse _
       (xp < roi_x0) orElse (xp >= roi_x1 + 1) orElse _
       (yp < roi_y0) orElse (yp >= roi_y1 + 1) then
        ret.cModel = 0
        return ret
    end if
    return this.block_data[yp * block_n_cols + xp]
end function

function TinySpace.getGravity() as Vector2D
    return Vector2D(0, gravity)
end function

sub TinySpace.refactorArbiters(arb_i as integer, seg() as BlockEndpointData_t, seg_n as integer, _
							   dyn_seg as TinyDynamic ptr ptr ptr, dyn_seg_n as integer)

	#define MINESCULE_RA 0.000001

	dim as integer i, j, q, k
	dim as Vector2D a, b
	dim as Vector2D d
	dim as Vector2D tempD
	dim as integer noOverlap
	dim as double slope, inter
	redim as ArbiterData_t tempArbs(0)
	dim as integer tempArbs_N
	
	for i = 0 to arbiters_n(arb_i) - 1
		if arbiters(arb_i, i).dynamic_ = 0 then
			a = arbiters(arb_i, i).a
			b = arbiters(arb_i, i).b
			d = b - a
			if abs(d.x()) > abs(d.y()) then
				slope = d.y() / d.x()
				inter = a.y() - slope * a.x()
				for j = 0 to seg_n - 1
					if abs(seg(j).a.y() - slope * seg(j).a.x() - inter) <= MINESCULE_RA then
						if abs(seg(j).b.y() - slope * seg(j).b.x() - inter) <= MINESCULE_RA then
						
							noOverlap = 0
							tempD = seg(j).a - b
							
							if (tempD * d) > 0 then 
								noOverlap = 1
							else
								tempD = a - seg(j).b
								if (tempD * d) > 0 then 
									noOverlap = 1
								end if
							end if
							if noOverlap = 0 then
															
								tempArbs_N += 1
								redim preserve as ArbiterData_t tempArbs(tempArbs_N - 1)
								tempArbs(tempArbs_N - 1) = arbiters(arb_i, i)
								tempArbs(tempArbs_N - 1).a = seg(j).a
								tempArbs(tempArbs_N - 1).b = seg(j).b
								tempArbs(tempArbs_N - 1).dynamic_ = 0
								seg(j).tag = tempArbs_N - 1

								exit for
							end if
						end if
					end if
				next j
			else
				slope = d.x() / d.y()
				inter = a.x() - slope * a.y()
				for j = 0 to seg_n - 1
					if abs(seg(j).a.x() - slope * seg(j).a.y() - inter) <= MINESCULE_RA then
						if abs(seg(j).b.x() - slope * seg(j).b.y() - inter) <= MINESCULE_RA then
							noOverlap = 0
							tempD = seg(j).a - b
							if (tempD * d) > 0 then 
								noOverlap = 1
							else
								tempD = a - seg(j).b
								if (tempD * d) > 0 then noOverlap = 1
							end if
							if noOverlap = 0 then
															
								tempArbs_N += 1
								redim preserve as ArbiterData_t tempArbs(tempArbs_N - 1)
								tempArbs(tempArbs_N - 1) = arbiters(arb_i, i)
								tempArbs(tempArbs_N - 1).a = seg(j).a
								tempArbs(tempArbs_N - 1).b = seg(j).b
								tempArbs(tempArbs_N - 1).dynamic_ = 0
								seg(j).tag = tempArbs_N - 1

								exit for
							end if
							
						end if
					end if
				next j
			end if		
		else
			for j = 0 to dyn_seg_n - 1
				for q = 0 to TS_GETDYN(dyn_seg, j)->getNumSegs() - 1
					if arbiters(arb_i, i).dynamic_tag = TS_GETDYN(dyn_seg, j)->getReferenceTag(q) then
						tempArbs_N += 1
						redim preserve as ArbiterData_t tempArbs(tempArbs_N - 1)
						tempArbs(tempArbs_N - 1) = arbiters(arb_i, i)	
						TS_GETDYN(dyn_seg, j)->setTag(q, tempArbs_N - 1)
					end if
				next q
			next j	
		end if
	next i
	
	arbiters_N(arb_i) = tempArbs_N
	for i = 0 to tempArbs_N - 1
		arbiters(arb_i, i) = tempArbs(i)
	next i

end sub

function Tinyspace.raycast(p as Vector2D, v as Vector2D,_
                           byref in_pt as Vector2D) as double
    dim as integer scan_x, scan_y
    dim as integer start_x, start_y, skipSearch
    dim as integer end_x, end_y, i, noset
    dim as double  tempSwap, mag, j, j2, crss, curBestDist
    dim as Vector2D tl, br, testP
    dim as Vector2D pt(0 to 1), vc(0 to 1)
    dim as double magn(0 to 1)
    
    dim as BlockEndpointData_t segment(0 to MAX_SEGS-1)
    dim as integer             segment_n    
	
	segment_n = 0
	noset = 1
	
	tl = p
	br = p + v
	
	
	if tl.x() > br.x() then
		tempSwap = tl.x()
		tl.setX(br.x())
		br.setX(tempSwap)
	end if
	
	if tl.y() > br.y() then
		tempSwap = tl.y()
		tl.setY(br.y())
		br.setY(tempSwap)
	end if	

    dividePosition(tl, Vector2D(block_l, block_l))
    dividePosition(br, Vector2D(block_l, block_l))
    br = br + Vector2D(1, 1)
    tl = tl - Vector2D(1, 1)
    
	start_x = _max_(cint(tl.x()), 0)
	start_y = _max_(cint(tl.y()), 0)
	end_x   = _min_(cint(br.x()), block_n_cols - 1)
	end_y   = _min_(cint(br.y()), block_n_rows - 1)
	
	skipSearch = 0
	if start_x > end_x orElse end_x < start_x orElse _
	   start_y > end_y orElse end_y < start_y then
	   skipSearch = 1
	end if 
	
	if skipSearch = 0 then
		
		roi_x0 = start_x
		roi_y0 = start_y
		roi_x1 = end_x
		roi_y1 = end_y
        
		redim as integer usedSpace(start_x to end_x, start_y to end_y)
		
		
		for scan_y = start_y to end_y
			for scan_x = start_x to end_x
				usedSpace(scan_x, scan_y) = 0
			next scan_x
		next scan_y
		
		
		
		for scan_y = start_y to end_y
			for scan_x = start_x to end_x
				if usedSpace(scan_x, scan_y) = 0 then
					
					if getBlock(scan_x, scan_y).cModel <> EMPTY AndAlso _
					   getBlock(scan_x, scan_y-1).cModel = EMPTY then
						
						traceRing(scan_x, scan_y, _
								  segment(), segment_n, _
								  usedSpace())
						
					end if
					
				end if
			next scan_x
		next scan_y  
		
		
		for i = 0 to segment_n - 1
			
			pt(0) = segment(i).a
			vc(0) = (segment(i).b - segment(i).a)
			magn(0) = vc(0).magnitude()
			vc(0) = vc(0) / magn(0)
			pt(1) = p
			vc(1) = v
			magn(1) = vc(1).magnitude
			vc(1) = vc(1) / magn(1)
			crss = vc(0).cross(vc(1))
			if crss <> 0 then
			
				j = -(vc(0).cross(pt(1)) + pt(0).cross(vc(0))) / crss
			
				testP = (pt(1) + j * vc(1))
				j2 = (testP - pt(0)) * vc(0)
			
				if (j >= 0) andAlso (j <= magn(1)) then
					if (j2 >= 0) andAlso (j2 <= magn(0)) then
						if noset = 1 orElse j < curBestDist then
							noset = 0
							curBestDist = j
							in_pt = testP
						end if
					end if
				end if

			end if
		next i
	end if
	
	if noset = 0 then 
		return curBestDist 
	else
		return -1
	end if
end function

sub TinySpace.step_time(byval t as double)
    dim as TinyBody ptr c
    dim as TinyBody wrk
    dim as TinyBlock block
    dim as Vector2D tl, br
    dim as integer scan_x, scan_y
    dim as integer start_x, start_y
    dim as integer end_x, end_y
    dim as integer axis_i
    dim as Vector2D dynaV
    dim as Vector2D test_p, impulse
    dim as integer i, q, j, k, hasSegment
    dim as integer v_cancel, f_cancel
    dim as double  depth, depthc, firstStep
    dim as double  cur_t, lo_t, hi_t, res_t
    dim as double  t_friction
    dim as double  contactI, bodyI
    dim as Vector2D fric_norm
    dim as Vector2D fric_force
    dim as Vector2D reflect
    dim as Vector2D vn
    dim as Vector2D ppos
    dim as double  t_tangent
    dim as double  max_depth
    dim as double  elapsed_t
    dim as integer hadPulse, oldArbiters_n
    dim as integer interpen, contacting
    dim as integer skipCollisionCheck
    dim as integer firstCollide, resolutions
    dim as integer numDynaArbs
    dim as integer iterate, firstCycle
    dim as ArbiterData_t tempArbs(0 to MAX_ARBS-1)
    dim as integer numArbs, cTarget
    dim as Vector2D v_adj, f_total, f_adj, f_bias
    Redim as Vector2D normals(0)
    Redim as integer  norm_skip(0)
    dim as Vector2D norm
    dim as Vector2D dynaVF
    dim as integer  skipCheck, normals_N, skipSearch
    dim as any ptr ptr curDynamics
    dim as TinyDynamic ptr ptr ptr curDynamicsList
    dim as integer     foundDynamics
    dim as Vector2D    lockAxis_Adj
    dim as Vector2D    slideDirection
    dim as Vector2D    tempV
    dim as integer     lockAxis_count
    dim as integer     retryStep, retry_i
    dim as integer 	   hadStaticArbs
    dim as integer     surfVSwitchMode
    
    
    dim as BlockEndpointData_t segment(0 to MAX_SEGS-1)
    dim as integer             segment_n
    dim as integer             numIgnore
   
    redim as integer usedSpace(0,0)
     
    i = 0
    #ifdef DEBUG
        PRINTLOG "------------------------------------------------------"
        PRINTLOG "TIME : " & str(timer)
        PRINTLOG "------------------------------------------------------"
    #endif
    
    while i < bodies_n
		if lockID <> -1 then i = lockID
    
        c = bodies(i)
        res_t = t

        f_total = c->f + Vector2D(0, c->m * gravity)
        
        test_p = c->p
        tl = Vector2D(c->p.x() - c->r * c->r_rat, c->p.y() - c->r)
        br = Vector2D(c->p.x() - c->r * c->r_rat, c->p.y() - c->r)
        tl.setX(_min_(tl.x(), test_p.x() - c->r * c->r_rat - abs(c->v.x()) * t))
        tl.setY(_min_(tl.y(), test_p.y() - c->r - abs(c->v.y()) * t))
        br.setX(_max_(br.x(), test_p.x() + c->r * c->r_rat + abs(c->v.x()) * t))
        br.setY(_max_(br.y(), test_p.y() + c->r + abs(c->v.y()) * t))

        dividePosition(tl, Vector2D(block_l, block_l))
        dividePosition(br, Vector2D(block_l, block_l))
        br = br + Vector2D(1, 1)
        tl = tl - Vector2D(1, 1)
        start_x = _max_(cint(tl.x()), 0)
        start_y = _max_(cint(tl.y()), 0)
        end_x   = _min_(cint(br.x()), block_n_cols - 1)
        end_y   = _min_(cint(br.y()), block_n_rows - 1)
        
        tl = tl * block_l
        br = br * block_l

		skipSearch = 0
        if (c->noCollide = 1) orElse _
           start_x >= end_x orElse end_x < start_x orElse _
		   start_y >= end_y orElse end_y < start_y then
           
		   skipSearch = 1
		   
		end if 
		
		
		if skipSearch = 0 then

			roi_x0 = start_x
			roi_y0 = start_y
			roi_x1 = end_x
			roi_y1 = end_y
			
			segment_n = 0
			
			redim as integer usedSpace(start_x to end_x, start_y to end_y)
			for scan_y = start_y to end_y
				for scan_x = start_x to end_x
					usedSpace(scan_x, scan_y) = 0
				next scan_x
			next scan_y
	  
			for scan_y = start_y to end_y
				for scan_x = start_x to end_x
					if usedSpace(scan_x, scan_y) = 0 then
						
						if getBlock(scan_x, scan_y).cModel <> EMPTY AndAlso _
						   getBlock(scan_x, scan_y-1).cModel = EMPTY then
							
							traceRing(scan_x, scan_y, _
									  segment(), segment_n, _
									  usedSpace())       
								
						end if
					end if
				next scan_x
			next scan_y
			
			foundDynamics = spacialHash.search(tl, br, curDynamicsList)
		end if
			
							
		#ifdef DEBUG
			printlog "Found: " & str(segment_n) & ", segments."
			for j = 0 to arbiters_n(i) - 1
				printlog str(arbiters(i, j).a) & ", " & str(arbiters(i, j).b)
			next j
		#endif

		
		if (segment_n > 0 orElse foundDynamics > 0) andAlso (c->noCollide = 0) andAlso (skipSearch = 0) then
			res_t = t
			firstCycle = 1
			v_adj = Vector2D(0,0)
			f_adj = Vector2D(0,0)
			cur_t = res_t
			lo_t = 0
			hi_t = cur_t
			skipCollisionCheck = 0
			firstCollide = 0
			resolutions = 0
			elapsed_t = 0
			
			while cur_t > 0 andAlso resolutions < (MAX_RESOLUTIONS+1)
				
				firstStep = 0
				iterate = 0
				wrk = *c
				cTarget = 0 					
				retry_i = 0

				for q = 0 to segment_n - 1
					segment(q).tag = -1
				next q
				for q = 0 to foundDynamics - 1
					for j = 0 to TS_GETDYN(curDynamicsList, i)->getNumSegs() - 1
						TS_GETDYN(curDynamicsList, i)->setTag(j, -1)
					next j
				next q

				refactorArbiters(i, segment(), segment_n, curDynamicsList, foundDynamics)
				
				'so for all arbiters from last time, if any of the collision segs for this frame match up
				' 	with them, give THOSE collision segs a tag pointing to the arbiter from last time
				
				do
					interpen = 0
					contacting = 0
					numArbs = 0
					retryStep = 0
					hadStaticArbs = 0
					
					if skipCollisionCheck = 0 then
						for q = 0 to segment_n - 1
							#ifdef DEBUG
								line(segment(q).a.x(), segment(q).a.y())-(segment(q).b.x(), segment(q).b.y()), rnd*&hffffff
							#endif
						
					
							if lineCircleCollide(segment(q).a, segment(q).b,_
												 wrk.p, wrk.r, _
												 depth, norm, impulse,_
												 ppos) <> 0 then   
								
								tempArbs(numArbs).a          = segment(q).a
								tempArbs(numArbs).b          = segment(q).b
								tempArbs(numArbs).depth      = depth
								tempArbs(numArbs).impulse    = impulse
								tempArbs(numArbs).velocity   = Vector2D(0,0)
								
								tempArbs(numArbs).guide_axis = ppos + impulse * wrk.r
								tempArbs(numArbs).guide_dot  = impulse
								
								hadStaticArbs = 1
												
								if segment(q).tag <> -1 then
									tempArbs(numArbs).new_ = 0
									tempArbs(numArbs).ignore = arbiters(i, segment(q).tag).ignore
									#ifdef DEBUG
										if tempArbs(numArbs).ignore = 1 then
											printlog "Setting tempArb to ignore... " & norm & ", " & arbiters(i, segment(q).tag).a & ", " & arbiters(i, segment(q).tag).b
										else
											printlog "Found previous Arbiter... " & norm
										end if
									#endif									
								else	
									tempArbs(numArbs).new_ = 1
									tempArbs(numArbs).ignore = 0
									#ifdef DEBUG
										printlog "Flagging new arbiter... " &  norm
									#endif	
								end if
								if ((norm * impulse) > 0) andAlso (tempArbs(numArbs).ignore = 0) then 
									if firstStep = 0 andAlso firstCollide = 1 then		
										if tempArbs(numArbs).new_ = 1 then 
											cTarget = 1 
										end if
									end if
								
									if depth > MIN_DEPTH then
										interpen = 1
										#ifdef DEBUG
											printlog "Arbiter penetrating... " & norm
										#endif
									elseif tempArbs(numArbs).new_ = 1 orElse cTarget = 0 then
										contacting = 1
										#ifdef DEBUG
											printlog "Arbiter contacting... " & norm
										#endif
									end if
								else
									tempArbs(numArbs).ignore = 1
									#ifdef DEBUG
										printlog "Ignoring arbiter... " & norm
									#endif
								end if
								
								numArbs += 1
							end if
						next q 
						
						'check all of the dynamic shapes for collision
						for q = 0 to foundDynamics - 1							
							numDynaArbs = TS_GETDYN(curDynamicsList, q)->circleCollide(wrk.p, wrk.r,_
																					   tempArbs(), numArbs,_
																					   max_depth, MIN_DEPTH)
							if numDynaArbs = -1 then
								interpen = 1
								exit for
							else
								for j = (numArbs - numDynaArbs) to numArbs - 1
									
									'if a returned arbiter holds a non-negative tag, this is not a new collision,
									'	and its information is stored in the arbiter number referenced by the tag.
									'	Otherwise, we have not been in resting contact with this segment.
									#ifdef DEBUG
										printlog "DYNA. Arbiter depth: " & tempArbs(j).depth
									#endif	

									if tempArbs(j).tag <> -1 then
										tempArbs(j).new_ = 0
										tempArbs(j).ignore = arbiters(i, tempArbs(j).tag).ignore
										#ifdef DEBUG
											if tempArbs(numArbs).ignore = 1 then
												printlog "DYNA. Setting tempArb to ignore... " & str(tempArbs(j).dynamic_norm)
											else
												printlog "DYNA. Found previous Arbiter... " & str(tempArbs(j).dynamic_norm)
											end if
										#endif		
									else
										tempArbs(j).new_ = 1
										tempArbs(j).ignore = 0
										#ifdef DEBUG
											printlog "DYNA. Flagging new arbiter... " &  tempArbs(j).dynamic_norm
										#endif	
									end if
									
									if (((tempArbs(j).dynamic_norm * tempArbs(j).impulse) > 0) andAlso _
										(tempArbs(j).ignore = 0)) orElse (TS_GETDYN(curDynamicsList, q)->isClosed() = 1) then 
																					
										
										if firstStep = 0 andAlso firstCollide = 1 then		
											if tempArbs(j).new_ = 1 then 
												cTarget = 1 
											end if
										end if
									
										'why this is needed(applies only to dynamics):
										'	usually, if we have a strong impulse, but are not in contact, the MIN_DEPTH window
										'	is large enough that we will catch the system at a time where the objects start colliding.
										'	if we are in contact here, the engine will catch the contact as "contacting on first frame"
										'	and resolve any impulses before the step. In the case of segments whose endpoints
										'	follow some non-constant parametric function, business is as usual if we were not in contact
										'	with this segment on the previous resolution. However, when we contact such a segment, it is
										'	possible that on the next frame the point of contact (if in contact) 
										'	with the segment will be of a different velocity of the current point. When this happens, 
										'   it is likely either that we interpenetrate at some arbitrarily small time step, or the segment 
										'   will fluctuate within MIN_DEPTH. 
										'
										'	SO, when we have collision with a segment we were previously in contact with, if
										'		we interpenetrate, compute adjustment and try time step again (does not count towards iterations)
										'		if in contact
										'
										'	What do we do with our dynamic arbiters after we hit a resolution time?
										'	(to be continued!)
										
										if tempArbs(j).depth > MIN_DEPTH then
											if tempArbs(j).new_ = 1 orElse (retry_i >= MAX_RETRYS) andAlso firstCollide = 1 then
												interpen = 1
											else
												if (retry_i >= MAX_RETRYS) then
													#ifdef DEBUG
														printlog "<!> ERROR, MAX NUMBER OF RETRYS EXCEEDED <!>"
													#endif
													interpen = 1
												else
													retryStep = 1
												end if
											end if
											#ifdef DEBUG
												printlog "DYNA. Arbiter interpenetrating."
											#endif
										elseif tempArbs(j).new_ = 1 orElse cTarget = 0 then
											contacting = 1
											#ifdef DEBUG
												printlog "DYNA. Arbiter contacting."
											#endif
										else
											#ifdef DEBUG
												printlog "DYNA. Arbiter not considered contacting or interpenetrating."
											#endif
										end if
										
									else
										tempArbs(j).ignore = 1
										#ifdef DEBUG
											printlog "DYNA. Ignoring arbiter... " & tempArbs(j).dynamic_norm
										#endif
									end if	
									
								next j
								
							end if
							
						next q
							
						#ifdef DEBUG
							PRINTLOG "         " & skipCollisionCheck & " " & firstCollide, 1 
							PRINTLOG " " & firstStep & " " & contacting & " " & interpen & ", " & cTarget & "," & cur_t & "," & numArbs
							PRINTLOG "         Work p: " & wrk.p & " v: "& wrk.v & " v_adj: " & v_adj & " f_adj: " & f_adj
						#endif
						if retryStep = 0 then
							retry_i = 0
							if firstCollide = 0 then
								' check if we are already in resting contact
								#ifdef DEBUG
									PRINTLOG "On first collide"
								#endif
								if interpen = 0 and contacting = 1 then 
									cur_t = 0
									#ifdef DEBUG
										PRINTLOG "Contacting on first frame, pre step"
									#endif
									exit do
								end if
							else
								if interpen = 1 then
									hi_t  = cur_t
									cur_t = (hi_t + lo_t) * 0.5
								else 
									if firstStep = 0 then
										#ifdef DEBUG
											PRINTLOG "Contacting on first step OR no collision"
										#endif
										exit do
									end if
									if contacting = 0 then
										lo_t = cur_t
										cur_t = (hi_t + lo_t) * 0.5
									else
										#ifdef DEBUG
											PRINTLOG "Contacting after resolution"
										#endif
										exit do
									end if
								end if
								firstStep = 1
							end if
						else
							retry_i += 1
							#ifdef DEBUG
								printlog "Running lock axis..."
							#endif
							'do lock axis
							lockAxis_Adj = Vector2D(0,0)
							axis_i = 0
							do
								lockAxis_count = 0
								for j = 0 to numArbs - 1
									slideDirection = (wrk.p + lockAxis_Adj) - tempArbs(j).guide_axis
									
									#ifdef DEBUG
										dim as Vector2D a, b
										a = tempArbs(j).guide_axis + tempArbs(j).guide_dot.perp *  100
										b = tempArbs(j).guide_axis + tempArbs(j).guide_dot.perp * -100
										line (a.x, a.y)-(b.x, b.y), &h00ffaa
										
									#endif
									
									tempV = tempArbs(j).guide_axis - wrk.p
									if (slideDirection * tempArbs(j).guide_dot) < 0 andALso (tempV.magnitude() <= wrk.r) then
										slideDirection = (slideDirection * tempArbs(j).guide_dot.perp()) * tempArbs(j).guide_dot.perp() + tempArbs(j).guide_axis
										slideDirection = slideDirection - (wrk.p + lockAxis_Adj)
										lockAxis_Adj = lockAxis_Adj + slideDirection + tempArbs(j).guide_dot * MIN_DEPTH * 0.5
									else
										lockAxis_count += 1
									end if
								next j
								axis_i += 1
							loop until (lockAxis_count = numArbs) orElse (axis_i >= MAX_AXIS_ITERATIONS)
							#ifdef DEBUG
								if axis_i >= MAX_AXIS_ITERATIONS then
									printlog "<!> ERROR, LOCK AXIS BAILING OUT <!>"
								end if
								printlog "Lock axis proc returns: " & str(lockAxis_Adj) & ", in " & str(axis_i) & " iterations."
							#endif
						end if 
					else
						skipCollisionCheck = 0
						#ifdef DEBUG
							PRINTLOG "skipping first collision check"
						#endif
					end if
					
					
					if retryStep = 0 then
						for q = 0 to foundDynamics - 1							
							TS_GETDYN(curDynamicsList, q)->offset_time(elapsed_t + cur_t)
						next q
					end if

					wrk = *c
					wrk.v = wrk.v + ((f_total + f_adj) / wrk.m) * cur_t + v_adj
					if wrk.v.magnitude() > TERM_VEL then
						wrk.v.normalize()
						wrk.v = wrk.v * TERM_VEL
					end if
					wrk.p = wrk.p + wrk.v * cur_t + _
							iif(retryStep = 1, lockAxis_Adj, Vector2D(0,0)) + _
							iif(wrk.dynaID <> -1, wrk.surfaceV * cur_t, Vector2D(0,0))
												
					#ifdef DEBUG
						circle (wrk.p.x(), wrk.p.y()), wrk.r, rgba(0,255.0*(_max_(iterate,1))/10.0,0,32),,,wrk.r_rat,F
					#endif
					
					if retryStep = 0 then
						firstCollide = 1
						iterate += 1
					end if
				loop until iterate > MAX_ITERATIONS
				
				
				#ifdef DEBUG
					if iterate = MAX_ITERATIONS + 1 then
						PRINTLOG "<!> ERROR, BAILING OUT <!>"
						wrk.v = Vector2D(0,0)
					end if
				#endif
				hadPulse = 0
				arbiters_n(i) = numArbs
				numIgnore = 0
				tempV = wrk.v
				for q = 0 to numArbs-1
					arbiters(i, q) = tempArbs(q)
					if arbiters(i, q).ignore = 0 then 
						if arbiters(i, q).new_ = 1 then hadPulse = 1
						dynaV = vector2D(0,0)
						if arbiters(i, q).dynamic_ = 1 then
						
							contactI = (arbiters(i, q).velocity * (-arbiters(i, q).impulse))
							bodyI = (tempV * (-arbiters(i, q).impulse))
							
							if -contactI < 0 then
								if -bodyI < 0 then
									if bodyI > contactI then
										dynaV = -contactI * arbiters(i, q).impulse
										#ifdef DEBUG 
											printlog "Dynamic contact velocity: body is moving towards point, point moves away, body is faster than point."
										#endif
									else
										if hadStaticArbs = 0 then 
											dynaV = -contactI * arbiters(i, q).impulse
											
										end if
										
										#ifdef DEBUG 
											printlog "Dynamic contact velocity: body is moving towards point, point moves away, body is slower than point."
										#endif
									end if
								else
									#ifdef DEBUG 
										printlog "Dynamic contact velocity: body is moving away from point, point moves away from body."
									#endif
								end if
							else
								if -bodyI < 0 then
									dynaV = -contactI * arbiters(i, q).impulse
									#ifdef DEBUG 
										printlog "Dynamic contact velocity: body is moving towards point, point moves towards body."
									#endif
								else
									if abs(bodyI) > abs(contactI) then
										#ifdef DEBUG 
											printlog "Dynamic contact velocity: body is moving away from point, point moves towards body, body is faster than point."
										#endif
									else
										dynaV = (abs(contactI) - abs(bodyI)) * arbiters(i, q).impulse
										#ifdef DEBUG 
											printlog "Dynamic contact velocity: body is moving away from point, point moves towards body, body is slower than point."
										#endif
									end if
								end if
							end if
							
							#ifdef DEBUG 
								line (wrk.p.x(), wrk.p.y())-(wrk.p.x()+dynaV.x*30, wrk.p.y()+dynaV.y*30)
							#endif
													
						end if
						arbiters(i, q).dynaV = dynaV
					else
						numIgnore += 1
					end if
				next q
				normals_N = 0
				

				'by now, we have a list of all collisions, and we know if any are new
				if arbiters_n(i) > numIgnore then
					normals_N = 0
					f_bias = Vector2D(0,0)
					depthc = 0
					redim as Vector2D normals(0)
					Redim as integer  norm_skip(0)
					for q = 0 to arbiters_n(i)-1
						if arbiters(i, q).ignore = 0 then
							normals_N += 1
							redim preserve as Vector2D normals(normals_N - 1)
							redim preserve as integer  norm_skip(normals_N - 1)
							normals(normals_N - 1) = arbiters(i, q).impulse
							if arbiters(i, q).dynamic_ = 1 then
								norm_skip(normals_N - 1) = 1
							else
								norm_skip(normals_N - 1) = 0
							end if
							if arbiters(i, q).depth > depthc then depthc = arbiters(i, q).depth
							if arbiters(i, q).new_ = 1 then f_bias = f_bias + normals(normals_N - 1)
							
						end if
					next q
					f_bias.normalize()
					if normals_N = 0 then normals(0) = Vector2D(0,0)
					
					
					dynaVF = Vector2D(0,2)
					k = -1
					for q = 0 to numArbs - 1	
						if (arbiters(i, q).ignore = 0) then
							if arbiters(i, q).impulse.y < dynaVF.y then
								k = q
								dynaVF = arbiters(i, q).impulse
							end if
						end if
					next q
					surfVSwitchMode = 0
					if k = -1 then 
						if wrk.dynaID <> -1 then surfVSwitchMode = 1
					else
						if arbiters(i, k).dynamic_ = 1 then
							if wrk.dynaID <> -1 then
								if wrk.dynaID <> arbiters(i, k).dynamic_tag then surfVSwitchMode = 3
							else
								surfVSwitchMode = 2
							end if
						else
							if wrk.dynaID <> -1 then surfVSwitchMode = 1
						end if
					end if
					
					if k <> -1 then 
						if arbiters(i, k).dynamic_ = 1 then
							wrk.surfaceV = (arbiters(i, k).velocity * arbiters(i, k).impulse.perp) * arbiters(i, k).impulse.perp
						end if
					end if
					select case surfVSwitchMode
					case 1
						wrk.dynaID = -1
						wrk.v = wrk.v + wrk.surfaceV
						#ifdef DEBUG
							printlog "DETATCH!"
						#endif
					case 2
						wrk.dynaID = arbiters(i, k).dynamic_tag
						wrk.v = wrk.v - wrk.surfaceV
						#ifdef DEBUG
							printlog "ATTACH!"
						#endif
					case 3
						wrk.dynaID = arbiters(i, k).dynamic_tag
						#ifdef DEBUG
							printlog "SWITCH!"
						#endif
					end select
					
					if hadPulse = 1 then
						vectorListImpulse(normals(), wrk.v + iif(c->dynaID <> -1, c->surfaceV, Vector2D(0,0)), v_adj, v_cancel, norm_skip(), 0)
						vn = wrk.v
						vn.normalize()
						if (-(wrk.v + iif(c->dynaID <> -1, c->surfaceV, Vector2D(0,0))) * f_bias) > MIN_TRIG_ELAS_DV then
							reflect = (-(wrk.v + iif(c->dynaID <> -1, c->surfaceV, Vector2D(0,0))) * f_bias) * f_bias
							reflect = reflect * wrk.elasticity
							#ifdef DEBUG
								line (c->p.x(), c->p.y())-(c->p.x() - reflect.x(), c->p.y() - reflect.y()), &hffcc00
								line (c->p.x(), c->p.y())-(c->p.x() - wrk.v.x(), c->p.y() - wrk.v.y()), &hffcc00

							#endif
							v_adj = v_adj + reflect
						end if
					else
						vectorListImpulse(normals(), wrk.v + iif(c->dynaID <> -1, c->surfaceV, Vector2D(0,0)), v_adj, v_cancel, norm_skip(), 0)
					end if
					
					for q = 0 to numArbs - 1
						if arbiters(i, q).dynamic_ = 1 then
							if (arbiters(i, q).ignore = 0) andAlso _
							  ((arbiters(i, q).impulse * arbiters(i, q).dynamic_norm) > MIN_DYNAV_ADJ_DOT) then
								v_adj = v_adj + arbiters(i, q).dynaV
							end if
						end if
					next q
					
					
					vectorListImpulse(normals(), f_total, f_adj, f_cancel, norm_skip(), 0)
					
								
					'f_adj = normal force
					if f_cancel = 0 then
						t_friction = f_adj.magnitude() * wrk.friction ' * [surface friction]
						fric_force = f_adj.perp()
						fric_force.normalize()
						t_tangent = (fric_force * wrk.v)
						
					
						if abs(t_tangent) > MIN_TRIG_FRIC_V then
						
							if (t_friction / c->m) * res_t < abs(t_tangent) then
								#ifdef DEBUG
									PRINTLOG "FRICTION: Friction applied normally..."
								#endif
								f_adj = f_adj - sgn(t_tangent) * t_friction * fric_force
							else
								#ifdef DEBUG
									PRINTLOG "FRICTION: Full velocity and force cancel: ", 1
									PRINTLOG (t_tangent * fric_force) & ", " & v_adj
								#endif
								f_adj = f_adj - ((t_tangent / res_t) * c->m) * fric_force
								v_adj = v_adj - t_tangent * fric_force
							end if
						else
							#ifdef DEBUG
								PRINTLOG "FRICTION: Reducing force to zero"
							#endif
							if abs(f_total*fric_force) < t_friction then
								f_adj = f_adj - (f_total * fric_force) * fric_force
							end if
						end if
					end if
				else
					if wrk.dynaID <> -1 then
						c->dynaID = -1
						c->v = c->v + c->surfaceV
						#ifdef DEBUG
							printlog "DETATCH!"
						#endif
					end if
				end if
				
				if (normals_N = 0) then
					c->v = c->v + ((f_total + f_adj) / c->m) * cur_t + v_adj
					if c->v.magnitude() > TERM_VEL then
						c->v.normalize()
						c->v = c->v * TERM_VEL
					end if
					c->p = c->p + c->v * cur_t + iif(c->dynaID <> -1, c->surfaceV * cur_t, Vector2D(0,0))
					#ifdef DEBUG
						PRINTLOG "Resolve without wrk value"
					#endif
				elseif cur_t > 0 then
					*c = wrk
					if (cur_t = res_t) then 
						c->v = c->v + v_adj
						#ifdef DEBUG
							PRINTLOG "Setting final velocity... ", 1
							PRINTLOG str(v_adj) & " ", 1
						#endif    
					end if
					#ifdef DEBUG
						PRINTLOG "Taking wrk value"
					#endif
				else
					#ifdef DEBUG
						PRINTLOG "Skipping c setting, calculating v_adj and f_adj, time:"& cur_t
					#endif
				end if
				if normals_N > 0 then
					c->didCollide = 1
					wrk.didCollide = 1
				end if
				
				elapsed_t += cur_t
				res_t -= cur_t
				cur_t = res_t
				lo_t = 0
				hi_t = cur_t
				 
				#ifdef DEBUG
					PRINTLOG " v_adj: " & v_adj & " f_adj: " & f_adj & " f_total: " & f_total 
					PRINTLOG "Current time: " & cur_t
					PRINTLOG "Had pulse: " & hadPulse
					PRINTLOG "arbiters_n: " & arbiters_n(i)
					PRINTLOG "Current P,V: " & c->p & c->v
					PRINTLOG "Frames: " & str(framesGone)
					PRINTLOG "Energy: " & (1/2 * c->m * (c->v.magnitude()^2))
					if arbiters_n(i) <> 0 then
						for q = 0 to ubound(normals)
							circle(c->p.x() + -normals(q).x()*c->r * c->r_rat, c->p.y() + -normals(q).y()*c->r), 3, &hff0000,,,,F
						next q
					end if
				#endif
									
				skipCollisionCheck = 1
				firstCycle = 0
				resolutions += 1
			wend
			
		else
			if c->dynaID <> -1 then
				c->dynaID = -1
				c->v = c->v + c->surfaceV
				#ifdef DEBUG
					printlog "DETATCH!"
				#endif
			end if
			arbiters_n(i) = 0
	
			cur_t = t
			c->v = c->v + (f_total / c->m) * cur_t            
			if c->v.magnitude() > TERM_VEL then
				c->v.normalize()
				c->v = c->v * TERM_VEL
			end if
			c->p = c->p + c->v * cur_t
			
			
			#ifdef DEBUG
				printlog "NO COLLIDE"
				PRINTLOG "Current P,V: " & c->p & c->v
			#endif
			
			
			
		end if  
	
		if curDynamicsList then deallocate(curDynamicsList)

		if lockID <> -1 then exit while
        i += 1
    wend
    
	for i = 0 to dynamics_n - 1
		dynamics(i)->step_time(t)
	next i
    
	framesGone += 1
end sub
