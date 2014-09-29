#include "pathtracker.bi"
#include "utility.bi"
#include "level.bi"
#include "tinyspace.bi"
#include "player.bi"

#define BOUNDINGBOX_SLOP 8
 
static as integer PathTracker.seg_count = 0

constructor PathTracker()
	nodes.init(sizeof(PathTracker_Node_t))
	edges.init(sizeof(PathTracker_Edge_t))
end constructor

destructor PathTracker()
	flush() 
end destructor

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
	
	edges.rollReset()
	do
		curEdge = edges.roll()
		if curEdge then
			delete(*curEdge)
		else
			exit do
		end if
	loop	
	edges.flush()  
	
	spacialNodeIDs.flush()
end sub

sub PathTracker.init(link_p as ObjectLink)
	link = link_p
	spacialNodeIDs.init(link.level_ptr->getWidth() * 16, link.level_ptr->getHeight() * 16, sizeof(integer))
	currentNode = -1
	enable = 0
	onNode = 0
	onEdge = 0
	lastJump = -1
	currentEdge = 0
	buildNodes()
end sub

sub PathTracker.buildNodes()
	dim as Vector2D ptr segs
	dim as integer      segs_n
	dim as integer      i
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
				if a <> objectSegs(objectSegs_N - 1).b then
					dumpStaticShape(objectSegs())
					objectSegs_N = 1
					redim preserve as PathTracker_Segment_t objectSegs(objectSegs_N - 1)
					objectSegs(objectSegs_N - 1).a = a
					objectSegs(objectSegs_N - 1).b = b
				else
					objectSegs_N += 1
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
	dim as integer i, q
	dim as integer leftMostIndex
	dim as integer endSplit
	dim as integer lastSplit
	dim as integer doCont
	dim as integer old_safe
	dim as integer safe
	redim as PathTracker_Segment_t paramSegs(0)
	dim as Vector2d d
	
	if segs(0).a.x < segs(0).b.x then
		leftMostIndex = 0
		for i = 1 to ubound(segs)
			if segs(i).a.x < segs(leftMostIndex).a.x then
				leftMostIndex = i
			end if
		next i
		if leftMostIndex <> 0 then
			i = leftMostIndex
			q = 0
			do
				swap segs(q), segs(i)
				q += 1
				i = (i + 1) mod (ubound(segs)+1)
			loop until q = leftMostIndex
		end if
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
		for i = 1 to ubound(segs)
			if segs(i).a.x > segs(leftMostIndex).a.x then
				leftMostIndex = i
			end if
		next i
		if leftMostIndex <> 0 then
			i = leftMostIndex
			q = 0
			do
				swap segs(q), segs(i)
				q += 1
				i = (i + 1) mod (ubound(segs)+1)
			loop until q = leftMostIndex
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
sub PathTracker.record()
	enable = 1
end sub 
sub PathTracker.pause()
	enable = 0
end sub 

sub PathTracker.step_record()
	dim as Vector2D a, b
	dim as Vector2D nodeP
	dim as Vector2D gPos
	dim as integer i
	dim as integer nodes_n
	dim as integer ptr ptr nodeList
	dim as double d_dist
	dim as integer d_index
	dim as Vector2D pos_
	
	nodeList = 0
	if enable then
		link.player_ptr->exportMovementParameters(curFrame.dire, curFrame.jump, curFrame.ups, curFrame.shift)
		
		if onEdge = 1 then
			currentEdge->frames.push_back(@curFrame)	
		end if
		
		pos_ = link.player_ptr->body.p
		a = pos_ - (Vector2D(1,1) * link.player_ptr->body.r) - Vector2D(BOUNDINGBOX_SLOP, BOUNDINGBOX_SLOP)
		b = pos_ + (Vector2D(1,1) * link.player_ptr->body.r) + Vector2D(BOUNDINGBOX_SLOP, BOUNDINGBOX_SLOP)
		if link.tinyspace_ptr->isGrounded(link.player_ptr->body_i, 0) then
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
				if onEdge = 1 then
					onEdge = 0
					endEdge()
				end if
				onNode = 1
			end if
		else
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
	end if
	
	dim as PathTracker_Edge_t ptr ptr ed
	edges.rollReset()
	do
		ed = edges.roll()
		if ed then
			
			vline ((*ed)->start_loc), ((*ed)->end_loc), &h00ff00
		else
			exit do
		end if
	loop
	
end sub

sub PathTracker.startEdge(type_ as PathTracker_Path_Type_e)
	
	currentEdge = new PathTracker_Edge_t
	currentEdge->path_type = type_
		
	if abs(link.player_ptr->body.v.x()) = abs(link.player_ptr->top_speed) then
		currentEdge->speed_type = PT_FULLSPEED
	elseif abs(link.player_ptr->body.v.x()) = abs(link.player_ptr->top_speed) * link.player_ptr->top_speed_mul then
		currentEdge->speed_type = PT_SLOWSPEED
	else
		currentEdge->speed_type = PT_INTERMEDIATE
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

	if currentEdge->frames.getSize() > 3 then
	
		currentEdge->ID_end = currentNode
		getNodeDist(link.player_ptr->body.p, currentNode, currentEdge->end_dist)
		getNodeCoord(link.player_ptr->body.p, currentNode, currentEdge->end_loc)
		curNode = nodes.retrieve(currentEdge->ID_start)
		curNode->edges.push_back(@currentEdge)
		edges.push_back(@currentEdge)
		
	else
	
		delete(currentEdge)
		
	end if
end sub

sub PathTracker.getNodeCoord(p as Vector2D, node as integer, ret as Vector2D)
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

sub PathTracker.getNodeDist(p as Vector2D, node as integer, ret as double)	
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
					v = curNode->segments[i].b - curNode->segments[i].a
					ret += v.magnitude()
				next q		
				exit for
			else
				for q = 0 to i - 1
					v = curNode->segments[i].b - curNode->segments[i].a
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


sub PathTracker.addNode(segs() as PathTracker_Segment_t, type_ as integer)
	dim as PathTracker_Node_t curNode
	dim as integer i
	dim as Vector2D tl, dr
	
	seg_count += 1
	
	curNode.segments_n = ubound(segs) + 1
	curNode.segments = new PathTracker_Segment_t[curNode.segments_n]
	tl = segs(0).a
	dr = segs(0).b
	for i = 0 to ubound(segs)
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
end sub


