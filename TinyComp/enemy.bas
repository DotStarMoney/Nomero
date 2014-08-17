#include "enemy.bi"
#include "TinyBlock.bi"
#include "utility.bi"
#include "debug.bi"
#include "gamespace.bi"
#include "player.bi"


constructor Enemy
    acc   = 3000
    air_acc = 400
    top_speed = 150
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
    boostFrames    = 13
    boostForce     = 800
    jumpImpulse    = 150
    freeJumpFrames = 3 
    lastUps = 0
    lastFire = 0
    lastTopSpeed = 200
    groundSwitchAnimFrames = 0
    anim.play()
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
    'anim.load(filename)
end sub

sub Enemy.drawEnemy(scnbuff as uinteger ptr)
    anim.drawAnimation(scnbuff, body.p.x(), body.p.y())
end sub

sub Enemy.process(t as double)
	

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
                    anim.hardSwitch(7)
                elseif facing = 1 then
                    anim.hardSwitch(8)
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
    end if
    
    if addSpd = 1 then 
        this.body.v = this.body.v + (curSpeed - oSpeed) * gtan
    end if
    
    
    
    anim.step_animation()
    lastUps = ups
    lastFire = fire
end sub


