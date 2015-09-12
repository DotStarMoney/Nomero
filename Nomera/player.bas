#include "player.bi"
#include "TinyBlock.bi"
#include "utility.bi"
#include "debug.bi"
#include "gamespace.bi"
#include "dynamiccontroller.bi"
#include "leveltypes.bi"
#include "level.bi"
#include "effects3d.bi"
#include "locktoscreen.bi"
#include "objectslotset.bi"

#define MIN_BOMB_TILE_POS -46
#define MIN_ITEM_BAR_POS -50
#define ITEM_BAR_LIFE 300
#define INTERACT_INTRO_TIME 60
#define INTERACT_FLASH_CYCLE_TIME 90

#define DControl link.dynamiccontroller_ptr 

constructor Player
	dim as integer i
    acc   = 3000
    air_acc = 400
    top_speed = 150
    air_top_speed = 160
    lastJump = 0
    isJumping = 0
    jumpBoostFrames = 0
    lastJumpMemoryFrames = 6
    lastJumpMemory = 0
    state = FREE_FALLING
    facing         = 1
    groundDot      = 0.2
    cutSpeed       = 0.5
    stopFriction   = 3
    drawArrow 	= 0
    boostFrames    = 13
    boostForce     = 800
    jumpImpulse    = 150
    top_speed_mul  = 1.5
    freeJumpFrames = 6
    lastGrounded   = 0
    lastUps = 0
    lastFire = 0
    lastTopSpeed = 200
    groundSwitchAnimFrames = 0
    pendingSwitch = 0
    health = 100
    chargeFlicker = 0
    charge = 0
    bombs = 0
    revealSilo = 0
    coverValue = 0.65
    itemBarLife = ITEM_BAR_LIFE
    itemBarPos = MIN_ITEM_BAR_POS
    money = 0
    displayMoney = 0
    intelCount = 0
    addedMoneyCounter = 0
    keyCount = 0
    
    
    isCrouching = 0
    interactHilightTL = Vector2D(0,0)
    interactHilightBR = Vector2D(0,0)
    interactCycle = 0
    interactIntroDelay = 0
    
    
    spinnerAngle = 0
    spinnerAngleTarget = 0
    spinnerAngleAcc = 0 
    spinnerAngleV = 0

    loadAnimations("mrspy.txt")
    bombListTiles.load("bomblist.png")
    
    hudDigits.load("digits.png")
    healthindi.load("hindicator.png")
	hudTrim.load("hudtrim.png")
    detectmeter.load("dmeter.png")
    huditembar.load("itembar.png")
    keyIcon.load("key.png")
    
    intelIcon.load("objects\media\collectables.txt")
    intelIcon.hardSwitch(9)
    intelIcon.play()
    
    spinnerItem = 0
    anim.play()
    explodeAllHoldFrames_time = 60
    deactivateHoldFrames_time = 60
    explodeAllHoldFrames = 0
    deactivateHoldFrames = 0
    for i = 0 to 9
		bombData(i).hasBomb = 0
		bombData(i).isSwitching = 0
		bombData(i).curState = TOO_CLOSE
        bombData(i).tilePosY = MIN_BOMB_TILE_POS
		bombData(i).deactivateGroupFlag = 0
	next i
    for i = 0 to 5
        spinnerCount(i) = 16
    next i
  
    #ifdef KICKSTARTER
    useSoldier = -1
    #endif

end constructor
sub Player.showItemBar() 
    itemBarLife = ITEM_BAR_LIFE
end sub
#ifdef KICKSTARTER
sub Player.initPathing
     
        dim as string filename = ""
        dim as recordFrame_t ptr recordData
        
        useSoldier = RED_SOLDIER
        
        select case useSoldier
        case RED_SOLDIER
            filename += "RED_SOLDIER"
        case YELLOW_SOLDIER
            filename += "YELLOW_SOLDIER"
        case KARTOFEL
            filename += "KARTOFEL"
        end select
        timeStamp = int(timer)
        filename = "pathing\" + lcase(link.level_ptr->getName()) +  "\" + filename + "_" + str(timeStamp) + ".path"
     
        recordFileNum = freefile        
        open filename for binary as recordFileNum 
        put #recordFileNum,,useSoldier
        put #recordFileNum,,timeStamp
        put #recordFileNum,,(link.level_ptr->getName() + chr(0))
       
end sub
#endif


destructor Player()
    #ifdef KICKSTARTER
        close #recordFileNum
    #endif

end destructor

function Player.getState() as PlayerState
    return state    
end function

sub Player.setParent(p as TinySpace ptr, l as Level ptr, g as ProjectileCollection ptr,_
                     gs as any ptr)
    parent = p
    level_parent = l
    proj_parent = g
    game_parent = gs
end sub

sub Player.setLink(link_ as objectLink)
	link = link_
end sub


sub Player.loadAnimations(filename as string)
    anim.load(filename)
    silhouette.load(left(filename, len(filename) - 4) & "_s.txt")
    hudspinner.load("hudspinner.txt")
    
end sub

sub Player.drawPlayer(scnbuff as uinteger ptr)
    dim as integer numLights
    dim as LightPair ptr ptr lights
 
    #ifndef NO_PLAYER
    if link.level_ptr->shouldLight() then
        numLights = link.level_ptr->getLightList(lights)
        if harmedFlashing > 0 then
            if chargeFlicker < 4 then anim.drawAnimationLit(scnbuff, body.p.x(), body.p.y(), lights, numLights, link.level_ptr->getObjectAmbientLevel(),,4*facing)
        else
            anim.drawAnimationLit(scnbuff, body.p.x(), body.p.y(), lights, numLights, link.level_ptr->getObjectAmbientLevel(),,4*facing,1)
        end if
    else
        if harmedFlashing > 0 then
            if chargeFlicker < 4 then anim.drawAnimation(scnbuff, body.p.x(), body.p.y(),,4*facing)
        else
            anim.drawAnimation(scnbuff, body.p.x(), body.p.y(),,4*facing)
        end if
    end if
    #ENDIF
    
end sub

sub Player.drawPlayerInto(destbuff as uinteger ptr, posx as integer, posy as integer, positionless as integer = 0)
    posx = 0
    posy = 0
    #IFNDEF NO_PLAYER
    if positionless = 0 then
        if harmedFlashing > 0 then
            if chargeFlicker < 4 then anim.drawAnimation(destbuff, body.p.x() - posx, body.p.y() - posy,,4*facing)
        else
            anim.drawAnimation(destbuff, body.p.x() - posx, body.p.y() - posy,,4*facing)
        end if
    else
        if harmedFlashing > 0 then
            if chargeFlicker < 4 then anim.drawAnimation(destbuff, posx - anim.getOffset().x(), posy - anim.getOffset().y(),,4*facing)
        else
            anim.drawAnimation(destbuff, posx - anim.getOffset().x(), posy - anim.getOffset().y(),,4*facing)
        end if    
    end if
    #endif
end sub

function Player.beingHarmed() as integer
	if harmedFlashing > 0 then 
		return 1
	else
		return 0
	end if
end function

sub Player.computeCoverage()
	dim as integer pposx, pposy
	dim as integer numblocks_
	dim as integer ptr comptex
	dim as integer i
	dim as integer ptr playerImg
	dim as integer xpos, ypos, w, h
    dim as Vector2D tl, br
    
	dim as Level_CoverageBlockInfo_t ptr blocks_
	
	pposx = body.p.x() + anim.getOffset().x
	pposy = body.p.y() + anim.getOffset().y	
    
    'only works because character is a multiple of 16
	comptex = imagecreate((int((anim.getWidth() - 1) shr 4) + 1) shl 4, (int((anim.getHeight() - 1) shr 4) + 1) shl 4, &h00000000)
	
	numblocks_ = link.level_ptr->getCoverageLayerblocks(pposx, pposy,_
													   pposx+anim.getWidth()-1,pposy+anim.getHeight()-1,_
													   blocks_)
                                                       
    tl = Vector2D(pposx, pposy) - link.gamespace_ptr->camera + Vector2D(SCRX, SCRY)*0.5
    br = tl + Vector2D(anim.getWidth() - 1, anim.getHeight() - 1)
    if br.x >= 0 andAlso br.y >= 0 andALso tl.x <= (SCRX - 1) andALso tl.y <= (SCRY - 1) then
        tl = Vector2D(_max_(0.0, tl.x), _max_(0.0, tl.y))
        br = Vector2D(_min_(SCRX - 1.0, br.x), _min_(SCRY - 1.0, br.y))
        bitblt_invertPset(comptex, 0, 0, link.level_ptr->getSmokeTexture(), tl.x, tl.y, br.x, br.y)
    end if
													   
	for i = 0 to numblocks_ - 1
        bitblt_trans_clip(comptex, blocks_[i].rpx - pposx, blocks_[i].rpy - pposy, blocks_[i].img, blocks_[i].x0, blocks_[i].y0, blocks_[i].x1, blocks_[i].y1)
	next i
    
    window screen (pposx, pposy)-(pposx + SCRX - 1, pposy + SCRY - 1)
    link.dynamiccontroller_ptr->setOverrideLightObjects()
    link.dynamiccontroller_ptr->drawDynamics(comptex, ACTIVE_COVER)
    link.dynamiccontroller_ptr->resetOverrideLightObjects()

	anim.getFrameImageData(playerImg, xpos, ypos, w, h)
	
	'only works because character is a multiple of 16
	covered = compareTrans(comptex, 0, 0, playerImg, xpos, ypos, w, h) / anim.getFramePixelCount()
	
	if blocks_ then deallocate(blocks_)
	imagedestroy comptex
end sub

function Player.onSpikes() as integer
	dim as integer x0,y0
    dim as integer x1,y1
    dim as integer xscan, yscan
    
    x0 = body.p.x() - anim.getWidth() * 0.5 - 8
    if state <> JUMPING then
		y0 = body.p.y() - anim.getHeight() * 0.5 - 16
		y1 = y0 + anim.getHeight() - 16
	else
		y0 = body.p.y() - anim.getHeight() * 0.5 + 8
		y1 = body.p.y() + anim.getHeight() * 0.5 - 20
	end if
    
    x1 = x0 + anim.getWidth()
    
    x0 += 8
    x1 -= 8
    
    x0 /= 16
    y0 /= 16
    x1 /= 16
    y1 /= 16
    if x0 < 0 then
        x0 = 0
    elseif x0 >= level_parent->getWidth() then
        x0 = level_parent->getWidth() - 1
    end if
    if x1 < 0 then
        x1 = 0
    elseif x1 >= level_parent->getWidth() then
        x1 = level_parent->getWidth() - 1
    end if 
    if y0 < 0 then
        y0 = 0
    elseif y0 >= level_parent->getHeight() then
        y0 = level_parent->getHeight() - 1
    end if
    if y1 < 0 then
        y1 = 0
    elseif y1 >= level_parent->getHeight() then
        y1 = level_parent->getHeight() - 1
    end if
    for yscan = y0 to y1
        for xscan = x0 to x1
            if level_parent->getCollisionBlock(xscan, yscan).cModel = 57 then
                return 1
            elseif level_parent->getCollisionBlock(xscan, yscan).cModel = 77 then
				return 2
            end if
        next xscan
    next yscan
    return 0
end function 
   
function Player.onLadder() as integer
    dim as integer x0,y0
    dim as integer x1,y1
    dim as integer xscan, yscan
    
    x0 = body.p.x() - anim.getWidth() * 0.5 - 16
    y0 = body.p.y() - anim.getHeight() * 0.5 - 16
    x1 = x0 + anim.getWidth() + 16
    y1 = y0 + anim.getHeight()
    x0 = (x0 + LADDER_GRAB_EDGE_LENGTH) / 16
    y0 = (y0 + LADDER_GRAB_EDGE_LENGTH) / 16
    x1 = (x1 - LADDER_GRAB_EDGE_LENGTH) / 16
    y1 = (y1 - LADDER_GRAB_EDGE_LENGTH) / 16
    if x0 < 0 then
        x0 = 0
    elseif x0 >= level_parent->getWidth() then
        x0 = level_parent->getWidth() - 1
    end if
    if x1 < 0 then
        x1 = 0
    elseif x1 >= level_parent->getWidth() then
        x1 = level_parent->getWidth() - 1
    end if 
    if y0 < 0 then
        y0 = 0
    elseif y0 >= level_parent->getHeight() then
        y0 = level_parent->getHeight() - 1
    end if
    if y1 < 0 then
        y1 = 0
    elseif y1 >= level_parent->getHeight() then
        y1 = level_parent->getHeight() - 1
    end if
    for yscan = y0 to y1
        for xscan = x0 to x1
            if level_parent->getCollisionBlock(xscan, yscan).cModel = 22 then
                return 1
            end if
        next xscan
    next yscan
    return 0
end function

sub Player.switch(ls as LevelSwitch_t)
	dim as GameSpace ptr gsp
	gsp = cast(GameSpace ptr, game_parent)
	gsp->switchRegions(ls)
	pendingSwitchData = ls
	pendingSwitch = 1
end sub

sub Player.explosionAlert(p as Vector2D)
	dim as Vector2D expM
	dim as double kickback
	dim as double mag
	
	expM = p - (body.p - Vector2D(0, 24))
	mag = expM.magnitude()
	if mag < 70 then
		kickback = (70 - mag) / 70
		body.v = body.v - ((expM / mag) * kickback) * 250
		health -= kickback * 100
		harmedFlashing = 24
		link.soundeffects_ptr->playSound(SND_HURT)
	end if
end sub

sub Player.getBounds(byref p as Vector2D, byref size as Vector2D)
	p = this.body.p + this.anim.getOffset()
	size = Vector2D(anim.getWidth(), anim.getHeight())
end sub

sub Player.harm(p as Vector2D, amount as integer, kickM as double = -1)
    dim as Vector2D expM
	dim as double kickback
	dim as double mag
    
    expM = p - (body.p - Vector2D(0, 24))
    mag = expM.magnitude()
	if mag < 70 andAlso kickM = -1 then
		kickback = (70 - mag) / 70
		body.v = body.v - ((expM / mag) * kickback) * 100
    elseif kickM <> -1 then
        expM = body.p - p
        expM.normalize()
		body.v = body.v + expM*kickM    
	end if
	health -= amount
	harmedFlashing = 24
end sub

sub Player.centerToMap(byref p as Vector2D)
	body.p = p - Vector2D(0, body.r)
end sub

sub Player.exportMovementParameters(byref dire_p as integer, byref jump_p as integer,_
						            byref ups_p as integer, byref shift_p as integer)
	dire_p = _dire_
	jump_p = _jump_
	ups_p = _ups_
	shift_p = _shift_
end sub

sub Player.processControls(dire as integer, jump as integer,_
                           ups as integer, fire as integer,_
                           shift as integer, numbers() as integer, _
                           explodeAll as integer, deactivateAll as integer,_
                           turnstyle as integer, activate as integer,_
                           t as double)
    dim as Vector2D gtan
    dim as double curSpeed, oSpeed
    dim as integer addSpd, ptype, spikes, animateTrigger 
    dim as integer deactivateGroup, canTrigger
    dim as integer i, isTriggering
    dim as Item ptr newItem
    dim as LevelSwitch_t ls
    dim as GameSpace ptr gsp
    dim as Vector2D d, bombPos, a_bound, b_bound
	gsp = cast(GameSpace ptr, game_parent)
	
	
	_dire_ = dire
	_jump_ = jump
	_ups_ = ups
	_shift_ = shift
    
    #ifdef KICKSTARTER
    dim as recordFrame_t frame

    if useSoldier <> -1 then
        frame.p = body.p
        frame.direLEFTRIGHT = dire
        frame.jumpZ = jump
        frame.fireX = fire
        frame.upsUPDOWN = ups
        frame.sprintSHIFT = shift
        frame.pressQ = deactivateAll
        frame.pressW = explodeAll
        if numbers(0) then
            frame.dire2AS = -1
        elseif numbers(1) then
            frame.dire2AS = 1
        else
            frame.dire2AS = 0
        end if
        if state = ON_LADDER then
            frame.onLadder = 1
        else
            frame.onLadder = 0
        end if
        if state = GROUNDED then
            frame.grounded = 1
        else
            frame.grounded = 0
        end if
        put #recordFileNum,,frame
    end if
    #endif
    
    
    
    isCrouching = 0
    canTrigger = 0
    animateTrigger = 0
    if dire = 0 andAlso jump = 0 andAlso parent->isGrounded(body_i, this.groundDot) then canTrigger = 1

    for i = 0 to 9
        if numbers(i) = 0 then bombData(i).cantPlace = 0
    next i
    if canTrigger = 0 then
        for i = 0 to 9
            if bombData(i).hasBomb then numbers(i) = 0  
            if numbers(i) then
                bombData(i).cantPlace = 1
            end if
        next i
        explodeAll = 0
        deactivateAll = 0
        isTriggering = 0
    else
        for i = 0 to 9
            if bombData(i).lastHasBomb = 0 andAlso bombData(i).hasBomb <> 0 then bombData(i).cantPlace = 1
            if bombData(i).cantPlace then 
                numbers(i) = 0
                animateTrigger = 0
            end if
            if numbers(i) <> 0 andAlso bombData(i).cantPlace = 0 then 
                isTriggering = 1 
                if bombData(i).hasBomb then animateTrigger = 1
            end if
        next i
        if explodeAll orElse deactivateAll then 
            isTriggering = 1      
            animateTrigger = 1
        end if
    end if
    if isTriggering = 1 then
        if anim.getAnimation() <> 6 orElse anim.getFrame <> 3 then
            for i = 0 to 9
                if bombData(i).hasBomb then numbers(i) = 0  
            next i
            explodeAll = 0
            deactivateAll = 0    
        end if
    end if
    for i = 0 to 9
        bombData(i).lastHasBomb = bombData(i).hasBomb
    next i
    
    if state <> ON_LADDER andAlso ups <> 0 andAlso (onLadder() = 1) _
       andAlso lastUps = 0 then
        state = ON_LADDER
        jumpHoldFrames = 0
        anim.setSpeed(1)
        anim.hardSwitch(3)
        this.body.friction = this.stopFriction
        this.body.v = Vector2D(0,0)
        isJumping = 0
    end if
    
    if jump = 1 andAlso lastJump = 0 then
		lastJumpMemory = lastJumpMemoryFrames
    else
        if jump = 0 then 
			isJumping = 0
		end if
    end if
    
    if state = ON_LADDER then
        groundedFrames = 0
        if onLadder() = 1 then
            if parent->isGrounded(body_i, this.groundDot) andAlso ups > -1 then
                state = GROUNDED
            else
                this.body.f = -this.body.m * parent->getGravity()
                this.body.v = Vector2D(0,0)
                if dire = 1 then
                    this.body.v = this.body.v + Vector2D(CLIMBING_SPEED,0) 
                elseif dire = -1 then
                    this.body.v = this.body.v - Vector2D(CLIMBING_SPEED,0) 
                end if
                if ups = -1 then
                    this.body.v = this.body.v - Vector2D(0, CLIMBING_SPEED) 
                elseif ups = 1 then
                    this.body.v = this.body.v + Vector2D(0, CLIMBING_SPEED) 
                end if
                if ups <> 0 orElse dire <> 0 then
                    anim.play()
                else
                    anim.pause()
                end if
            end if
        else
            state = FREE_FALLING
        end if
    elseif parent->isGrounded(body_i, this.groundDot) then
		
        gtan = parent->getGroundingNormal(body_i, Vector2D(0,-1), Vector2D(dire,0), this.groundDot)
        gtan = gtan.perp()   
        if jumpHoldFrames = 0 orElse (lastGrounded = 0) then state = GROUNDED
		if lastState <> GROUNDED andAlso lastVel.magnitude() > 350 andAlso landedSFXFrames = 0 then
			landedSFXFrames = 8
			link.soundeffects_ptr->playSound(SND_LAND)
		end if
		
        curSpeed = gtan * this.body.v
        oSpeed = curSpeed
        
        if dire = 1 andalso ups <> 1 then
			
            curSpeed = curSpeed + this.acc * t
            if this.body.v.y() < 0 then
                if jumpHoldFrames = 0 then anim.hardSwitch(1) 'running
            else
                anim.hardSwitch(1)
                jumpHoldFrames = 0
            end if
            if shift = 0 then
                if curSpeed > this.top_speed then curSpeed = this.top_speed
                anim.setSpeed(1)
            else
                if curSpeed > this.top_speed*top_speed_mul then curSpeed = this.top_speed*top_speed_mul
                anim.setSpeed(2)
            end if
            addSpd = 1
            facing = 1

            this.body.friction = 0
            
        elseif dire = -1 andalso ups <> 1 then
            facing = 0
            if this.body.v.y() < 0 then
                if jumpHoldFrames = 0 then anim.hardSwitch(1)
            else
                anim.hardSwitch(1)
                jumpHoldFrames = 0
            end if

            curSpeed = curSpeed - this.acc * t
            if shift = 0 then
                if curSpeed < -this.top_speed then curSpeed = -this.top_speed
                anim.setSpeed(1)
            else
                if curSpeed < -this.top_speed*top_speed_mul then curSpeed = -this.top_speed*top_speed_mul
                anim.setSpeed(2)
            end if
            addSpd = 1
            this.body.friction = 0
        else
			if this.body.v.y() < 0 then
                if jumpHoldFrames = 0 andAlso ups <> 1 andAlso isTriggering = 0 then anim.switch(0)
            else
                if ups <> 1 andAlso isTriggering = 0 then anim.switch(0)
                jumpHoldFrames = 0
            end if
            
			if ups = 1 andAlso isTriggering = 0 then
                anim.switch(5)
                isCrouching = 1
			end if
        
            curSpeed = curSpeed * this.cutSpeed
            addSpd = 0
            this.body.friction = this.stopFriction
           
        end if
        lastTopSpeed = _max_(abs(curSpeed), this.top_speed)
        groundedFrames += 1
        if groundedFrames = GROUND_FRAMES+1 then groundedFrames = GROUND_FRAMES
        if groundedFrames = GROUND_FRAMES then freeJump = freeJumpFrames
        groundSwitchAnimFrames = 3
        if jumpHoldFrames > 0 then jumpHoldFrames -= 1
        lastGrounded = 1
    else
        groundedFrames = 0

        if state <> JUMPING andAlso jumpHoldFrames = 0 then 
            if groundSwitchAnimFrames = 0 then 
                anim.hardSwitch(4)
            end if
            state = FREE_FALLING
        else
            jumpHoldFrames = 2
        end if
        curSpeed = this.body.v.x()
        oSpeed = curSpeed
        gtan = Vector2D(1, 0)
        this.body.friction = 0
        
        if dire = 1 then
            curSpeed = curSpeed + this.air_acc * t
          
            if curSpeed > this.lastTopSpeed then curSpeed = this.lastTopSpeed
            
            addSpd = 1
            dire = 1
            if state = FREE_FALLING then facing = 1
        elseif dire = -1 then
            curSpeed = curSpeed - this.air_acc * t
            
            if curSpeed < -this.lastTopSpeed then curSpeed = -this.lastTopSpeed 
           
            addSpd = 1
            dire = -1
            if state = FREE_FALLING then facing = 0
        else
            curSpeed = curSpeed * this.cutSpeed
            addSpd = 0
        end if
        if freeJump > 0 then freeJump -=1
        if groundSwitchAnimFrames > 0 then groundSwitchAnimFrames -= 1
        lastGrounded = 0
    end if   
    
    if isTriggering = 1 andAlso animateTrigger = 1 then 
        if anim.getAnimation() <> 6 then anim.switch(6)
    end if
    
    if lastJumpMemory > 0 then
		if freeJump > 0 andAlso isJumping = 0 then
			freeJump = 0
			lastJumpMemory = 0
			state = JUMPING
			link.soundeffects_ptr->playSound(SND_JUMP)
			isJumping = 1
			jumpBoostFrames = this.boostFrames
			anim.hardSwitch(2)
			this.body.v = Vector2D(this.body.v.x(),0) - Vector2D(0, this.jumpImpulse)
		end if
	end if
    
    if lastJumpMemory > 0 then lastJumpMemory -= 1

    lastJump = jump
    
    if isJumping = 1 then
        jumpBoostFrames -= 1
        if jumpBoostFrames = 0 then isJumping = 0
        
        this.body.f = Vector2D(0,-jumpBoostFrames*this.boostForce)
    else
        if state <> ON_LADDER then this.body.f = Vector2D(0,0)
    end if
    
    spikes = onSpikes()
	if spikes = 1 then 
		harm(Vector2D(-1000,-1000), 1)
		this.body.v *= 0.8
		curSpeed *= 0.2
		oSpeed *= 0.2
	elseif spikes = 2 then
		harm(Vector2D(-1000,-1000), 100)
	end if
	if lastSpikes = 0 andAlso spikes <> 0 then
		link.soundeffects_ptr->playSound(SND_HURT)
	end if
    
    if addSpd = 1 then 
        this.body.v = this.body.v + (curSpeed - oSpeed) * gtan
    end if
    
    if fire = 1 andAlso bombs > 0 then 
		if charge = 99 then
			link.soundeffects_ptr->playSound(SND_FULLCHARGE)
		end if
		charge += 3
		if charge >= 100 then charge = 100
	else
		charge -= 1
		if charge < 0 then charge = 0 
	end if
	
	if fire = 0 andAlso lastFire = 1 then
		if bombs > 0 then
			'proj_parent->create(this.body.p, this.body.v + Vector2D((facing * 2 - 1) * charge * 4, -200))
			link.soundeffects_ptr->playSound(SND_THROW)
			bombs -= 1
			charge = 0
		end if
	end if
	if fire = 1 andAlso lastFire = 0 then
        doInteract = 1
    else
        doInteract = 0 
    end if

	
	chargeFlicker = (chargeFlicker + 1) mod 8
	computeCoverage()
	if covered > coverValue then
		revealSilo += 16
		if revealSilo > 255 then revealSilo = 255
	else
		revealSilo -= 8
		if revealSilo < 0 then revealSilo = 0
	end if
        
	if pendingSwitch = 0 then
		ptype = level_parent->processPortalCoverage(this.body.p + this.anim.getOffset(), anim.getWidth(), anim.getHeight(), ls)
		
		if ls.shouldSwitch = 1 then
			if ls.facing <> D_IN then
				switch(ls)
			else
				if (ups = -1) andAlso (lastUps = 0) andAlso (state = GROUNDED) then				
					switch(ls)
					link.soundeffects_ptr->playSound(SND_DOOR)
				end if
			end if
		end if
	else
		level_parent->repositionFromPortal(pendingSwitchData, body)
		if ucase(pendingSwitchData.portalName) = "DEFAULT" then centerToMap(body.p)
		gsp->centerCamera(body.p)
		pendingSwitch = 0
	end if
		
	if deactivateAll then
		explodeAll = 0
		if deactivateHoldFrames < deactivateHoldFrames_time then
			deactivateHoldFrames += 1
		end if
		for i = 0 to 9
			if numbers(i) then 
				numbers(i) = 0
				bombData(i).deactivateGroupFlag = 1
			end if
		next i
	else
		if deactivateHoldFrames = deactivateHoldFrames_time then
			deactivateGroup = 0
			for i = 0 to 9
				if bombData(i).deactivateGroupFlag andAlso bombData(i).hasBomb then 
					deactivateGroup = 1
                    
					DControl->removeItem(bombData(i).ID)
                    
                    bombData(i).hasBomb = 0
					bombData(i).isSwitching = 1
					bombData(i).switchFrame = BOMB_TRANS_FRAMES
					bombData(i).nextState = TOO_CLOSE
				end if
			next i
			if deactivateGroup = 0 then
				for i = 0 to 9
					numbers(i) = 0
					if bombData(i).hasBomb then 
                        
                        DControl->removeItem(bombData(i).ID)
                        
						bombData(i).hasBomb = 0
						bombData(i).isSwitching = 1
						bombData(i).switchFrame = BOMB_TRANS_FRAMES
						bombData(i).nextState = TOO_CLOSE
					end if
				next i
			end if
			
			deactivateHoldFrames = 0
		elseif deactivateHoldFrames > 0 then
			deactivateHoldFrames -= 1
			
		end if
		for i = 0 to 9
			bombData(i).deactivateGroupFlag = 0
		next i
	end if
	
	if explodeAll then
		if explodeAllHoldFrames < explodeAllHoldFrames_time then
			explodeAllHoldFrames += 1
		end if
	else
		if explodeAllHoldFrames = explodeAllHoldFrames_time then
			for i = 0 to 9
				numbers(i) = 0
				if bombData(i).hasBomb then 
					numbers(i) = -1
				end if
			next i
			explodeAllHoldFrames = 0
		elseif explodeAllHoldFrames > 0 then
			explodeAllHoldFrames -= 1
		end if
	end if
	
    if landedSFXFrames > 0 then landedSFXFrames -= 1
    if harmedFlashing > 0 then harmedFlashing -= 1
    anim.step_animation()
       
    for i = 0 to 9
		if numbers(i) andAlso (bombData(i).lastNumbers = 0) andAlso (bombData(i).hasBomb = 0) andAlso spinnerCount(spinnerItem) > 0 then
			if parent->isGrounded(body_i, this.groundDot) andAlso (parent->getArbiterN(body_i) > 0) then 
                'spinnerCount(spinnerItem) -= 1
              
                select case spinnerItem
                case 0
                    link.soundeffects_ptr->playSound(SND_PLACE_APMINE)
                    bombData(i).ID = DControl->addItem(DControl->itemStringToType("ANTIPERSONNEL MINE"),ACTIVE_FRONT,body.p + Vector2D(0, 10))
                case 3
                    link.soundeffects_ptr->playSound(SND_PLACE_GASMINE)   
                    bombData(i).ID = DControl->addItem(DControl->itemStringToType("SMOKE MINE"),ACTIVE_FRONT,body.p + Vector2D(0, 10))                    
                case 4
                    link.soundeffects_ptr->playSound(SND_PLACE_ELECMINE)
                    bombData(i).ID = DControl->addItem(DControl->itemStringToType("electric mine"),ACTIVE_FRONT,body.p + Vector2D(0, 10))                    
                end select
                
                DControl->setParameter(i, bombData(i).ID, "colorIndex")
                
  
				bombData(i).hasBomb = 1
				bombPos = DControl->getPos(bombData(i).ID)
                
                bombData(i).bombType = spinnerItem
				d = bombPos - (body.p - Vector2D(0, 13))
				if d.magnitude() > (BOMB_TRANS_DIST + i*2) then
               
					DControl->getBounds(bombData(i).ID, a_bound, b_bound)
					if(boxbox(link.gamespace_ptr->camera - Vector2D(SCRX, SCRY) * 0.5 - Vector2D(1,1) * SCREEN_IND_BOUND, _
							  link.gamespace_ptr->camera + Vector2D(SCRX, SCRY) * 0.5 + Vector2D(1,1) * SCREEN_IND_BOUND, _
							  a_bound, b_bound)) then
						bombData(i).nextState = PLAYER_ARROW
					else			
						bombData(i).nextState = SCREEN_ARROW
					end if
				else
					bombData(i).nextState = TOO_CLOSE
				end if
				bombData(i).curState = TOO_CLOSE
				bombData(i).switchFrame = BOMB_TRANS_FRAMES
				bombData(i).isSwitching = 1
				bombData(i).animating = 1
			end if
		elseif numbers(i) andAlso bombData(i).hasBomb andAlso (bombData(i).lastNumbers = 0) then
            link.oneshoteffects_ptr->create(body.p + Vector2D(((facing*2)-1)*12, -9), LITTLE_PULSE,,2)
			link.soundeffects_ptr->playSound(SND_SIGNAL)

			DControl->fireSlot(bombData(i).ID, "EXPLODE")
            
			bombData(i).hasBomb = 0
			bombData(i).isSwitching = 1
			bombData(i).switchFrame = BOMB_TRANS_FRAMES
			bombData(i).nextState = TOO_CLOSE
        elseif bombData(i).hasBomb andAlso DControl->hasItem(bombData(i).ID) = 0 then
			bombData(i).hasBomb = 0
			bombData(i).isSwitching = 1
			bombData(i).switchFrame = BOMB_TRANS_FRAMES
			bombData(i).nextState = TOO_CLOSE            
		end if
		bombData(i).lastNumbers = numbers(i)  
    next i
    
    if turnstyle = -1 then
        spinnerAngleTarget += 1.0472
        spinnerItem -= 1
        link.soundeffects_ptr->playSound(SND_SPINNER)
    elseif turnstyle = 1 then
        spinnerAngleTarget -= 1.0472
        spinnerItem += 1
        link.soundeffects_ptr->playSound(SND_SPINNER)
    end if
  
    if spinnerItem >= 6 then 
        spinnerItem -= 6
    elseif spinnerItem < 0 then
        spinnerItem += 6
    end if
        
    spinnerAngleAcc += sqr(abs(spinnerAngleTarget - spinnerAngle)) * sgn(spinnerAngleTarget - spinnerAngle) * 0.028 - spinnerAngleV * 0.40
    spinnerAngleV += spinnerAngleAcc
    spinnerAngleV *= 0.4
    spinnerAngle += spinnerAngleAcc
    if (abs(spinnerAngleTarget - spinnerAngle) < 0.01) andAlso (abs(spinnerAngleAcc) < 0.01) then
        spinnerAngleAcc = 0
        spinnerAngleV = 0
        spinnerAngle = spinnerAngleTarget 
    end if
        
    
    if spinnerCount(spinnerItem) > 9999 then 
        spinnerCount(spinnerItem) = 9999
    elseif spinnerCount(spinnerItem) < 0 then
        spinnerCount(spinnerItem) = 0
    end if
    
    if activate then 
        if itemBarLife = 0 then 
            itemBarLife = ITEM_BAR_LIFE
        else
            itemBarLife = 0
        end if
    end if
    

    
        
    lastUps = ups
    lastFire = fire
    lastSpikes = onSpikes() 
    lastState = state
    lastVel = body.v
end sub

sub Player.addMoney(amount as integer)
    money += amount
    addedMoneyCounter = 120
    displayMoney += amount
end sub

function Player.getCovered() as double
    return covered
end function

sub Player.addIntel()
    intelCount += 1
end sub
sub Player.addKey()
    keyCount += 1
end sub
sub Player.useKey()
    keyCount -= 1
end sub
function Player.hasKey() as integer
    return keyCount
end function

sub Player.drawOverlay(scnbuff as uinteger ptr, offset as Vector2D = Vector2D(0,0))
	dim as Vector2D center, curPos
	dim as Vector2D bombPos, ntl, nbr
	dim as Vector2d scnPos, offsetV
	dim as Vector2D d, arrow, a_bound, b_bound
	dim as Vector2D as_bound, bs_bound
	dim as Vector2D p(0 to 2)
	dim as double ang, rd, posY
	dim as double shrink, colSin, totalWidth, curPosX, thisWidth
    dim as double tilePlaceX(0 to 9)
	dim as integer i, col, col2, q
    dim as integer digits(0 to 3), nd

	center = -link.gamespace_ptr->camera + Vector2D(SCRX, SCRY) * 0.5
	as_bound = link.gamespace_ptr->camera - Vector2D(SCRX, SCRY) * 0.5 
	bs_bound = link.gamespace_ptr->camera + Vector2D(SCRX, SCRY) * 0.5 
	

	silhouette.setGlow(&h00FFFFFF or ((revealSilo and &hff) shl 24))
	if revealSilo > 0 then silhouette.drawAnimationOverride(scnbuff, body.p.x(), body.p.y(), anim.getAnimation(), anim.getFrame(), link.gamespace_ptr->camera, 4*facing)	

    if interactShowHilight then
        if (int(interactCycle * 0.25) = 0) orElse (int(interactCycle * 0.25) = 2) then
            ntl = Vector2D(interactHilightTL.x - interactCycle*0.5 + 6, interactHilightTL.y - interactCycle*0.5 + 6)
            nbr = Vector2D(interactHilightBR.x + interactCycle*0.5 - 6, interactHilightBR.y + interactCycle*0.5 - 6)
            line scnbuff, (ntl.x, ntl.y)-(nbr.x, nbr.y), &hcf003f, B
            line scnbuff, (ntl.x + 1, ntl.y + 1)-(nbr.x - 1, nbr.y - 1), &h3f001f, B
            line scnbuff, ((ntl.x + nbr.x)*0.5, ntl.y)-((ntl.x + nbr.x)*0.5, ntl.y + 4), &hcf003f
            line scnbuff, ((ntl.x + nbr.x)*0.5, nbr.y)-((ntl.x + nbr.x)*0.5, nbr.y - 4), &hcf003f
            line scnbuff, (ntl.x, (ntl.y + nbr.y)*0.5)-(ntl.x + 4, (ntl.y + nbr.y)*0.5), &hcf003f
            line scnbuff, (nbr.x, (ntl.y + nbr.y)*0.5)-(nbr.x - 4, (ntl.y + nbr.y)*0.5), &hcf003f
        end if
    end if
    
    LOCK_TO_SCREEN()
    
    '216 -> 180
    hudTrim.putTRANS(scnbuff, SCRX*0.5 - 180, 425, 0, 0, 470, 49)
    drawHexPrism(scnbuff, 68, 452, spinnerAngle, 42, 40, hudspinner.getRawImage(), 48, 48, &b0000000000111111)
    
    
    /'
    totalWidth = 0
    for i = 0 to 9
        thisWidth = bombData(i).tilePosY + 32
        if thisWidth < 0 then thisWidth = 0
        tilePlaceX(i) = totalWidth - (32 - thisWidth)*0.5
        totalWidth += thisWidth
    next i
    '/
    
    for i = 0 to 9     
        tilePlaceX(i) = i * 33 + 224'-= totalWidth * 0.5
        posY = (SCRY - 32 - 14) - bombData(i).tilePosY
        if posY > -32 then
            bombListTiles.putTRANS(scnbuff, tilePlaceX(i), posY, i*32, 0, i*32+31, 31)
            bombListTiles.putTRANS(scnbuff, tilePlaceX(i), posY, bombData(i).bombType*32, 32, bombData(i).bombType*32+31, 63)
        end if
    next i
  
    
	
    
    
    curPos = Vector2D(194, 434)
    nd = intToBCD(spinnerCount(spinnerItem), @digits(0))
    for i = 0 to nd - 1
        hudDigits.putTRANS(scnbuff, curPos.x, curPos.y, 16 + digits(i)*8,0, 23 + digits(i)*8,15)
        curPos -= Vector2D(8, 0)
    next i
   
    
    curPos = Vector2D(194, 455)
    nd = intToBCD(money, @digits(0))
    for i = 0 to nd - 1
        hudDigits.putTRANS(scnbuff, curPos.x, curPos.y, 16 + digits(i)*8,16, 23 + digits(i)*8,31)
        curPos -= Vector2D(8, 0)
    next i
    
    drawDetectMeter(scnbuff, (sin(timer * 0.5) + 1) * 50)
    
    huditembar.putTRANS(scnbuff, 0, itemBarPos, 0, 0, 639, 49)
    intelIcon.drawAnimation(scnbuff, 619, itemBarPos + 13)
    huditembar.putTRANS(scnbuff, 610, itemBarPos + 29, intelCount*20, 50, intelCount*20 + 19, 69)    
    for i = 0 to keyCount - 1
        keyIcon.putTRANS(scnbuff, 22 + i * 18, 2 + itemBarPos, 0, 0, 16, 16)
    next i
    
    
    UNLOCK_TO_SCREEN()
    
    if addedMoneyCounter > 0 then
        nd = intToBCD(displayMoney, @digits(0))
        curPos = body.p - Vector2D(0,60) + Vector2D(4,0)*nd - Vector2D(2,0)
        for i = 0 to nd - 1
            hudDigits.putTRANS(scnbuff, curPos.x, curPos.y, 16 + digits(i)*8,16, 23 + digits(i)*8,31)
            curPos -= Vector2D(8, 0)
        next i
        hudDigits.putTRANS(scnbuff, curPos.x - 2, curPos.y - 2, 0,16,7,31)
        
    end if
    
    for i = 0 to 9 
		if bombData(i).animating then
			if bombData(i).hasBomb then
                bombPos = link.dynamiccontroller_ptr->getPos(bombData(i).ID)
			else
				bombPos = bombData(i).bombP
			end if
            
			d = bombPos - (body.p - Vector2D(0, 13))
			ang = d.angle()
			if bombData(i).nextState = PLAYER_ARROW orElse bombData(i).curState = PLAYER_ARROW andAlso (drawArrow = 1) then
				if bombData(i).isSwitching then
					if bombData(i).nextState = PLAYER_ARROW then
						shrink = 1.5 - bombData(i).switchFrame / BOMB_TRANS_FRAMES
					else
						shrink = (bombData(i).switchFrame / BOMB_TRANS_FRAMES) * 1.8
					end if
				else
					shrink = 1
				end if
				arrow = body.p - Vector2D(0, 13) + offset
				if shrink <> 0 then
					p(0) = arrow+Vector2D(cos(ang),sin(ang)) * (34 + (5 + i*2)*shrink)
					p(1) = arrow+Vector2D(cos(ang + (0.15 - (i*0.005)) * shrink),sin(ang + (0.15 - (i*0.005)) * shrink)) * (34 + (-4 + i*2)*shrink)
					p(2) = arrow+Vector2D(cos(ang - (0.15 + (i*0.005)) * shrink),sin(ang - (0.15 + (i*0.005)) * shrink)) * (34 + (-4 + i*2)*shrink)
					col = Item.getIndicatorColor(i)
					center = center - offset
					vTriangle scnbuff, p(0) + center, p(1) + center, p(2) + center, col
					center = center + offset
					subColor(col, &h484848)
					vline scnbuff, p(0), p(1), col
					vline scnbuff, p(1), p(2), col
					vline scnbuff, p(2), p(0), col
				end if
			end if
			if bombData(i).nextState = SCREEN_ARROW orElse bombData(i).curState = SCREEN_ARROW then
				if bombData(i).isSwitching then
					if bombData(i).nextState = PLAYER_ARROW then
						shrink = bombData(i).switchFrame / BOMB_TRANS_FRAMES
					else
						shrink = 1.5 - (bombData(i).switchFrame / BOMB_TRANS_FRAMES) '* 1.8
					end if
				else
					shrink = 1
				end if
				scnPos = bombPos
				a_bound = as_bound + Vector2D(1,1) * BOMB_SCREEN_IND_RAD 
				b_bound = bs_bound - Vector2D(1,1) * BOMB_SCREEN_IND_RAD 
				if scnPos.x < a_bound.x then 
					scnPos.setX(a_bound.x)
				elseif scnPos.x > b_bound.x then
					scnPos.setX(b_bound.x)
				end if
				if scnPos.y < a_bound.y then 
					scnPos.setY(a_bound.y)
				elseif scnPos.y > b_bound.y then
					scnPos.setY(b_bound.y)
				end if	
				
				bombData(i).offset = Vector2D(0,0)
				for q = 0 to i-1
					if bombData(q).animating andAlso bombData(q).nextState = SCREEN_ARROW orElse bombData(q).curState = SCREEN_ARROW then
						d = (bombData(q).indicatorP + bombData(q).offset) - (scnPos + bombData(i).offset)
						rd = d.magnitude
						if rd <= (BOMB_SCREEN_IND_RAD*1.5) then
							d = (link.gamespace_ptr->camera) - (scnPos + bombData(i).offset)
							d.normalize()
							bombData(i).offset += d * (BOMB_SCREEN_IND_RAD*1.5 - rd) * 0.5
						end if
					end if
				next q
				
				d = bombPos - (scnPos + bombData(i).offset)
				ang = d.angle()
				bombData(i).bombP = bombPos
				bombData(i).angle = ang
				bombData(i).indicatorP = scnPos
				bombData(i).shrink = shrink
			end if
		end if
	next i
	
	for i = 9 to 0 step -1
		if bombData(i).animating then
			if bombData(i).nextState = SCREEN_ARROW orElse bombData(i).curState = SCREEN_ARROW then
				shrink = bombData(i).shrink
				scnPos = bombData(i).indicatorP
				ang = bombData(i).angle
				offsetV = bombData(i).offset
				col = Item.getIndicatorColor(i)
				col2 = col
				colSin = 24*(sin(timer*8 + i * _PI_/10)+1)
				subColor(col2, RGB(colSin, colSin, colSin))
				subColor(col, &h484848)		
				circle scnbuff, (scnPos.x + offsetV.x, scnPos.y + offsetV.y), (BOMB_SCREEN_IND_RAD-12) * shrink, col2,,,,F
				circle scnbuff, (scnPos.x + offsetV.x, scnPos.y + offsetV.y), (BOMB_SCREEN_IND_RAD-12) * shrink, col
				p(0) = scnPos + Vector2D(cos(ang), sin(ang)) * (BOMB_SCREEN_IND_RAD) * shrink
				p(1) = scnPos + Vector2D(cos(ang + _PI_/2), sin(ang + _PI_/2)) * (BOMB_SCREEN_IND_RAD - 12) * shrink + offsetV
				p(2) = scnPos + Vector2D(cos(ang - _PI_/2), sin(ang - _PI_/2)) * (BOMB_SCREEN_IND_RAD - 12) * shrink + offsetV
				center = center - offset
				if shrink <> 0 then vTriangle scnbuff, p(0) + center, p(1) + center, p(2) + center, col2
				center = center + offset
				vline scnbuff, p(0), p(1), col
				vline scnbuff, p(0), p(2), col
				col = Item.getIndicatorColor(i)
				addColor(col, &h606060)
				if shrink = 1 then drawStringShadow scnbuff, scnPos.x - 3 + offsetV.x, scnPos.y - 4 + offsetV.y, iif(i < 9, str(i + 1), "0"), col
			end if
		end if
	next i
end sub 
sub Player.drawDetectMeter(scnbuff as integer ptr, lvl as integer)
    dim as integer nPieces, i, posx, posy
    static as integer pieces(0 to 20, 0 to 1) = _
                             {{3, 3}, {7, 3}, {11, 3}, {15, 3}, {19, 3}, {23, 3}, {27, 3}, _
                              {31, 3}, {35, 3}, {39, 4}, {42, 5}, {45, 8}, {47, 11}, {49, 15}, _
                              {49, 19}, {49, 23}, {49, 27}, {49, 31}, {49, 35}, {49, 39}, {49, 43}}
    if lvl > 100 then 
        lvl = 100
    elseif lvl < 0 then
        lvl = 0
    end if
    detectmeter.putTRANS(scnbuff, 564, 419, 0, 0, 53, 48)
    nPieces = (lvl / 100.0) * 20
    for i = 0 to nPieces
        posx = 564 + pieces(i, 0)
        posy = 419 + pieces(i ,1)
        detectmeter.putTRANS(scnbuff, posx, posy, 54+i*4, 0, 57+i*4, 3)
    next i
    
end sub


sub Player.processItems(t as double)
	dim as integer bombNumber, dIndex, canInteract
	dim as Vector2D bombPos
	dim as Vector2D d, a_bound, b_bound
    dim as ObjectSlotSet interactables
    dim as Shape2D ptr geom
    dim as string thisId
    
    if itemBarLife > 0 then
        itemBarPos += 4
        if itemBarPos > 0 then itemBarPos = 0
        itemBarLife -= 1
    else
        itemBarPos -= 4
        if itembarPos < MIN_ITEM_BAR_POS then itemBarPos = MIN_ITEM_BAR_POS
    end if
    intelIcon.step_animation()
    DControl->querySlots(interactables, "interact", @Circle2D(Vector2D(body.p.x, body.p.y - iif(isCrouching, 0, 26)), 8))
    dIndex = 0
    while dIndex < interactables.getMember_N()
        interactables.getID(thisID, dIndex)
        DControl->getValue(canInteract, thisID, "interact")
        if canInteract = 0 then
            if doInteract then 
                interactables.throwMember(dIndex)
                interactIntroDelay = 0
                interactShowHilight = 0
            end if
            interactables.getGeometry(geom, dIndex)
            geom->getBoundingBox(interactHilightTL, interactHilightBR)
            interactHilightTL -= Vector2D(2, 2)
            interactHilightBR += Vector2D(2, 2)
            interactIntroDelay += 1
            if interactIntroDelay > INTERACT_INTRO_TIME then 
                interactIntroDelay = INTERACT_INTRO_TIME
                interactShowHilight = 1
                interactCycle = (interactCycle + 1) Mod INTERACT_FLASH_CYCLE_TIME
            end if
            exit while
        end if
        dIndex += 1
    wend
    if dIndex = interactables.getMember_N() then
        interactIntroDelay = 0
        interactShowHilight = 0
        interactCycle = 0
    end if
    
   
	
	for bombNumber = 0 to 9
    
        if bombData(bombNumber).hasBomb then
            bombData(bombNumber).tilePosY += 6
            if bombData(bombNumber).tilePosY > 0 then bombData(bombNumber).tilePosY = 0 
        else
            bombData(bombNumber).tilePosY -= 6
            if bombData(bombNumber).tilePosY < MIN_BOMB_TILE_POS then bombData(bombNumber).tilePosY = MIN_BOMB_TILE_POS 
        end if
		if bombData(bombNumber).animating then
			
			
			if bombData(bombNumber).isSwitching then
				if bombData(bombNumber).switchFrame > 0 then
					bombData(bombNumber).switchFrame -= 1
				else
					bombData(bombNumber).isSwitching = 0
					bombData(bombNumber).curState = bombData(bombNumber).nextState
					if bombData(bombNumber).hasBomb = 0 then
						bombData(bombNumber).animating = 0
					end if
				end if
			elseif bombData(bombNumber).hasBomb then
				
                
				bombPos = link.dynamiccontroller_ptr->getPos(bombData(bombNumber).ID)
                
				d = bombPos - (body.p - Vector2D(0, 13))
				if d.magnitude() > (BOMB_TRANS_DIST + bombNumber*2) then
					link.dynamiccontroller_ptr->getBounds(bombData(bombNumber).ID, a_bound, b_bound)
					if (boxbox(link.gamespace_ptr->camera - Vector2D(SCRX, SCRY) * 0.5 - Vector2D(1,1) * SCREEN_IND_BOUND, _
							  link.gamespace_ptr->camera + Vector2D(SCRX, SCRY) * 0.5 + Vector2D(1,1) * SCREEN_IND_BOUND, _
							  a_bound, b_bound)) then
						if (bombData(bombNumber).curState <> PLAYER_ARROW) then
							bombData(bombNumber).nextState = PLAYER_ARROW
							bombData(bombNumber).isSwitching = 1
							bombData(bombNumber).switchFrame = BOMB_TRANS_FRAMES
						end if
					elseif (bombData(bombNumber).curState <> SCREEN_ARROW) then	
						bombData(bombNumber).nextState = SCREEN_ARROW
						bombData(bombNumber).isSwitching = 1
						bombData(bombNumber).switchFrame = BOMB_TRANS_FRAMES
					end if
				elseif (bombData(bombNumber).curState <> TOO_CLOSE) then	
					bombData(bombNumber).nextState = TOO_CLOSE
					bombData(bombNumber).isSwitching = 1
					bombData(bombNumber).switchFrame = BOMB_TRANS_FRAMES
				end if
			end if
			
		
	
		end if
	next bombNumber
	
    if addedMoneyCounter > 0 then
        addedMoneyCounter -= 1
    else
        displayMoney = 0
    end if
   
end sub
