#include "enemy.bi"
#include "TinyBlock.bi"
#include "utility.bi"
#include "debug.bi"
#include "gamespace.bi"
#include "player.bi"
#include "pathtracker.bi"

constructor Enemy
    acc   = 3000
    air_acc = 400
    top_speed = 150
    top_speed_mul = 1.5
    air_top_speed = 160
    lastJump = 0
    isJumping = 0
    jumpBoostFrames = 0
    state = E_FREE_FALLING
    facing         = 1
    groundDot      = 0.2
    cutSpeed       = 0.5
    stopFriction   = 3
    boostFrames    = 13
    boostForce     = 800
    jumpImpulse    = 150
    freeJumpFrames = 6
    lastUps = 0
    lastFire = 0
    lastTopSpeed = 200
    groundSwitchAnimFrames = 0
    health = 100
    
    dire_ = 0
    jump_ = 0
    ups_ = 0
    fire_ = 0
    shift_ = 0
    
    anim.play()
end constructor

function Enemy.getState() as EnemyState
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
	link.pathtracker_ptr->register(@this)
end sub

sub Enemy.drawEnemy(scnbuff as uinteger ptr)
    anim.drawAnimation(scnbuff, body.p.x(), body.p.y())
end sub

function Enemy.process(t as double) as integer
	dim as PathTracker_Inputs_t inputs
	
	link.pathtracker_ptr->requestInputs(@this, inputs)
	
	processControls(inputs.dire,inputs.jump,inputs.ups,fire_,inputs.shift, t)
	return 0
end function

sub Enemy.explosionAlert(p as Vector2D)
	''''
	
end sub

sub Enemy.processControls(dire as integer, jump as integer,_
                          ups as integer, fire as integer,_
                          shift as integer, t as double)
    dim as Vector2D gtan
    dim as double curSpeed, oSpeed
    dim as integer addSpd, ptype, spikes
    dim as LevelSwitch_t ls
    dim as GameSpace ptr gsp
	gsp = cast(GameSpace ptr, game_parent)
	
    if state <> E_ON_LADDER andAlso ups <> 0 andAlso (onLadder() = 1) _
       andAlso lastUps = 0 then
        state = E_ON_LADDER
        jumpHoldFrames = 0
        anim.setSpeed(1)
        'anim.hardSwitch(6)
        this.body.friction = this.stopFriction
        this.body.v = Vector2D(0,0)
        isJumping = 0
    end if
    if state = E_ON_LADDER then
        groundedFrames = 0
        if onLadder() = 1 then
            if parent->isGrounded(body_i, this.groundDot) andAlso ups > -1 then
                state = E_GROUNDED
            else
                this.body.f = -this.body.m * parent->getGravity()
                this.body.v = Vector2D(0,0)
                if dire = 1 then
                    this.body.v = this.body.v + Vector2D(E_CLIMBING_SPEED,0) 
                elseif dire = -1 then
                    this.body.v = this.body.v - Vector2D(E_CLIMBING_SPEED,0) 
                end if
                if ups = -1 then
                    this.body.v = this.body.v - Vector2D(0, E_CLIMBING_SPEED) 
                elseif ups = 1 then
                    this.body.v = this.body.v + Vector2D(0, E_CLIMBING_SPEED) 
                end if
                if ups <> 0 orElse dire <> 0 then
                    anim.play()
                else
                    anim.pause()
                end if
            end if
        else
            state = E_FREE_FALLING
        end if
    elseif parent->isGrounded(body_i, this.groundDot) then
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
                if curSpeed > this.top_speed*top_speed_mul then curSpeed = this.top_speed*top_speed_mul
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
                if curSpeed < -this.top_speed*top_speed_mul then curSpeed = -this.top_speed*top_speed_mul
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
        if groundedFrames = E_GROUND_FRAMES+1 then groundedFrames = E_GROUND_FRAMES
        if groundedFrames = E_GROUND_FRAMES then freeJump = freeJumpFrames
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
        if state <> E_ON_LADDER then this.body.f = Vector2D(0,0)
    end if
    
    if addSpd = 1 then 
        this.body.v = this.body.v + (curSpeed - oSpeed) * gtan
    end if
    

	
    anim.step_animation()
        
    lastUps = ups
    lastFire = fire
end sub


function Enemy.onSpikes() as integer
	dim as integer x0,y0
    dim as integer x1,y1
    dim as integer xscan, yscan
    
    x0 = body.p.x() - anim.getWidth() * 0.5 - 8
    if state <> E_JUMPING then
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
   
function Enemy.onLadder() as integer
    dim as integer x0,y0
    dim as integer x1,y1
    dim as integer xscan, yscan
    
    x0 = body.p.x() - anim.getWidth() * 0.5 - 16
    y0 = body.p.y() - anim.getHeight() * 0.5 - 16
    x1 = x0 + anim.getWidth() + 16
    y1 = y0 + anim.getHeight()
    x0 = (x0 + E_LADDER_GRAB_EDGE_LENGTH) / 16
    y0 = (y0 + E_LADDER_GRAB_EDGE_LENGTH) / 16
    x1 = (x1 - E_LADDER_GRAB_EDGE_LENGTH) / 16
    y1 = (y1 - E_LADDER_GRAB_EDGE_LENGTH) / 16
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
