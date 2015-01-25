#include "animation.bi"
#include "utility.bi"
#include "debug.bi"
#include "fbpng.bi"
#include "gamespace.bi"

dim as HashTable Animation.animHash
dim as integer Animation.initAnimHash = 0

constructor Animation
    init()
end constructor

constructor Animation(filename as string)
    init()
    load(filename)
end constructor

destructor Animation
    
end destructor

sub Animation.init()
    if initAnimHash = 0 then Animation.animHash.init(sizeof(AnimationData_t ptr))    
    initAnimHash = 1
    data_ = 0
    glowValue = rgb(255, 255, 255)
    delayCounter = 0
    currentFrame = 0
    isPaused = 1
    completed = 0
    isReleasing = 0
    speed = 1
end sub


function Animation.done() as integer
    return completed
end function

sub Animation.setGlow(glow as integer)
	glowValue = glow
end sub

function Animation.getGlow() as integer
	return glowValue
end function


sub Animation.load(filename as string)
    dim as integer  f, readStep, i
    dim as string   lne, imageName, curText
    redim as string pieces(0)
    dim as integer charPos, curAnim, getRFrames
    
    if animHash.exists(filename) = 1 then
        data_ = *cast(AnimationData_t ptr ptr, animHash.retrieve(filename))
    else
        data_ = new AnimationData_t 'allocate(sizeof(AnimationData_t))
        with *data_
            .animName = allocate(len(filename) + 1)
            *(.animName) = filename
            f = freefile
            readStep = 0
            open filename for input as #f
            line input #f, lne
            while lne <> ""
                charPos = instr(lne, "#")
                if charPos > 0 then lne = left(lne, charPos - 1)
                while left(lne, 1) = " "
                    lne = right(lne, len(lne)-1)
                wend
                while right(lne, 1) = " "
                    lne = left(lne, len(lne)-1)
                wend
                if lne <> "" then
                    select case readStep
                    case 0
                        imageName = mid(lne, 2, len(lne)-2)
                        readStep += 1
                    case 1
                        split(lne,",",-1,pieces())
                        .imgName = allocate(len(imageName) + 1)
                        *(.imgName) = imageName
                        .w = val(pieces(0))
                        .h = val(pieces(1))
                        if right(imageName, 3) = "bmp" then
							.image = imagecreate(.w, .h)
							bload imageName, .image
						else
							.image = png_load(imageName)
						end if
                        readStep = 200
                    case 200
						curText = mid(lne, 2, len(lne)-2)
						if curText = "TRANS" then
							.drawMode = ANIM_TRANS
						elseif curText = "ALPHA" then
							.drawMode = ANIM_ALPHA						
						elseif curText = "GLOW" then
							.drawMode = ANIM_GLOW							
						end if
						readStep = 2
                    case 2
                        .animations_n = val(lne)
                        .animations = new Animation_t[.animations_n] 'allocate(sizeof(Animation_t) * .animations_n)
                        curAnim = -1
                        readStep = 100
                    case 100
                        .defaultAnim = val(lne)
                        readStep = 3
                    case 3
                        curAnim += 1
                        .animations[curAnim].rotatedGroupFrames.init(sizeof(RotatedGroup_t ptr))
                        .animations[curAnim].nonTransCountFrames.init(sizeof(NonTransCount_t ptr))
                        split(lne,",",-1,pieces())
                        for i = 0 to ubound(pieces)
                            pieces(i) = ucase(mid(pieces(i), 2, len(pieces(i))-2))
                        next i
                        if pieces(0) = "STILL" then
                            .animations[curAnim].anim_type = ANIM_STILL
                        elseif pieces(0) = "LOOP" then
                            .animations[curAnim].anim_type = ANIM_LOOP
                        elseif pieces(0) = "ONE SHOT" then
                            .animations[curAnim].anim_type = ANIM_ONE_SHOT
                        end if
                        if pieces(1) = "TO COMPLETION" then
                            .animations[curAnim].anim_release_type = ANIM_TO_COMPLETION
                        elseif pieces(1) = "INSTANT" then
                            .animations[curAnim].anim_release_type = ANIM_INSTANT
                        elseif pieces(1) = "FINISH FRAME" then
                            .animations[curAnim].anim_release_type = ANIM_FINISH_FRAME
                        elseif pieces(1) = "AFTER RELEASE POINT" then
                            .animations[curAnim].anim_release_type = ANIM_AFTER_RELEASE_POINT
                        elseif pieces(1) = "REVERSE" then
                            .animations[curAnim].anim_release_type = ANIM_REVERSE
                        elseif pieces(1) = "JUMP TO RELEASE THEN REVERSE" then
                            .animations[curAnim].anim_release_type = ANIM_JUMP_TO_RELEASE_THEN_REVERSE
                        end if
                        if pieces(2) = "YES" then
                            .animations[curAnim].usePerFrameDelay = 1
                        elseif pieces(2) = "NO" then
                            .animations[curAnim].usePerFrameDelay = 0
                        end if
                        readStep += 1
                    case 4
                        .animations[curAnim].frame_n = val(lne)
                        readStep += 1    
                    case 5
                        split(lne,",",-1,pieces())
                        .animations[curAnim].frame_width = val(pieces(0))
                        .animations[curAnim].frame_height = val(pieces(1))
                        readStep += 1
                    case 6
                        .animations[curAnim].frame_delay = val(lne)
                        readStep += 1  
                    case 7
                        split(lne,",",-1,pieces())
                        .animations[curAnim].frame_startCell = val(pieces(0))
                        .animations[curAnim].frame_endCell = val(pieces(1))
                        readStep += 1
                    case 8
                        .animations[curAnim].frame_loopPoint = val(lne)
                        readStep += 1  
                    case 9
                        split(lne,",",-1,pieces())
                        .animations[curAnim].frame_offset = Vector2D(val(pieces(0)),val(pieces(1)))
                        readStep += 1
                    case 10
                        .animations[curAnim].release_frames_n = val(lne)
                        if .animations[curAnim].release_frames_n > 0 then
                            .animations[curAnim].release_frames = allocate(sizeof(integer) * .animations[curAnim].release_frames_n)
                            readStep += 1  
                        else
                            .animations[curAnim].release_frames = 0
                            readStep += 2
                        end if
                        getRFrames = 0
                    case 11
                        .animations[curAnim].release_frames[getRFrames] = val(lne)
                        getRFrames += 1
                        if getRFrames >= .animations[curAnim].release_frames_n then readStep += 1
                    case 12
                        curText = ucase(mid(lne, 2, len(lne)-2))
                        if curText = "YES" then
                            .animations[curAnim].frame_hasData = 1 
                            .animations[curAnim].frame_data = allocate(sizeof(FrameData_t)*.animations[curAnim].frame_n)
                            readStep += 1
                        elseif curText = "NO" then
                            .animations[curAnim].frame_hasData = 0
                            .animations[curAnim].frame_data = 0
                            readStep = 3
                        end if
                        getRFrames = 0
                    case 13
                        split(lne,",",-1,pieces())
                        .animations[curAnim].frame_data[getRFrames].offset = Vector2D(val(pieces(0)),val(pieces(1)))
                        .animations[curAnim].frame_data[getRFrames].delay = val(pieces(2))
                        getRFrames += 1
                        if getRFrames >= .animations[curAnim].frame_n then readStep = 3
                    end select
                end if
                line input #f, lne
            wend 
            close #f
            .defaultAnim = 0
        end with
        animHash.insert(filename, @data_)
    end if
    currentAnim = data_->defaultAnim
    
    currentFrame = 0
    drawFrame = 0
    delayCounter = 0
    reachedEnd = 0
    isReleasing = 0
end sub
        
sub Animation.switch(next_anim as integer)
    if next_anim <> currentAnim andAlso next_anim <> pendingSwitch then
        pendingSwitch = next_anim
        if data_->animations[currentAnim].anim_release_type = ANIM_JUMP_TO_RELEASE_THEN_REVERSE then
            currentFrame = data_->animations[currentAnim].release_frames[0]
            if data_->animations[currentAnim].usePerFrameDelay = 1 then
                delayCounter = data_->animations[currentAnim].frame_data[currentFrame].delay
            else
                delayCounter = data_->animations[currentAnim].frame_delay
            end if
        elseif data_->animations[currentAnim].anim_release_type = ANIM_REVERSE then
            if data_->animations[currentAnim].usePerFrameDelay = 1 then
                delayCounter = data_->animations[currentAnim].frame_data[currentFrame].delay
            else
                delayCounter = data_->animations[currentAnim].frame_delay
            end if
        end if
        isReleasing = 1
    end if
end sub

function Animation.getFrame() as integer
    return drawFrame
end function

sub Animation.hardSwitch(next_anim as integer)
    if ((next_anim <> currentAnim) andAlso (next_anim <> pendingSwitch)) OrElse _
       ((next_anim = currentAnim) andAlso (isReleasing = 1)) then
        pendingSwitch = next_anim
        applySwitch
    end if
end sub

sub Animation.pause()
   isPaused = 1 
end sub
sub Animation.restart()
    currentFrame = 0
    delayCounter = 0 
    reachedEnd = 0
    completed = 0
end sub
sub Animation.play()
    isPaused = 0
end sub

sub Animation.step_animation()
    drawFrame = currentFrame
    if isPaused = 0 then
        select case data_->animations[currentAnim].anim_type
        case ANIM_STILL
            step_Still()
        case ANIM_ONE_SHOT
            step_OneShot()
        case ANIM_LOOP
            step_Loop()
        end select
    end if
end sub

sub Animation.advance()  
    dim as integer shouldAdvance
    delayCounter += speed
    shouldAdvance = 0
    with data_->animations[currentAnim]
        if .usePerFrameDelay = 1 then
            if delayCounter >= .frame_data[currentFrame].delay then
                shouldAdvance = 1
            end if
        else
            if delayCounter >= .frame_delay then
                shouldAdvance = 1
            end if
        end if
        
        if shouldAdvance = 1 then
            delayCounter = 0
            currentFrame += 1
        end if
    end with
end sub

sub Animation.step_OneShot()
    dim as integer lastFrame
    dim as integer i
    dim as integer shouldApplySwitch
    dim as integer shouldAdvance
    with data_->animations[currentAnim]
        if isReleasing = 0 then
            advance()
            if currentFrame >= .frame_n then 
                currentFrame = .frame_n - 1
                reachedEnd = 1
                completed = 1
            end if
        else
            select case .anim_release_type
            case ANIM_TO_COMPLETION
                advance()
                if currentFrame >= .frame_n orElse reachedEnd = 1 then 
                    applySwitch()                    
                end if
            case ANIM_INSTANT
                applySwitch()
            case ANIM_FINISH_FRAME
                lastFrame = currentFrame
                advance()
                if currentFrame <> lastFrame orElse reachedEnd = 1 then 
                    applySwitch()
                end if
            case ANIM_AFTER_RELEASE_POINT
                lastFrame = currentFrame
                shouldApplySwitch = 0
                advance()
                for i = 0 to .release_frames_n
                    if lastFrame = .release_frames[i] then
                        if lastFrame <> currentFrame then 
                            shouldApplySwitch = 1
                        end if
                        exit for
                    end if
                next i
                if reachedEnd = 1 orElse shouldApplySwitch then
                    applySwitch()
                end if
            case ANIM_REVERSE
                delayCounter -= 1
                shouldAdvance = 0
                if delayCounter = 0 then
                    shouldAdvance = 1
                    if .usePerFrameDelay = 1 then
                        delayCounter = .frame_data[currentFrame].delay 
                    else
                        delayCounter = .frame_delay
                    end if
                end if
                
                if shouldAdvance = 1 then
                    currentFrame -= 1
                    if currentFrame = -1 then
                        currentFrame = 0
                        applySwitch()
                    end if
                end if
            case ANIM_JUMP_TO_RELEASE_THEN_REVERSE
                delayCounter -= 1
                shouldAdvance = 0
                if delayCounter = 0 then
                    shouldAdvance = 1
                    if .usePerFrameDelay = 1 then
                        delayCounter = .frame_data[currentFrame].delay 
                    else
                        delayCounter = .frame_delay
                    end if
                end if
                
                if shouldAdvance = 1 then
                    currentFrame -= 1
                    if currentFrame = -1 then
                        currentFrame = 0
                        applySwitch()
                    end if
                end if
            end select
        end if
    end with
end sub

sub Animation.step_Loop()
    dim as integer lastFrame
    dim as integer i
    dim as integer shouldApplySwitch
    dim as integer shouldAdvance
    with data_->animations[currentAnim]
        if isReleasing = 0 then
            advance()
            if currentFrame >= .frame_n then 
                reachedEnd = 1 
                currentFrame = .frame_loopPoint
            else 
                reachedEnd = 0
            end if
        else
            select case .anim_release_type
            case ANIM_TO_COMPLETION
                advance()
                if currentFrame >= .frame_n orElse reachedEnd = 1 then 
                    applySwitch()                    
                end if
            case ANIM_INSTANT
                applySwitch()
            case ANIM_FINISH_FRAME
                lastFrame = currentFrame
                advance()
                if currentFrame <> lastFrame orElse reachedEnd = 1 then 
                    applySwitch()
                end if
            case ANIM_AFTER_RELEASE_POINT
                lastFrame = currentFrame
                shouldApplySwitch = 0
                advance()
                if currentFrame >= .frame_n then currentFrame = .frame_loopPoint
                for i = 0 to .release_frames_n
                    if lastFrame = .release_frames[i] then
                        if lastFrame <> currentFrame then 
                            shouldApplySwitch = 1
                        end if
                        exit for
                    end if
                next i
                if shouldApplySwitch then
                    applySwitch()
                end if
            case ANIM_REVERSE
                delayCounter -= speed
                shouldAdvance = 0
                if delayCounter <= 0 then
                    shouldAdvance = 1
                    if .usePerFrameDelay = 1 then
                        delayCounter = .frame_data[currentFrame].delay 
                    else
                        delayCounter = .frame_delay
                    end if
                end if
                
                if shouldAdvance = 1 then
                    currentFrame -= 1
                    if currentFrame = -1 then
                        currentFrame = 0
                        applySwitch()
                    end if
                end if
            case ANIM_JUMP_TO_RELEASE_THEN_REVERSE
                delayCounter -= speed
                shouldAdvance = 0
                if delayCounter <= 0 then
                    shouldAdvance = 1
                    if .usePerFrameDelay = 1 then
                        delayCounter = .frame_data[currentFrame].delay 
                    else
                        delayCounter = .frame_delay
                    end if
                end if
                
                if shouldAdvance = 1 then
                    currentFrame -= 1
                    if currentFrame = -1 then
                        currentFrame = 0
                        applySwitch()
                    end if
                end if
            end select
        end if
    end with

end sub

function Animation.getWidth() as integer
	if data_ <> 0 then
		return data_->animations[currentAnim].frame_width
	else
		return 0
	end if
end function

function Animation.getHeight() as integer 
    if data_ <> 0 then
		return data_->animations[currentAnim].frame_height
	else
		return 0
	end if
end function

function Animation.getOffset() as Vector2D
    dim as Vector2D off
    if data_ <> 0 then
		with data_->animations[currentAnim]
			off = .frame_offset
			if .frame_hasData = 1 then off += .frame_data[currentFrame].offset
			return off
		end with
	else
		return Vector2d(0,0)
	end if
end function

sub Animation.applySwitch()
    currentAnim = pendingSwitch
    isReleasing = 0 
    drawFrame = 0
    currentFrame = 0
    delayCounter = 0
    reachedEnd = 0
end sub

sub Animation.step_Still()
    if isReleasing = 1 then
        applySwitch()
    end if 
end sub

sub Animation.setSpeed(s as integer)
    speed = s
end sub

function Animation.getFramePixelCount(rotatedFlags as integer = 0) as integer
	dim as NonTransCount_t ptr tempGroup
	dim as integer i
	dim as integer drawW, drawH
    dim as integer ptr drawImg
    dim as Vector2D off
    dim as integer start_x, start_y
    dim as integer count
    
	with data_->animations[currentAnim]
		
		if .nonTransCountFrames.exists(drawFrame) then
			tempGroup = *cast(NonTransCount_t ptr ptr, .nonTransCountFrames.retrieve(drawFrame))	
		else
			tempGroup = new NonTransCount_t
			for i = 0 to 7
				tempGroup->countPerRotatedGroup(i) = 0
			next i
			.nonTransCountFrames.insert(drawFrame, @tempGroup)
		end if
		
		if tempGroup->countPerRotatedGroup(rotatedFlags) = 0 then
			fetchImageData currentAnim, drawFrame, rotatedFlags, drawImg, drawW, drawH, off, start_x, start_y
			tempGroup->countPerRotatedGroup(rotatedFlags) = countTrans(drawImg, start_x, start_y,_
																	   start_x + drawW - 1, start_y + drawH - 1)
		end if
		
		return tempGroup->countPerRotatedGroup(rotatedFlags)
	
	end with

end function

sub Animation.getFrameImageData(byref img as uinteger ptr, byref xpos as integer, byref ypos as integer, byref w as integer, byref h as integer)
	dim as Vector2D THISONEDOESDUMMY
	fetchImageData currentAnim, drawFrame, 0, img, w, h, THISONEDOESDUMMY, xpos, ypos
end sub
        
        
sub Animation.fetchImageData(animNum as integer, frameNum as integer, rotatedFlag as integer,_
				             byref imgdata as uinteger ptr, byref drawW as integer, byref drawH as integer, byref offset as Vector2D,_
				             byref start_x as integer, byref start_y as integer)
	dim as RotatedGroup_t ptr tempRotGroup
	dim as integer i
	dim as integer newW, newH

	with data_->animations[animNum]
	
        offset = .frame_offset
		start_x = ((.frame_startCell + frameNum) * .frame_width) mod data_->w
		start_y = (((.frame_startCell + frameNum) * .frame_width) \ data_->w) * .frame_height
		if .frame_hasData = 1 then
            offset += .frame_data[frameNum].offset
        end if
        drawW = .frame_width
		drawH = .frame_height
		
		
			   
		if (rotatedFlag = 0) orElse (rotatedFlag > 7) then
			imgdata = data_->image
		else
			if .rotatedGroupFrames.exists(frameNum) then
				tempRotGroup = *cast(RotatedGroup_t ptr ptr,.rotatedGroupFrames.retrieve(frameNum))
			else
				tempRotGroup = new RotatedGroup_t
				.rotatedGroupFrames.insert(frameNum, @tempRotGroup)
				tempRotGroup->rotatedGroup = new integer ptr[8]
				for i = 0 to 7
					tempRotGroup->rotatedGroup[i] = 0
				next i
			end if
			if tempRotGroup->rotatedGroup[rotatedFlag] = 0 then
				newW = drawW
				newH = drawH
				if (rotatedFlag and 1) then	swap newW, newH
				tempRotGroup->rotatedGroup[rotatedFlag] = imagecreate(newW, newH)
				copyImageRotate(data_->image, tempRotGroup->rotatedGroup[rotatedFlag], rotatedFlag, start_x, start_y, drawW, drawH, 0, 0) 
				drawW = newW
				drawH = newH
				imgdata = tempRotGroup->rotatedGroup[rotatedFlag]
			else
				imgdata = tempRotGroup->rotatedGroup[rotatedFlag]
				imageinfo imgdata, drawW, drawH
			end if

			start_x = 0
			start_y = 0
		end if
	end with	   
end sub

function Animation.getAnimation() as integer
	return currentAnim
end function

sub Animation.drawAnimationOverride(scnbuff as uinteger ptr, x as integer, y as integer,_
								    anim as integer, frame as integer,_
								    cam as Vector2D = Vector2D(0,0), drawFlags as integer = 0)					    
    Dim as Vector2D off
    dim as integer start_x, start_y
    dim as integer a_x, a_y
    dim as integer b_x, b_y
    dim as integer pos_x, pos_y
    dim as integer drawW, drawH
    dim as integer ptr drawImg
    with data_->animations[anim]
		
        fetchImageData anim, frame, drawFlags, drawImg, drawW, drawH, off, start_x, start_y
                
        select case data_->drawMode
        case ANIM_TRANS
		
			put scnbuff, (x + off.x, y + off.y), drawImg, (start_x, start_y)-(start_x + drawW - 1, start_y + drawH - 1), TRANS
			
		case ANIM_GLOW
			'put scnbuff, (0, 0), drawImg, ALPHA
			off = off - (cam - Vector2D(SCRX * 0.5, SCRY * 0.5))
			off.setX(off.x() + x)
			off.setY(off.y() + y)
			
	        if screenclip(off.x, off.y, drawW, drawH, pos_x, pos_y, a_x, a_y, b_x, b_y) then

				bitblt_alphaGlow(scnbuff, pos_x, pos_y, drawImg, start_x + a_x, start_y + a_y, start_x + b_x, start_y + b_y, glowValue)
			end if
			
		end select
		
    end with    								    
								    
end sub
        

sub Animation.drawAnimation(scnbuff as uinteger ptr, x as integer, y as integer, cam as Vector2D = Vector2D(0,0), drawFlags as integer = 0)
    Dim as Vector2D off
    dim as integer start_x, start_y
    dim as integer a_x, a_y
    dim as integer b_x, b_y
    dim as integer pos_x, pos_y
    dim as integer drawW, drawH
    dim as integer ptr drawImg
    with data_->animations[currentAnim]
		
        fetchImageData currentAnim, drawFrame, drawFlags, drawImg, drawW, drawH, off, start_x, start_y
        
        select case data_->drawMode
        case ANIM_TRANS
		
			put scnbuff, (x + off.x, y + off.y), drawImg, (start_x, start_y)-(start_x + drawW - 1, start_y + drawH - 1), TRANS
			
		case ANIM_GLOW
			off = off - (cam - Vector2D(SCRX * 0.5, SCRY * 0.5))
	        if screenclip(x + off.x, y + off.y, drawW, drawH, pos_x, pos_y, a_x, a_y, b_x, b_y) then
				bitblt_alphaGlow(scnbuff, pos_x, pos_y, drawImg, start_x + a_x, start_y + a_y, start_x + b_x, start_y + b_y, glowValue)
			end if
		end select
		
    end with    
end sub

