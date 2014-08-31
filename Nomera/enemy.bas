#include "enemy.bi"
#include "TinyBlock.bi"
#include "utility.bi"
#include "debug.bi"
#include "gamespace.bi"
#include "player.bi"

#define VIEW_DISTANCE  300
#define VIEW_CONE_DOT  0.85
#define TOO_CLOSE_DIST 100

constructor Enemy
    acc   = 500
    air_acc = 800
    top_speed = 100
    air_top_speed = 160
    lastJump = 0
    isJumping = 0
    jumpBoostFrames = 0
    state = E_FREE_FALLING
    thought = IDLE
    facing         = 1
    groundDot      = 0.2
    cutSpeed       = 0.5
    stopFriction   = 3
    boostFrames    = 16
    boostForce     = 800
    jumpImpulse    = 80
    freeJumpFrames = 3 
    lastUps = 0
    lastFire = 0
    lastTopSpeed = 200
    groundSwitchAnimFrames = 0
    pursuitFrames = 0
    burstTimer = 0
    burstShots = 0
    burstFrames = 1 
    health = 100
    
    searchDown = 0
    takeJump = 0
    alertingFrames = 0
    lazyness = 100
    manditoryWalk = 0
    dire_ = 0
    jump_ = 0
    ups_ = 0
    fire_ = 0
    shift_ = 0
    
    anim.play()
    alertAnim.load("alert.txt")
    alertAnim.play()
end constructor

function Enemy.getState() as EnemyPhysicalState
    return state    
end function

sub Enemy.setParent(p as TinySpace ptr, l as Level ptr, g as ProjectileCollection ptr,_
                    gs as any ptr, ply as Player ptr)
    parent = p
    level_parent = l
    proj_parent = g
    game_parent = gs
    player_parent = ply
end sub

sub Enemy.loadType(type_ as EnemyType)
	enemy_type = type_
	if type_ = SOLDIER_1 then
		anim.load("soldier.txt")
	elseif type_ = SOLDIER_2 then
	
	elseif type_ = BEAR then
	
	end if
	anim.play()
end sub

sub Enemy.setLink(link_ as objectLink)
	link = link_
end sub

sub Enemy.drawEnemy(scnbuff as uinteger ptr)
    anim.drawAnimation(scnbuff, body.p.x(), body.p.y())
    if thought <> IDLE then
		alertAnim.drawAnimation(scnbuff, body.p.x(), body.p.y() - 55)
    end if
end sub

function Enemy.process(t as double) as integer
	dim as Vector2D pt, pv, sv
	dim as Vector2D viewM
	dim as integer groundAhead, shouldPursue
	dim as integer clearJump, noalert, blocked
	dim as double dist, viewMag
	
	if parent->raycast(body.p + Vector2D(18, 0) * dire_, Vector2D(0, 30), pt) >= 0 then
		groundAhead = 1
	else
		groundAhead = 0
	end if
	
	if parent->raycast(body.p - Vector2D(0, -74), Vector2D(32,0)*dire_, pt) >= 0 then
		clearJump = 0
	else
		clearJump = 1
	end if
	
	if parent->raycast(body.p + Vector2D(0, 4), Vector2D(32,0)*dire_, pt) >= 0 then
		blocked = 1
	else
		blocked = 0
	end if
	
	select case thought
	case IDLE
		if groundAhead = 0 orElse blocked = 1 then
			dire_ = -dire_
			manditoryWalk = 10 + int(rnd * 20)
		end if
		if manditoryWalk = 0 then
			if int(rnd * lazyness) = 0 then
				if dire_ = 0 then
					manditoryWalk = 10 + int(rnd * 40)
					dire_ = int(rnd * 3) - 1
				else
					dire_ = 0
					manditoryWalk = 10 + int(rnd * 20)
				end if
			end if
		else
			manditoryWalk -= 1
		end if
		viewM = player_parent->body.p - body.p
		viewMag = viewM.magnitude()
		if viewMag > 500 then 
			viewM.normalize()
			viewM = viewM * 500
		end if
		if sgn(viewM.x()) = sgn(facing * 2 - 1) then
			dist = parent->raycast(body.p + Vector2D(0, -30), viewM, pt)
			if dist = -1 then
				if viewM.magnitude() < VIEW_DISTANCE then
					viewM.normalize()
					if viewM * Vector2D(facing*2 - 1,0) >= VIEW_CONE_DOT then
						thought = CONCERNED
						jump_ = 1
						alertingFrames = lazyness * 0.5
						dire_ = 0
						body.v.setX(0)
						alertAnim.hardSwitch(0)
					end if
				end if
			end if
		end if
		shift_ = 0
	case CONCERNED
		jump_ = 0
		shift_ = 0
		viewM = player_parent->body.p - body.p
		viewMag = viewM.magnitude()
		if viewMag > 500 then 
			viewM.normalize()
			viewM = viewM * 500
		end if
		noalert = 1
		if sgn(viewM.x()) = sgn(facing * 2 - 1) then
			dist = parent->raycast(body.p + Vector2D(0, -30), viewM, pt)
			if dist = -1 then
				if viewM.magnitude() < VIEW_DISTANCE * 1 then
					alertingFrames += 1
					noalert = 0
				end if
			end if
		end if
		if noalert = 1 then alertingFrames -= 1
		
		if alertingFrames <= 0 then 
			dire_ = int(rnd * 3) - 1
			manditoryWalk = int(rnd * 10)
			thought = IDLE
		elseif alertingFrames > lazyness * 1.5 then
			thought = PURSUIT
			link.soundeffects_ptr->playSound(SND_ALARM)
			alertAnim.hardSwitch(1)
		end if
		if (viewM.magnitude() < TOO_CLOSE_DIST) andAlso (dist = -1) then
			thought = PURSUIT
			link.soundeffects_ptr->playSound(SND_ALARM)
			alertAnim.hardSwitch(1)
		end if
	case PURSUIT
		viewM = player_parent->body.p - body.p
		viewMag = viewM.magnitude()
		if viewMag > 500 then 
			viewM.normalize()
			viewM = viewM * 500
		end if		
		noalert = 1
		shouldPursue = 1
		if sgn(viewM.x()) = sgn(facing * 2 - 1) then
			dist = parent->raycast(body.p + Vector2D(0, -30), viewM, pt)
			if dist = -1 then
				if viewM.magnitude() < VIEW_DISTANCE * 1 then
					alertingFrames += 2
					if alertingFrames > 500 then alertingFrames = 500
					noalert = 0
					shouldPursue = 0
				end if
			end if
		end if
		shift_ = 1
		
		if shouldPursue = 1 then
			if dist <> -1 then
				if viewM.y() > 70 then
					if searchDown = 0 then 
						searchDown = sgn(viewM.x())
					else
						if blocked = 1 then
							searchDown *= -1
						end if
					end if
					dire_ = searchDown
				else
					searchDown = 0
					if abs(viewM.x()) > 10 then
						dire_ = sgn(viewM.x())
					else
						dire_ = 0
					end if
					if blocked = 1 andAlso clearJump = 1 andAlso takeJump = 0 then
						takeJump = 20
					end if
				end if
			else
				searchDown = 0
				dire_ = sgn(viewM.x())
				if groundAhead = 0 then dire_ = 0
			end if
			burstShots = 0
			burstTimer = 0
			burstFrames = 1
		else
			dire_ = 0
			searchDown = 0
			if burstTimer = 0 andAlso burstShots = 0 then
				burstShots = 5
			end if
			viewM = player_parent->body.p - body.p
			viewM.normalize()
			
			burstFrames -= 1
			
			if burstFrames = 0 then
				if burstShots > 1 then
					burstShots -= 1
					link.soundeffects_ptr->playSound(SND_SHOOT)
					proj_parent->create(body.p - Vector2D(0,20) + Vector2D(10,0) * ((facing*2)-1), viewM * 500, BULLET)
				elseif burstShots = 1 then
					burstTimer = 5
					burstShots -= 1
				end if
				if burstTimer > 0 then burstTimer -= 1
			end if
			
			if burstFrames <= 0 then 
				burstFrames = 3
			end if
		end if
		
		
		if noalert = 1 then alertingFrames -= 1
		if alertingFrames < lazyness * 0.5 then
			thought = CONCERNED
			alertAnim.hardSwitch(0)
			dire_ = 0
		end if
	end select
	
	if takeJump > 0 then
		takeJump -= 1
		jump_ = 1
	else
		jump_ = 0
	end if
	

	pv = body.p + anim.getOffset()
	sv = Vector2D(anim.getWidth(), anim.getHeight())
	proj_parent->checkDynamicCollision(pv, sv)
	
	if health <= 0 then
		return 1
	end if
	
	processControls(dire_,jump_,ups_,fire_,shift_, t)
	return 0
end function

sub Enemy.explosionAlert(p as Vector2D)
	dim as Vector2D expM
	dim as double kickback
	dim as double mag
	
	expM = p - (body.p - Vector2D(0, 24))
	mag = expM.magnitude()
	if mag < 200 then
		if thought <> PURSUIT then
			link.soundeffects_ptr->playSound(SND_ALARM)
			thought = PURSUIT
			takeJump = 1
			alertingFrames = lazyness*1.5
			dire_ = 0
			body.v.setX(0)
			alertAnim.hardSwitch(1)
		end if
		
		if mag < 70 then
			kickback = (70 - mag) / 70
			body.v = body.v - ((expM / mag) * kickback) * 250
			health -= kickback * 200
		end if
	else
		if thought <> PURSUIT then
			thought = CONCERNED
			facing = (sgn(expM.x()) + 1) * 0.5
			takeJump = 1
			alertingFrames = max(lazyness, alertingFrames)
			dire_ = 0
			body.v.setX(0)
			alertAnim.hardSwitch(0)
		end if
	end if
	
end sub

sub Enemy.processControls(dire as integer, jump as integer,_
                          ups as integer, fire as integer,_
                          shift as integer, t as double)
    dim as Vector2D gtan
    dim as double curSpeed, oSpeed
    dim as integer addSpd, ptype
    dim as GameSpace ptr gsp
	gsp = cast(GameSpace ptr, game_parent)
    
   
	if parent->isGrounded(body_i, this.groundDot) then
        gtan = parent->getGroundingNormal(body_i, Vector2D(0,-1), Vector2D(dire,0), this.groundDot)
        gtan = gtan.perp()   
        if jumpHoldFrames = 0 then state = E_GROUNDED

        curSpeed = gtan * this.body.v
        oSpeed = curSpeed
        if dire = 1 then
            curSpeed = curSpeed + this.acc * t
            if this.body.v.y() < 0 then
                if jumpHoldFrames = 0 then anim.hardSwitch(3)
            else
                anim.hardSwitch(3)
                jumpHoldFrames = 0
            end if
            if shift = 0 then
                if curSpeed > this.top_speed then curSpeed = this.top_speed
                anim.setSpeed(1)
            else
                if curSpeed > this.top_speed*1.5 then curSpeed = this.top_speed*1.5 
                anim.setSpeed(2)
            end if
            addSpd = 1
            facing = 1

            this.body.friction = 0
        elseif dire = -1 then
            facing = 0
            if this.body.v.y() < 0 then
                if jumpHoldFrames = 0 then anim.hardSwitch(2)
            else
                anim.hardSwitch(2)
                jumpHoldFrames = 0
            end if

            curSpeed = curSpeed - this.acc * t
            if shift = 0 then
                if curSpeed < -this.top_speed then curSpeed = -this.top_speed
                anim.setSpeed(1)
            else
                if curSpeed < -this.top_speed*1.5 then curSpeed = -this.top_speed*1.5  
                anim.setSpeed(2)
            end if
            addSpd = 1
            this.body.friction = 0
        else
            curSpeed = curSpeed * this.cutSpeed
            addSpd = 0
            this.body.friction = this.stopFriction
            if this.body.v.y() < 0 then
                if jumpHoldFrames = 0 then anim.switch(facing)
            else
                anim.switch(facing)
                jumpHoldFrames = 0
            end if
        end if
        lastTopSpeed = max(abs(curSpeed), this.top_speed)
        groundedFrames += 1
        if groundedFrames = GROUND_FRAMES+1 then groundedFrames = GROUND_FRAMES
        if groundedFrames = GROUND_FRAMES then freeJump = freeJumpFrames
        groundSwitchAnimFrames = 3
        if jumpHoldFrames > 0 then jumpHoldFrames -= 1
    else
        groundedFrames = 0
        if state <> E_JUMPING andAlso jumpHoldFrames = 0 then 
            if groundSwitchAnimFrames = 0 then 
                if facing = 0 then
                    anim.hardSwitch(4)
                elseif facing = 1 then
                    anim.hardSwitch(5)
                end if
            end if
            state = E_FREE_FALLING
        else
            jumpHoldFrames = 4
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
            if state = E_FREE_FALLING then facing = 1
        elseif dire = -1 then
            curSpeed = curSpeed - this.air_acc * t
            
            if curSpeed < -this.lastTopSpeed then curSpeed = -this.lastTopSpeed 
           
            addSpd = 1
            dire = -1
            if state = E_FREE_FALLING then facing = 0
        else
            curSpeed = curSpeed * this.cutSpeed
            addSpd = 0
        end if
        if freeJump > 0 then freeJump -=1
        if groundSwitchAnimFrames > 0 then groundSwitchAnimFrames -= 1
    end if   
    
    if jump = 1 and lastJump = 0 then
        if freeJump > 0 and isJumping = 0 then
            state = E_JUMPING
            isJumping = 1
            jumpBoostFrames = this.boostFrames
            if facing = 0 then 
                anim.hardSwitch(4)
            else
                anim.hardSwitch(5)
            end if
            this.body.v = Vector2D(this.body.v.x(),0) - Vector2D(0, this.jumpImpulse)
        end if
    else
        if jump = 0 then isJumping = 0
    end if
    lastJump = jump
    
    if isJumping = 1 then
        jumpBoostFrames -= 1
        if jumpBoostFrames = 0 then isJumping = 0
        this.body.f = Vector2D(0,-jumpBoostFrames*this.boostForce)
	else
		this.body.f = Vector2D(0,0)
    end if
    
    if addSpd = 1 then 
        this.body.v = this.body.v + (curSpeed - oSpeed) * gtan
    end if
      
    anim.step_animation()
    alertAnim.step_animation()
    lastUps = ups
    lastFire = fire
end sub


