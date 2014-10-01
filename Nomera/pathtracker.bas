#include "pathtracker.bi"
#include "utility.bi"
#include "level.bi"
#include "tinyspace.bi"
#include "player.bi"
#include "crt.bi"
#include "gamespace.bi"
#include "constants.bi"

#define BOUNDINGBOX_SLOP 8

'find out why splitting one node into halves
'cant select segs from jumps, check why this is, either data is wrong
'   or insertion into list is wrong


'need to handle jumps that happen mid-air due to jump timer, also need to ignore landings that last for
'   less than X frames (bounce off of edge)
 
static as integer PathTracker.seg_count = 0
static as integer PathTracker.edge_count = 0

constructor PathTracker()
	nodes.init(sizeof(PathTracker_Node_t))
	edges.init(sizeof(PathTracker_Edge_t ptr))
	children.init(sizeof(PathTracker_Child_t))
	oldMB = 0
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
	
	spacialEdgePTRs.flush()
	spacialNodeIDs.flush()
end sub

sub PathTracker.init(link_p as ObjectLink)
	link = link_p
	spacialNodeIDs.init(link.level_ptr->getWidth() * 16, link.level_ptr->getHeight() * 16, sizeof(integer))
	spacialEdgePTRs.init(link.level_ptr->getWidth() * 16, link.level_ptr->getHeight() * 16, sizeof(PathTracker_Edge_t ptr))
	currentNode = -1
	enable = 0
	onNode = 0
	onEdge = 0
	lastJump = -1
	currentEdge = 0
	interestID = 0
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
	dim as integer mx, my, mb
	dim as PathTracker_Edge_t ptr ptr ptr edgeList
	dim as PathTracker_Edge_t ptr highEdge
	dim as integer high_ID
	dim as integer numEdges
	dim as Vector2D pos_
	
	nodeList = 0
	if enable then
		getmouse mx, my, ,mb
		
		numEdges = spacialEdgePTRs.search(Vector2D(mx - 2, my - 2) * 0.5 + link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5, _
		                                  Vector2D(mx + 2, my + 2) * 0.5 + link.gamespace_ptr->camera - Vector2D(SCRX, SCRY)*0.5, edgeList)
		if numEdges <> 0 then beep
		high_ID = 0
		for i = 0 to numEdges - 1
			if (*(edgeList[i]))->ID > high_ID then
				high_ID = (*(edgeList[i]))->ID
				highEdge = (*(edgeList[i]))
			end if
		next i
		
		if high_ID <> 0 andALso mb <> 0 andAlso oldMB = 0 then
			interestID = high_ID
		else
			interestID = 0
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
		
		oldMB = mb
	end if
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

	if currentEdge->frames.getSize() > 3  then
	
		edge_count += 1
		currentEdge->ID = edge_count
		currentEdge->ID_end = currentNode
		getNodeDist(link.player_ptr->body.p, currentNode, currentEdge->end_dist)
		getNodeCoord(link.player_ptr->body.p, currentNode, currentEdge->end_loc)
		spacialEdgePTRs.insert(currentEdge->start_loc, currentEdge->end_loc, @currentEdge)

		if (currentEdge->ID_start = 0) orElse (currentEdge->ID_start > seg_count) orElse _
			(currentEdge->end_loc = Vector2D(0,0)) orElse (currentEdge->start_loc = Vector2D(0,0))	then
			print currentEdge->ID_start
			stall(3000)
		end if
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

sub PathTracker.register(e_ as Enemy ptr)
	dim as PathTracker_Child_t c
	c.child = e_
	c.moveState = PT_FREE
	c.isNavigating = 0
	c.target.node = 0
	c.target.x = 0
	children.insert(cast(integer, e_), @c)
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
	data_bytes += (sizeof(PathTracker_Edge_t) - sizeof(List)) * edges.getSize()
	edges.rollReset()
	
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
	edges.rollReset()
	do
		curEdge = edges.roll()
		if curEdge then
			tempInt = (*curEdge)->frames.getSize()
			WRITE_ELEMENT(tempInt, integer)
			
			(*curEdge)->frames.rollReset()
			do
				curInput = (*curEdge)->frames.roll()
				if curInput then
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
		curNode_ptr = nodes.retrieve(curEdge->ID_start)
		curNode_ptr->edges.push_back(@curEdge)
		edges.push_back(@curEdge) 
		spacialEdgePTRs.insert(curEdge->start_loc, curEdge->end_loc, @curEdge)
	next i
	
end sub

sub PathTracker.record_draw(scnbuff as integer ptr)
	dim as PathTracker_Edge_t ptr ptr curEdge
	edges.rollReset()
	do
		curEdge = edges.roll()
		if curEdge then
			if (*curEdge)->ID = interestID then
				line scnbuff, ((*curEdge)->start_loc.x(), (*curEdge)->start_loc.y())-_
							  ((*curEdge)->end_loc.x(), (*curEdge)->end_loc.y()), _
							   rgb(3342*(*curEdge)->ID_start, 1928*(*curEdge)->ID_start, 8392*(*curEdge)->ID_start), B
				line scnbuff, ((*curEdge)->start_loc.x() + 1, (*curEdge)->start_loc.y() + 1)-_
							  ((*curEdge)->end_loc.x() - 1, (*curEdge)->end_loc.y() - 1), _
							   rgb(3342*(*curEdge)->ID_start, 1928*(*curEdge)->ID_start, 8392*(*curEdge)->ID_start), B			   
			end if
			line scnbuff, ((*curEdge)->start_loc.x(), (*curEdge)->start_loc.y())-_
					      ((*curEdge)->end_loc.x(), (*curEdge)->end_loc.y()), _
					       rgb(3342*(*curEdge)->ID_start, 1928*(*curEdge)->ID_start, 8392*(*curEdge)->ID_start)
		else
			exit do
		end if
	loop
end sub
