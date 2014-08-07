#ifndef PLAYER_BI
#define PLAYER_BI

#include "TinyBody.bi"
#include "TinySpace.bi"
#include "level.bi"
#include "animation.bi"
#include "projectilecollection.bi"

#define LADDER_GRAB_EDGE_LENGTH 24
#define CLIMBING_SPEED 82
#define GROUND_FRAMES 1

enum PlayerState
    ON_LADDER
    JUMPING
    FREE_FALLING
    GROUNDED
end enum

type Player
    public:
        declare constructor
        declare sub setParent(p as TinySpace ptr, l as Level ptr, g as ProjectileCollection ptr,_
                              gs as any ptr)
        declare sub processControls(dire as integer, jump as integer,_
                                    ups as integer, fire as integer,_
                                    shift as integer, t as double)
        declare sub loadAnimations(filename as string)
        declare sub drawPlayer(scnbuff as uinteger ptr)
        declare function getState() as PlayerState
    
        body    as TinyBody
        body_i  as integer
        acc     as double
        air_acc as double
        top_speed as double
        air_top_speed as double
        
        groundDot      as double
        cutSpeed       as double
        stopFriction   as double
        boostFrames    as integer
        boostForce     as double
        jumpImpulse    as double
        freeJumpFrames as integer
    private: 
        declare function onLadder() as integer
        declare sub switch(ls as LevelSwitch_t)
        
        as any ptr game_parent
        as integer groundSwitchAnimFrames
        as integer groundedFrames
        as integer lastUps
        as PlayerState state
        as integer facing
        as TinySpace ptr parent
        as Level ptr level_parent
        as ProjectileCollection ptr proj_parent
        as integer lastJump
        as integer isJumping
        as integer jumpBoostFrames
        as integer freeJump
        as Animation anim
        as integer lastFire 
        as double lastTopSpeed
        as integer jumpHoldFrames
    
End type

#endif
