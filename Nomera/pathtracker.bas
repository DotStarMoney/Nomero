#include "pathtracker.bi"
#include "utility.bi"
#include "level.bi"
#include "tinyspace.bi"
#include "player.bi"
#include "crt.bi"
#include "gamespace.bi"
#include "constants.bi"

#define BOUNDINGBOX_SLOP 8

static as integer PathTracker.seg_count = 0
static as integer PathTracker.edge_count = 0
static as integer PathTracker.interestStatic = 0


constructor PathTracker()
	nodes.init(sizeof(PathTracker_Node_t))
	edges.init(sizeof(PathTracker_Edge_t ptr))
	children.init(sizeof(PathTracker_Child_t))
	oldMB = 0
end constructor

destructor PathTracker()
	flush() 
end destructor

function PathTracker.removeInterestID(data_ as any ptr) as integer 
	dim as PathTracker_Edge_t ptr ptr curEdge
	curEdge = data_
	if (*curEdge)->ID = interestStatic then return 1
	return 0
end function

sub PathTracker.flush()
	dim as PathTracker_Node_t ptr curNode
	dim as PathTracker_Edge_t ptr ptr curEdge
 
	nodes.resetRoll()
	do
		curNode = nodes.roll()
		if curNode then
			delete(curNode->segments)
		else
			exit do
		end if
	loop	
	nodes.flush()  
	
	edges.resetRoll()
	do
		curEdge = edges.roll()
		if curEdge then
			delete(*curEdge)
		else
			exit do
		end if
	loop	
	edges.flush()  
	children.flush()
	spacialEdgePTRs.flush()
	spacialNodeIDs.flush()
end sub

sub PathTracker.init(link_p as ObjectLink)
	flush()
	link = link_p
	spacialNodeIDs.init(link.level_ptr->getWidth() * 16, link.level_ptr->getHeight() * 16, sizeof(integer))
	spacialEdgePTRs.init(link.level_ptr->getWidth() * 16, link.level_ptr->getHeight() * 16, sizeof(PathTracker_Edge_t ptr))
	currentNode = -1
	enable = 0
	onNode = 0
	onEdge = 0
	lastJump = -1
	currentEdge = 0
	highIndex = -1
	interestID = 0
	buildNodes()
end sub

sub PathTracker.buildNodes()
	dim as Vector2D ptr segs
	dim as integer      segs_n
	dim as integer      i, q
	dim as integer		falseAlarm
	dim as Vector2D     a, b	
	redim as PathTracker_Segment_t objectSegs(0)
	dim as integer                 objectSegs_N

	nodes.flush()
	nodes.init(sizeof(PathTracker_Node_t))
	
	link.tinySpace_ptr->exportLevelGeometry(segs, segs_n)

	if segs_n = 0 then exit sub
   
	for i = 0 to (segs_n*0.5) - 1 
		a = segs[i*2]
		b = segs[i*2 + 1]

		if objectSegs_N = 0 then		
			objectSegs_N += 1
			redim preserve as PathTracker_Segment_t objectSegs(objectSegs_N - 1)
			objectSegs(objectSegs_N - 1).a = a
			objectSegs(objectSegs_N - 1).b = b
		else
			if b = objectSegs(0).a then
				objectSegs_N += 1
				redim preserve as PathTracker_Segment_t objectSegs(objectSegs_N - 1)
				objectSegs(objectSegs_N - 1).a = a
				objectSegs(objectSegs_N - 1).b = b
                dumpStaticShape(objectSegs())
				objectSegs_N = 0
			else
            
				falseAlarm = 0	
                for q = 0 to objectSegs_N - 1
                    if a = objectSegs(q).b orElse b = objectSegs(q).b then 
                        falseAlarm = 1
                        exit for
                    end if
                next q
				
				if falseAlarm then
					objectSegs_N += 1
					redim preserve as PathTracker_Segment_t objectSegs(objectSegs_N - 1)
					objectSegs(objectSegs_N - 1).a = a
					objectSegs(objectSegs_N - 1).b = b
				else
					dumpStaticShape(objectSegs())
					objectSegs_N = 1
					redim preserve as PathTracker_Segment_t objectSegs(objectSegs_N - 1)
					objectSegs(objectSegs_N - 1).a = a
					objectSegs(objectSegs_N - 1).b = b
				end if
			end if
		end if
	next i
	if objectSegs_N <> 0 then
		dumpStaticShape(objectSegs())
	end if
	deallocate(segs)
end sub

sub PathTracker.dumpStaticShape(segs() as PathTracker_Segment_t)
	dim as integer i, q, j, shiftAmount
    dim as integer boundA, boundB
	dim as integer leftMostIndex
	dim as integer endSplit
	dim as integer lastSplit
	dim as integer doCont
	dim as integer old_safe
	dim as integer safe
	redim as PathTracker_Segment_t paramSegs(0)
	dim as Vector2d d
	
    /'
    dim as integer col = rnd * &h7e7e7e + &h7f7f7f
    for i = 0 to ubound(segs)
        draw string (segs(i).a.x()*0.5, segs(i).a.y()*0.5), str(i), col
        line (segs(i).a.x()*0.5, segs(i).a.y()*0.5)-(segs(i).b.x()*0.5, segs(i).b.y()*0.5), col
    next i
    sleep
    '/
    
	if segs(0).a.x < segs(0).b.x then
        leftMostIndex = 0
        while leftMostIndex <= ubound(segs)
            if (segs(leftMostIndex).a.x = segs(leftMostIndex).b.x) then
                leftMostIndex += 1
            else
                exit while
            end if
        wend
		for i = 1 to ubound(segs)
			if segs(i).a.x < segs(leftMostIndex).a.x andALso (segs(i).a.x <> segs(i).b.x) then
				leftMostIndex = i
			end if
		next i
        /'
        line (segs(leftMostIndex).a.x()*0.5, segs(leftMostIndex).a.y()*0.5)-(segs(leftMostIndex).b.x()*0.5, segs(leftMostIndex).b.y()*0.5), &hffffff
        circle (segs(leftMostIndex).a.x()*0.5, segs(leftMostIndex).a.y()*0.5), 5
        circle (segs(leftMostIndex).b.x()*0.5, segs(leftMostIndex).b.y()*0.5), 5
        '/
        shiftAmount = leftMostIndex
		if shiftAmount <> 0 then
			i = shiftAmount
            q = ubound(segs) + 1 - i
            while i <> q
                if i < q then
                    boundA = shiftAmount - i
                    boundB = shiftAmount + q - i
                    for j = 0 to i-1
                        swap segs(boundA + j), segs(boundB + j)
                    next j
                    q -= i
                else
                    boundA = shiftAmount - i
                    boundB = shiftAmount
                    for j = 0 to q-1
                        swap segs(boundA + j), segs(boundB + j)
                    next j 
                    i -= q
                end if
            wend
            boundA = shiftAmount - i
            boundB = shiftAmount
            for j = 0 to i-1
                swap segs(boundA + j), segs(boundB + j)
            next j 
		end if
        /'
        print leftMostIndex
        for i = 0 to ubound(segs)
            draw string (segs(i).a.x()*0.5 + 5, segs(i).a.y()*0.5 - 10), str(i)
            line (segs(i).a.x()*0.5, segs(i).a.y()*0.5)-(segs(i).b.x()*0.5, segs(i).b.y()*0.5), col
        next i
        sleep
        '/
		lastSplit = 0 
		old_safe = 0
		safe = 0
		for i = 0 to ubound(segs)
			doCont = 0
			safe = 0
			d = segs(i).b - segs(i).a
			if d.x > 0 then
				if d.x >= d.y then
					doCont = 1
					safe = 1
				end if
			elseif (d.x = 0) andAlso (d.magnitude() <= 8) andAlso (i < ubound(segs)) then
				if old_safe = 1 then
					doCont = 1
				end if
			end if
			if doCont = 0 then
				if lastSplit < i then
					q = lastSplit
					endSplit = i
					if old_safe = 0 then endSplit -= 1
					redim as PathTracker_Segment_t paramSegs(0 to ((endSplit - lastSplit) - 1))
					while q < endSplit	
						paramSegs(q - lastSplit) = segs(q)
						q += 1
					wend
					addNode(paramSegs(), PT_STATIC)
				end if
				lastSplit = i + 1
			end if
			
			old_safe = safe
		next i
		if doCont = 1 then
			q = lastSplit
			endSplit = i
			if old_safe = 0 then endSplit -= 1
			redim as PathTracker_Segment_t paramSegs(0 to ((endSplit - lastSplit) - 1))
			while q < endSplit	
				paramSegs(q - lastSplit) = segs(q)
				q += 1
			wend
			addNode(paramSegs(), PT_STATIC)
		end if
	else
        leftMostIndex = 0
        while leftMostIndex <= ubound(segs)
            if (segs(leftMostIndex).a.x = segs(leftMostIndex).b.x) then
                leftMostIndex += 1
            else
                exit while
            end if
        wend
		for i = 1 to ubound(segs)
			if segs(i).a.x > segs(leftMostIndex).a.x andALso (segs(i).a.x <> segs(i).b.x) then
				leftMostIndex = i
			end if
		next i
        
        shiftAmount = leftMostIndex
		if shiftAmount <> 0 then
			i = shiftAmount
            q = ubound(segs) + 1 - i
            while i <> q
                if i < q then
                    boundA = shiftAmount - i
                    boundB = shiftAmount + q - i
                    for j = 0 to i-1
                        swap segs(boundA + j), segs(boundB + j)
                    next j
                    q -= i
                else
                    boundA = shiftAmount - i
                    boundB = shiftAmount
                    for j = 0 to q-1
                        swap segs(boundA + j), segs(boundB + j)
                    next j 
                    i -= q
                end if
            wend
            boundA = shiftAmount - i
            boundB = shiftAmount
            for j = 0 to i-1
                swap segs(boundA + j), segs(boundB + j)
            next j 
		end if
        
        
        
		lastSplit = 0 
		old_safe = 0
		safe = 0
		for i = 0 to ubound(segs)
			doCont = 0
			safe = 0
			d = segs(i).b - segs(i).a
			if d.x < 0 then
				if d.x <= d.y then
					doCont = 1
					safe = 1
				end if
			elseif (d.x = 0) andAlso (d.magnitude() <= 8) andAlso (i < ubound(segs)) then
				if old_safe = 1 then
					doCont = 1
				end if
			end if
			if doCont = 0 then
				if lastSplit < i then
					q = lastSplit
					endSplit = i
					if old_safe = 0 then endSplit -= 1
					redim as PathTracker_Segment_t paramSegs(0 to ((endSplit - lastSplit) - 1))
					while q < endSplit	
						paramSegs(q - lastSplit) = segs(q)
						q += 1
					wend
					addNode(paramSegs(), PT_STATIC)
				end if
				lastSplit = i + 1
			end if
			
			old_safe = safe
		next i
		if doCont = 1 then
			q = lastSplit
			endSplit = i
			if old_safe = 0 then endSplit -= 1
			redim as PathTracker_Segment_t paramSegs(0 to ((endSplit - lastSplit) - 1))
			while q < endSplit	
				paramSegs(q - lastSplit) = segs(q)
				q += 1
			wend
			addNode(paramSegs(), PT_STATIC)
		end if
	end if
end sub



sub PathTracker.addNode(segs() as PathTracker_Segment_t, type_ as integer)
	dim as PathTracker_Node_t curNode
	dim as integer i
	dim as Vector2D tl, dr
	
	seg_count += 1
	
	curNode.segments_n = ubound(segs) + 1
	curNode.segments = new PathTracker_Segment_t[curNode.segments_n]
	tl = segs(0).a
	dr = segs(0).b
    'locate 1,1: print seg_count
	for i = 0 to ubound(segs)
        'line (segs(i).a.x*0.5,segs(i).a.y*0.5)-(segs(i).b.x*0.5,segs(i).b.y*0.5)
        if segs(i).a.x() < tl.x() then tl.setX(segs(i).a.x())
		if segs(i).b.x() < tl.x() then tl.setX(segs(i).b.x())
		if segs(i).a.y() < tl.y() then tl.setY(segs(i).a.y())
		if segs(i).b.y() < tl.y() then tl.setY(segs(i).b.y())		
		if segs(i).a.x() > dr.x() then dr.setX(segs(i).a.x())
		if segs(i).b.x() > dr.x() then dr.setX(segs(i).b.x())
		if segs(i).a.y() > dr.y() then dr.setY(segs(i).a.y())
		if segs(i).b.y() > dr.y() then dr.setY(segs(i).b.y())		
		curNode.segments[i] = segs(i)
	next i
	curNode.type_ = type_
	curNode.ID = seg_count
	curNode.bb_a = tl
	curNode.bb_b = dr
	curNode.edges.init(sizeof(PathTracker_Edge_t ptr))
	nodes.insert(curNode.ID, @curNode)
	spacialNodeIDs.insert(tl, dr, @curNode.ID)
    
    'sleep
    
end sub

sub PathTracker.record()
	enable = 1
end sub 
sub PathTracker.pause()
	enable = 0
end sub 

sub PathTracker.getGroundedData(body as TinyBody, body_i as integer, byref node as integer, byref p as Vector2D)
	dim as Vector2D pos_
	dim as Vector2D a, b
	dim as integer nodes_n
	dim as integer ptr ptr nodeList
	dim as double d_dist
	dim as integer d_index
	dim as integer i
	dim as Vector2D nodeP, gPos

	pos_ = body.p
	a = pos_ - (Vector2D(1,1) * body.r) - Vector2D(BOUNDINGBOX_SLOP, BOUNDINGBOX_SLOP)
	b = pos_ + (Vector2D(1,1) * body.r) + Vector2D(BOUNDINGBOX_SLOP, BOUNDINGBOX_SLOP)
	if link.tinyspace_ptr->isGrounded(body_i, 0) then
		onEdgeFrames += 1
		nodes_n = spacialNodeIDs.search(a, b, nodeList)
		if nodes_n <> 0 then
			d_dist = 1000
			d_index = *nodeList[0]
			for i = 0 to nodes_n - 1
				getNodeCoord(pos_, *nodeList[i], nodeP)
				if (pos_.x - body.r <= nodeP.x) andAlso _
				   (pos_.x + body.r >  nodeP.x) then
					if pos_.y < nodeP.y then
						if (nodeP.y - pos_.y) < d_dist then
							d_dist = (nodeP.y - pos_.y)
							d_index = *nodeList[i]
							gPos = nodeP
						end if
					end if
				end if
			next i
			p = gPos
			node = d_index
			exit sub
		end if
	end if

	node = 0
	p = Vector2D(0,0)
end sub

sub PathTracker.step_record(del_key as integer)
	dim as Vector2D a, b
	dim as Vector2D nodeP
	dim as Vector2D gPos
	dim as integer i
	dim as integer nodes_n
	dim as integer ptr ptr nodeList
	dim as double d_dist
	dim as integer d_index
	dim as integer mx, my, mb
	dim as PathTracker_Edge_t ptr ptr ptr edgeList
	dim as PathTracker_Edge_t ptr highEdge
	dim as PathTracker_Node_t ptr curNode
	dim as integer high_ID, highIndex
	dim as integer numEdges
	dim as integer highIndexS
	dim as Vector2D pos_
	
	nodeList = 0
	if enable then
		getmouse mx, my, ,mb
		
		numEdges = spacialEdgePTRs.search(Vector2D(mx - 2, my - 2) * 0.5 + link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5, _
		                                  Vector2D(mx + 2, my + 2) * 0.5 + link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5, edgeList)
		
		high_ID = 0
		for i = 0 to numEdges - 1
			if (*(edgeList[i]))->ID > high_ID then
				high_ID = (*(edgeList[i]))->ID
				highEdge = (*(edgeList[i]))
				highIndexS = i
			end if
		next i
		
		if high_ID <> 0 andALso mb <> 0 andAlso oldMB = 0 then
			interestID = high_ID
			highIndex = highIndexS
			targetData = edgeList[highIndex]
		elseif mb <> 0 andAlso oldMB = 0 then
			interestID = 0
			highIndex = -1
		end if
		
		if (del_key) andAlso (interestID <> 0) andAlso (highIndex <> -1) then
			spacialEdgePTRs.remove(targetData)
			curNode = nodes.retrieve((*targetData)->ID_start)
			interestStatic = interestID
			
			curNode->edges.removeIf(@removeInterestID)
			
			edges.remove(interestID)
			delete((*targetData))
			interestID = 0
			highIndex = -1
		end if
		
		
		if numEdges then deallocate(edgeList)
		
		link.player_ptr->exportMovementParameters(curFrame.dire, curFrame.jump, curFrame.ups, curFrame.shift)
		
		if onEdge = 1 then
			currentEdge->frames.push_back(@curFrame)	
		end if
		
		pos_ = link.player_ptr->body.p
		a = pos_ - (Vector2D(1,1) * link.player_ptr->body.r) - Vector2D(BOUNDINGBOX_SLOP, BOUNDINGBOX_SLOP)
		b = pos_ + (Vector2D(1,1) * link.player_ptr->body.r) + Vector2D(BOUNDINGBOX_SLOP, BOUNDINGBOX_SLOP)
		if link.tinyspace_ptr->isGrounded(link.player_ptr->body_i, 0) then
			onEdgeFrames += 1
			nodes_n = spacialNodeIDs.search(a, b, nodeList)
			if nodes_n <> 0 then
				d_dist = 1000
				d_index = *nodeList[0]
				for i = 0 to nodes_n - 1
					getNodeCoord(pos_, *nodeList[i], nodeP)
					if (pos_.x - link.player_ptr->body.r <= nodeP.x) andAlso _
					   (pos_.x + link.player_ptr->body.r >  nodeP.x) then
						if pos_.y < nodeP.y then
							if (nodeP.y - pos_.y) < d_dist then
								d_dist = (nodeP.y - pos_.y)
								d_index = *nodeList[i]
								gPos = nodeP
							end if
						end if
					end if
				next i
				curNodeP = gPos
				currentNode = d_index				
				if onEdge = 1 andAlso (onEdgeFrames > MIN_GROUNDED_FRAMES) then
					onEdge = 0
					endEdge()
				end if
				onNode = 1
			end if
		else
			onEdgeFrames = 0
			if (onNode = 1) andAlso (onEdge = 0) then
				onEdge = 1
				startEdge(PT_DROP)
			end if
			onNode = 0
			currentNode = -1
		end if
		
		if (onNode = 1) andAlso (curFrame.jump = 1) andAlso _
		   (lastJump <> curFrame.jump) andAlso (onEdge = 0) then
			onEdge = 1
			startEdge(PT_JUMP)
		end if
		
		lastJump = curFrame.jump
		if nodeList then deallocate(nodeList)
		prevInputs = curFrame
		prev_pos = link.player_ptr->body.p
		prev_vel = link.player_ptr->body.v
		prev_dir = link.player_ptr->facing
		
		oldMB = mb
	end if
end sub

sub PathTracker.startEdge(type_ as PathTracker_Path_Type_e)
	
	currentEdge = new PathTracker_Edge_t
	currentEdge->path_type = type_
		
	if abs(link.player_ptr->body.v.x()) = abs(link.player_ptr->top_speed) then
		currentEdge->speed_type = PT_SLOWSPEED
	elseif abs(link.player_ptr->body.v.x()) = abs(link.player_ptr->top_speed) * link.player_ptr->top_speed_mul then
		currentEdge->speed_type = PT_FULLSPEED
	elseif abs(link.player_ptr->body.v.x()) > abs(link.player_ptr->top_speed) then
		currentEdge->speed_type = PT_INTERMEDIATE
	else
		currentEdge->speed_type = PT_STOPPING
	end if
	currentEdge->frames.init(sizeof(PathTracker_Inputs_t))
	if type_ = PT_DROP then
		currentEdge->startPosition = prev_pos
		currentEdge->startVelocity = prev_vel
		currentEdge->startDirection = prev_dir
		currentEdge->frames.push_back(@prevInputs)
		
		getNodeDist(prev_pos, currentNode, currentEdge->start_dist)
		getNodeCoord(prev_pos, currentNode, currentEdge->start_loc)
	else
		currentEdge->startPosition = link.player_ptr->body.p
		currentEdge->startVelocity = link.player_ptr->body.v
		currentEdge->startDirection = link.player_ptr->facing
		getNodeDist(link.player_ptr->body.p, currentNode, currentEdge->start_dist)
		getNodeCoord(link.player_ptr->body.p, currentNode, currentEdge->start_loc)
	end if
	currentEdge->frames.push_back(@curFrame)	
	currentEdge->ID_start = currentNode


end sub

sub PathTracker.endEdge()
	dim as PathTracker_Node_t ptr curNode

	if currentEdge = 0 then exit sub

	if currentEdge->frames.getSize() > MIN_RECORD_FRAMES then
		
		edge_count += 1
		currentEdge->ID = edge_count
		currentEdge->ID_end = currentNode
		
		getNodeDist(link.player_ptr->body.p, currentNode, currentEdge->end_dist)
		getNodeCoord(link.player_ptr->body.p, currentNode, currentEdge->end_loc)
		
		if currentNode = currentEdge->ID_start then
			if abs(currentEdge->end_dist - currentEdge->start_dist) < MIN_EDGE_DIST then
				delete(currentEdge)
				currentEdge = 0
				exit sub
			end if
		end if
	
		currentEdge->bb_a.setX(iif(currentEdge->start_loc.x() < currentEdge->end_loc.x(), currentEdge->start_loc.x(), currentEdge->end_loc.x()))
		currentEdge->bb_a.setY(iif(currentEdge->start_loc.y() < currentEdge->end_loc.y(), currentEdge->start_loc.y(), currentEdge->end_loc.y()))
		currentEdge->bb_b.setX(iif(currentEdge->start_loc.x() > currentEdge->end_loc.x(), currentEdge->start_loc.x(), currentEdge->end_loc.x()))
		currentEdge->bb_b.setY(iif(currentEdge->start_loc.y() > currentEdge->end_loc.y(), currentEdge->start_loc.y(), currentEdge->end_loc.y()))
	
		spacialEdgePTRs.insert(currentEdge->bb_a, currentEdge->bb_b, @currentEdge)
		curNode = nodes.retrieve(currentEdge->ID_start)
		curNode->edges.push_back(@currentEdge)
		edges.insert(currentEdge->ID,@currentEdge)
	else
	
		delete(currentEdge)
		currentEdge = 0
		
	end if
end sub

sub PathTracker.getNodeCoord(p as Vector2D, node as integer, byref ret as Vector2D)
	dim as PathTracker_Node_t ptr curNode
	dim as Vector2D v
	dim as double d
	dim as integer i

	curNode = nodes.retrieve(node)
	
	if p.x < curNode->segments[0].a.x() then
		ret = curNode->segments[0].a
		exit sub
	elseif p.x >= curNode->segments[curNode->segments_n - 1].b.x() then
		ret = curNode->segments[curNode->segments_n - 1].b
		exit sub
	end if
	
	for i = 0 to curNode->segments_n - 1
		if (curNode->segments[i].a.x <= p.x) andAlso (curNode->segments[i].b.x() > p.x) then
			if curNode->segments[i].a.x = curNode->segments[i].b.x then
				ret = curNode->segments[i].a
				exit for
			else
				v = curNode->segments[i].b - curNode->segments[i].a
				d = p.x - curNode->segments[i].a.x()
				ret = curNode->segments[i].a + Vector2D(d, d * (v.y() / v.x()))
				exit for
			end if
		end if
	next i

end sub

sub PathTracker.getNodeDist(p as Vector2D, node as integer, byref ret as double)	
	dim as PathTracker_Node_t ptr curNode
	dim as Vector2D v
	dim as double d
	dim as integer i, q

	curNode = nodes.retrieve(node)
	ret = 0
	
	if p.x < curNode->segments[0].a.x() then
		ret = 0
		exit sub
	elseif p.x >= curNode->segments[curNode->segments_n - 1].b.x() then
		for i = 0 to curNode->segments_n - 1
			v = curNode->segments[i].b - curNode->segments[i].a
			ret += v.magnitude()
		next i
		exit sub
	end if
	
	for i = 0 to curNode->segments_n - 1
		if (curNode->segments[i].a.x <= p.x) andAlso (curNode->segments[i].b.x() > p.x) then
			if curNode->segments[i].a.x = curNode->segments[i].b.x then
				for q = 0 to i - 1
					v = curNode->segments[q].b - curNode->segments[q].a
					ret += v.magnitude()
				next q		
				exit for
			else
				for q = 0 to i - 1
					v = curNode->segments[q].b - curNode->segments[q].a
					ret += v.magnitude()
				next q
				v = curNode->segments[i].b - curNode->segments[i].a
				d = p.x - curNode->segments[i].a.x()
				v = Vector2D(d, d * (v.y() / v.x()))
				ret += v.magnitude()
				exit for
			end if
		end if
	next i

end sub	



sub PathTracker.register(e_ as Enemy ptr)
	dim as PathTracker_Child_t c
	c.child = e_
	c.moveState = PT_FREE
	c.target.node = 0
	c.target.x = 0
	c.nodeTarget = 0
	c.headingEdge = 0
	c.state = PT_TRACKING
	c.edgeList.init(sizeof(integer))
	c.sprintFrames = 0
	c.reachedGoal = 0
	c.shouldSprint = 0
	c.runningStart = 0
	children.insert(cast(integer, e_), @c)
end sub

sub PathTracker.requestInputs(e_ as Enemy ptr, byref ret as PathTracker_Inputs_t)
	dim as PathTracker_Child_t ptr c
	dim as PathTracker_Node_t ptr curNode
	dim as PathTracker_Edge_t ptr ptr curEdge
	dim as integer randInt
	dim as integer curNodeID
	dim as double direX		
	dim as integer ptr tempInt 
	dim as integer tempPlayerNode
	dim as integer shouldTrack
	dim as Vector2D  playerPos
	dim as PathTracker_Inputs_t ptr curInputs
	dim as Vector2D curPos
	dim as integer correctSpeed
	dim as double runDir
	dim as double farEdge
	dim as integer shouldSprint
	dim as double speedStandoff
	
	c = children.retrieve(cast(integer, e_))
	if c = 0 then exit sub
	
	ret.dire = 0
	ret.jump = 0
	ret.ups = 0
	ret.shift = 0
	
	shouldTrack = 0
	
	getGroundedData(e_->body, e_->body_i, curNodeID, curPos)	
	getGroundedData(link.player_ptr->body, link.player_ptr->body_i, tempPlayerNode, playerPos)
	if tempPlayerNode <> 0 then 
		playerNode = tempPlayerNode
		bodyP = link.player_ptr->body.p
	end if
	
	if c->moveState <> PT_ON_EDGE then
		if curNodeID then
			c->moveState = PT_ON_NODE
		else
			c->moveState = PT_FREE
		end if
	end if
	
	select case c->state 
	case PT_IDLE
		shouldSprint = 0
	case PT_CATATONIC
		shouldSprint = 0
	case PT_TRACKING
		shouldSprint = 0
	end select
				
	select case c->state
	case PT_TRACKING
		if curNodeID <> playerNode orElse c->moveState = PT_ON_EDGE then
			if (c->target.node <> playerNode) orElse (c->startNode <> curNodeID) then
				if curNodeID andAlso playerNode then
					c->target.node = playerNode
					c->target.x = playerPos.x
					c->startNode = curNodeID
					c->edgeList.flush()
					c->headingEdge = 0
					c->reachedGoal = 0
					if c->moveState = PT_ON_EDGE then c->moveState = PT_ON_NODE
					computePath(curNodeID, curPos.x(), c->target.node, c->target.x, c->edgeList, 30)			
				end if
			end if
			if (c->edgeList.getSize() > 0) then shouldTrack = 1
		else			
			c->headingEdge = 0
			c->runningStart = 0
			c->edgeList.flush()
			c->target.node = 0
			shouldTrack = 0
			curNode = nodes.retrieve(playerNode)
			if playerNode <> 0 then
				if bodyP.x <= (curNode->bb_a.x() + PATH_RUN_PINCH) then
					direX = (curNode->bb_a.x() + PATH_RUN_PINCH) - e_->body.p.x
				elseif bodyP.x > (curNode->bb_b.x() - PATH_RUN_PINCH) then
					direX = (curNode->bb_b.x() - PATH_RUN_PINCH) - e_->body.p.x
				else
					direX = bodyP.x - e_->body.p.x
				end if
			else
				direX = 0
			end if
			if abs(direX) >= 8 then
				ret.dire = sgn(direX)
				c->reachedGoal = 1
			end if
			ret.shift = shouldSprint
		end if
	end select
	
	
	if shouldTrack then
		if c->moveState = PT_ON_NODE andAlso curNodeID <> 0 then
			
			
			if c->headingEdge = 0 andAlso c->edgeList.getSize() > 0 then
				tempInt = c->edgeList.getFront()
				curNode = nodes.retrieve(c->startNode)
				
				c->headingEdge = *cast(PathTracker_Edge_t ptr ptr, edges.retrieve(*tempInt))
				
			end if
			if c->edgeList.getSize() > 0 andAlso c->headingEdge then
				correctSpeed = 0

				if curNodeID then
					curNode = nodes.retrieve(curNodeID)
					select case c->headingEdge->speed_type
					case PT_SLOWSPEED
						speedStandoff = SPEED_STANDOFF_SLOW 
					case PT_FULLSPEED
						speedStandoff = SPEED_STANDOFF_FAST
					case PT_INTERMEDIATE
						speedStandoff = SPEED_STANDOFF_INTER
					end select
						
					runDir = -sgn(c->headingEdge->startVelocity.x)
					direX = c->headingEdge->start_loc.x - e_->body.p.x
					if runDir = 1 then
						farEdge = _min_(c->headingEdge->start_loc.x + speedStandoff, curNode->bb_b.x - PATH_RUN_PINCH)
					elseif runDir = -1 then
						farEdge = _max_(c->headingEdge->start_loc.x - speedStandoff, curNode->bb_a.x + PATH_RUN_PINCH)
					end if
					if c->headingEdge->speed_type <> PT_STOPPING then
						if sgn(direX) = -runDir then
						
							if (e_->body.p.x*runDir) < (farEdge*runDir) then
								if (c->runningStart = 0) then
									ret.dire = -sgn(direX)
									ret.shift = shouldSprint 
								else
									ret.dire = sgn(direX)
									select case c->headingEdge->speed_type
									case PT_SLOWSPEED
										ret.shift = 0 
									case PT_FULLSPEED
										ret.shift = 1 
									case PT_INTERMEDIATE
										if abs(e_->body.v.x) < abs(c->headingEdge->startVelocity.x) then
											ret.shift = 1
										else
											ret.shift = 0
										end if
									end select
									correctSpeed = 1
								end if
							else
								ret.dire = sgn(direX)
								ret.shift = shouldSprint
								c->runningStart = 1
							end if
						else
							if c->runningStart = 1 then correctSpeed = 1
							c->runningStart = 0
							'walk to other side of point
							ret.dire = sgn(direX)
							ret.shift = shouldSprint 'based on how much in a hurry we are
						end if
					else
						if abs(curPos.x - c->headingEdge->start_loc.x) < 20 then
							ret.shift = 0
							ret.dire = sgn(direX)
						else
							ret.shift = shouldSprint
							ret.dire = sgn(direX)
						end if
						correctSpeed = 1
					end if
				end if
					
				if (abs(curPos.x - c->headingEdge->start_loc.x) <= JESUS_TAKE_THE_WHEEL_DIST) andAlso (correctSpeed) then
					e_->body.p = c->headingEdge->startPosition
					e_->body.v = c->headingEdge->startVelocity
					e_->facing = c->headingEdge->startDirection
					requestLock(e_)
					c->headingEdge->frames.rollReset()
					c->listBuffer = c->headingEdge->frames.bufferRoll()
					c->moveState = PT_ON_EDGE
				end if	
			elseif curNodeID = playerNode then
				direX = c->target.x - e_->body.p.x
				ret.dire = sgn(direX)
				ret.shift = shouldSprint
			end if
		end if
		
		if c->moveState = PT_ON_EDGE then
			c->headingEdge->frames.setRoll(c->listBuffer)
			curInputs = c->headingEdge->frames.roll()
			if curInputs then
				c->listBuffer = c->headingEdge->frames.bufferRoll()
				ret = *curInputs
			else
				c->moveState = PT_ON_NODE
				c->startNode = c->headingEdge->ID_end
				c->headingEdge = 0
				c->runningStart = 0
				c->edgeList.pop_front()
			end if
		end if	
	end if
	
end sub


sub PathTracker.computePath(startNode as integer, startX as double,_
							endNode as integer, endX as double,_
							byref edgeList as List, rand as double = 30)
	dim as Hashtable distance
	dim as Hashtable prevID
	dim as Hashtable nodeX
	dim as PathTracker_Node_t ptr tnode
	dim as PathTracker_Edge_t ptr ptr tedge_
	dim as PathTracker_Edge_t ptr tedge
	
	dim as integer ptr tempInt
	dim as double ptr tempD
	dim as integer curN
	dim as integer endID
	dim as integer temp_i
	dim as double temp_d
	dim as double min_d
	dim as double min_x
	dim as integer min_i
	dim as Hashtable nodelist
	dim as double alt
	
	distance.init(sizeof(double))
	nodeX.init(sizeof(double))
	prevID.init(sizeof(integer))
	nodelist.init(sizeof(integer))
	
	temp_d = 0
	distance.insert(startNode, @temp_d)
	temp_d = startX
	nodeX.insert(startNode, @temp_d)
	
	BEGIN_HASH(tnode, nodes)
		if tnode->ID <> startNode then
			temp_d = 1000000
			distance.insert(tnode->ID, @temp_d)
			temp_d = -1
			nodeX.insert(tnode->ID, @temp_d)
		end if	
		temp_i = -1
		prevID.insert(tnode->ID, @temp_i)
		nodelist.insert(tnode->ID, @(tnode->ID))
	END_HASH()
	
	while(nodelist.getSize())
		min_d = 1000000
		BEGIN_HASH(tempInt, nodelist)
			curN = *tempInt
			tempD = distance.retrieve(curN)
			temp_d = *tempD
			if temp_d <= min_d then
				min_d = temp_d
				min_i = curN
				tempD = nodeX.retrieve(curN)
				min_x = *tempD
			end if
		END_HASH()
		if min_i = endNode then exit while
		nodelist.remove(min_i)
		tnode = nodes.retrieve(min_i)
		BEGIN_LIST(tedge_, tnode->edges)
			tedge = *tedge_
			if nodelist.exists(tedge->ID_end) then
				endID = tedge->ID_end
				alt = ((rnd ^ 2) * rand) * (1/FPS_TARGET)
				if endID = endNode then
					alt += min_d + _
					     (abs(min_x - tedge->start_loc.x()) * VEL_DIST_CONSTANT + _
					      tedge->frames.getSize() + _
					      abs(endX - tedge->end_loc.x()) * VEL_DIST_CONSTANT) * (1 / FPS_TARGET)	
				else
					alt += min_d + (abs(min_x - tedge->start_loc.x()) * VEL_DIST_CONSTANT + tedge->frames.getSize()) * (1 / FPS_TARGET)
				end if
				tempD = distance.retrieve(endID)
				if alt < *tempD then
					*tempD = alt
					tempInt = prevID.retrieve(endID)
					*tempInt = tedge->ID
					tempD = nodeX.retrieve(endID)
					*tempD = tedge->end_loc.x()
				end if
			end if
		END_LIST()
	wend	
	edgeList.flush()
	tempInt = prevID.retrieve(endNode)
	if *tempInt = -1 then exit sub
	do 		
		edgeList.push_front(tempInt)
		tedge_ = edges.retrieve(*tempInt)
		tedge = *tedge_
		tempInt = prevID.retrieve(tedge->ID_start)
	loop until tedge->ID_start = startNode
end sub


sub PathTracker.requestLock(e_ as Enemy ptr)
	'e_->body.p = 
	'''
	link.tinyspace_ptr->setLock(e_->body_i)
	link.tinyspace_ptr->step_time(0)
	link.tinyspace_ptr->setUnlock()
end sub

sub PathTracker.exportGraph(byref data_ as byte ptr, byref data_bytes as integer)
	#macro WRITE_ELEMENT(e, s)
		memcpy(@(data_[curOffset]), @(e), sizeof(s))
		curOffset += sizeof(s)
	#endmacro
	
	
	dim as PathTracker_Node_t ptr curNode
	dim as PathTracker_Edge_t ptr ptr curEdge
	dim as PathTracker_Inputs_t ptr curInput
	dim as integer curOffset
	dim as integer tempInt
	dim as integer i
	
	curOffset = 0
	
	data_bytes = 0
	data_bytes += sizeof(integer) 'data size
	data_bytes += sizeof(integer) 'seg_count
	data_bytes += sizeof(integer) 'edge_count
	data_bytes += sizeof(integer) 'number of nodes	
	data_bytes += (sizeof(PathTracker_Node_t) - sizeof(List) - sizeof(PathTracker_Segment_t ptr)) * nodes.getSize()
	
	nodes.resetRoll()
	do
		curNode = nodes.roll()
		if curNode then
			data_bytes += curNode->segments_n * sizeof(PathTracker_Segment_t)
		else
			exit do
		end if
	loop
	
	
	data_bytes += sizeof(integer) 'number of edges
	data_bytes += (sizeof(PathTracker_Edge_t) - sizeof(List) + sizeof(integer)) * edges.getSize()
	edges.resetRoll()
	
	
	do
		curEdge = edges.roll()
		if curEdge then
			data_bytes += (*curEdge)->frames.getSize() * sizeof(PathTracker_Inputs_t)
		else
			exit do
		end if
	loop
	
	
	data_ = allocate(sizeof(byte) * data_bytes)
	
	WRITE_ELEMENT(data_bytes, integer)
	WRITE_ELEMENT(seg_count, integer)
	WRITE_ELEMENT(edge_count, integer)
	tempInt = nodes.getSize()
	WRITE_ELEMENT(tempInt, integer)
	nodes.resetRoll()
	do
		curNode = nodes.roll()
		if curNode then
			WRITE_ELEMENT(curNode->segments_n, integer)
			for i = 0 to curNode->segments_n - 1
				WRITE_ELEMENT(curNode->segments[i], PathTracker_Segment_t)
			next i
			WRITE_ELEMENT(curNode->type_, PathTracker_Node_Type_e)
			WRITE_ELEMENT(curNode->ID, integer)
			WRITE_ELEMENT(curNode->bb_a, Vector2D)
			WRITE_ELEMENT(curNode->bb_b, Vector2D)
		else
			exit do
		end if
	loop
	
	tempInt = edges.getSize()
	WRITE_ELEMENT(tempInt, integer)
	edges.resetRoll()
	do
		curEdge = edges.roll()
		if curEdge then
			tempInt = (*curEdge)->frames.getSize()
			WRITE_ELEMENT(tempInt, integer)
			
			(*curEdge)->frames.rollReset()
			do
				curInput = (*curEdge)->frames.roll()	
				if curInput <> 0 then
					WRITE_ELEMENT(*curInput, PathTracker_Inputs_t)
				else
					exit do
				end if
			loop
			WRITE_ELEMENT((*curEdge)->path_type, PathTracker_Path_Type_e)
			WRITE_ELEMENT((*curEdge)->speed_type, PathTracker_Path_Speed_e)
			WRITE_ELEMENT((*curEdge)->startPosition, Vector2D)
			WRITE_ELEMENT((*curEdge)->startVelocity, Vector2D)
			WRITE_ELEMENT((*curEdge)->startDirection, integer)
			WRITE_ELEMENT((*curEdge)->start_loc, Vector2D)
			WRITE_ELEMENT((*curEdge)->end_loc, Vector2D)
			WRITE_ELEMENT((*curEdge)->start_dist, double)
			WRITE_ELEMENT((*curEdge)->end_dist, double)			
			WRITE_ELEMENT((*curEdge)->ID_start, integer)
			WRITE_ELEMENT((*curEdge)->ID_end, integer)	
			WRITE_ELEMENT((*curEdge)->ID, integer)	
			WRITE_ELEMENT((*curEdge)->bb_a, Vector2D)
			WRITE_ELEMENT((*curEdge)->bb_b, Vector2D)	
		else
			exit do
		end if
	loop
end sub


sub PathTracker.importGraph(byref data_ as byte ptr, byref data_bytes as integer)
	#macro READ_ELEMENT(e, s)
		memcpy(@(e), @(data_[curOffset]), sizeof(s))
		curOffset += sizeof(s)
	#endmacro
	dim as integer curOffset
	dim as integer tempInt
	dim as integer i, q, k, numElements, numItems
	dim as PathTracker_Node_t curNode
	dim as PathTracker_Node_t ptr curNode_ptr
	dim as PathTracker_Edge_t ptr curEdge
	dim as PathTracker_Inputs_t curInput
	
	curOffset = 0
	flush()
	
	READ_ELEMENT(tempInt, integer) 'bogus
	READ_ELEMENT(seg_count, integer)
	READ_ELEMENT(edge_count, integer)
	READ_ELEMENT(numElements, integer)
	for i = 0 to numElements - 1
		READ_ELEMENT(curNode.segments_n, integer)
		curNode.segments = new PathTracker_Segment_t[curNode.segments_n]
		for q = 0 to curNode.segments_n - 1
			READ_ELEMENT(curNode.segments[q], PathTracker_Segment_t)
		next q
		READ_ELEMENT(curNode.type_, PathTracker_Node_Type_e)
		READ_ELEMENT(curNode.ID, integer)
		READ_ELEMENT(curNode.bb_a, Vector2D)
		READ_ELEMENT(curNode.bb_b, Vector2D)
		curNode.edges.init(sizeof(PathTracker_Edge_t ptr))
		nodes.insert(curNode.ID, @curNode)
		spacialNodeIDs.insert(curNode.bb_a, curNode.bb_b, @curNode.ID)
	next i
	
	READ_ELEMENT(numElements, integer)
	for i = 0 to numElements - 1
		curEdge = new PathTracker_Edge_t
		curEdge->frames.init(sizeof(PathTracker_Inputs_t))
		READ_ELEMENT(numItems, integer)
		for q = 0 to numItems - 1
			READ_ELEMENT(curInput, PathTracker_Inputs_t)
			curEdge->frames.push_back(@curInput)
		next q
		READ_ELEMENT(curEdge->path_type, PathTracker_Path_Type_e)
		READ_ELEMENT(curEdge->speed_type, PathTracker_Path_Speed_e)
		READ_ELEMENT(curEdge->startPosition, Vector2D)
		READ_ELEMENT(curEdge->startVelocity, Vector2D)
		READ_ELEMENT(curEdge->startDirection, integer)
		READ_ELEMENT(curEdge->start_loc, Vector2D)
		READ_ELEMENT(curEdge->end_loc, Vector2D)
		READ_ELEMENT(curEdge->start_dist, double)
		READ_ELEMENT(curEdge->end_dist, double)			
		READ_ELEMENT(curEdge->ID_start, integer)
		READ_ELEMENT(curEdge->ID_end, integer)	
		READ_ELEMENT(curEdge->ID, integer)
		READ_ELEMENT(curEdge->bb_a, Vector2D)
		READ_ELEMENT(curEdge->bb_b, Vector2D)
		curNode_ptr = nodes.retrieve(curEdge->ID_start)
		curNode_ptr->edges.push_back(@curEdge)
		edges.insert(curEdge->ID, @curEdge) 
		spacialEdgePTRs.insert(curEdge->bb_a, curEdge->bb_b, @curEdge)
	next i
	
end sub

sub PathTracker.record_draw(scnbuff as integer ptr)
	dim as PathTracker_Edge_t ptr ptr curEdge
	dim as integer col, bcol
	if enable then
		edges.resetRoll()
		do
			curEdge = edges.roll()
			if curEdge then
				col = rgb(3342*(*curEdge)->ID_start, 1928*(*curEdge)->ID_start, 8392*(*curEdge)->ID_start)
				line scnbuff, ((*curEdge)->start_loc.x(), (*curEdge)->start_loc.y())-_
				  ((*curEdge)->end_loc.x(), (*curEdge)->end_loc.y()), col
							   
				if (*curEdge)->ID = interestID then
					if int(timer * 10) and 1 then
						bcol = not col
					else
						bcol = col
					end if
					line scnbuff, ((*curEdge)->start_loc.x(), (*curEdge)->start_loc.y())-_
								  ((*curEdge)->end_loc.x(), (*curEdge)->end_loc.y()), _
								   bcol, B
					line scnbuff, ((*curEdge)->start_loc.x() + 1, (*curEdge)->start_loc.y() + 1)-_
								  ((*curEdge)->end_loc.x() - 1, (*curEdge)->end_loc.y() - 1), _
								   bcol, B			   
								   
					draw string scnbuff, ((*curEdge)->bb_a.x(), (*curEdge)->bb_a.y() - 16), "Frames: " & str((*curEdge)->frames.getSize()), col
				end if
			else
				exit do
			end if
		loop
	end if
end sub
