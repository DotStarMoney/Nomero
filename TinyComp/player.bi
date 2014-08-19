#ifndef PLAYER_BI
#define PLAYER_BI

#include "TinyBody.bi"
#include "TinySpace.bi"
#include "level.bi"
#include "animation.bi"
#include "projectilecollection.bi"
#include "objectlink.bi"

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
        declare sub setLink(link_ as objectlink)
        declare sub processControls(dire as integer, jump as integer,_
                                    ups as integer, fire as integer,_
                                    shift as integer, t as double)
        declare sub loadAnimations(filename as string)
        declare sub drawPlayer(scnbuff as uinteger ptr)
        declare function getState() as PlayerState
        declare sub explosionAlert(p as Vector2D)
        declare sub harm(p as Vector2D, amount as integer)
        declare sub getBounds(byref p as Vector2D, size as Vector2D)
        declare sub centerToMap(byref p as Vector2D)
        declare function beingHarmed() as integer
    
    
		bombs   as integer
		health  as integer
		charge  as integer
		chargeFlicker as integer
        body    as TinyBody
        body_i  as integer
        acc     as double
        air_acc as double
        top_speed as double
        air_top_speed as double
        
        as integer facing
        groundDot      as double
        cutSpeed       as double
        stopFriction   as double
        boostFrames    as integer
        boostForce     as double
        jumpImpulse    as double
        harmedFlashing as integer
        freeJumpFrames as integer
    private: 
        declare function onLadder() as integer
        declare function onSpikes() as integer
        declare sub switch(ls as LevelSwitch_t)
        
        as objectlink link
        as integer lastSpikes
        as any ptr game_parent
        as integer groundSwitchAnimFrames
        as integer groundedFrames
        as integer lastUps
        as PlayerState state
        as PlayerState lastState
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
        as integer pendingSwitch
        as LevelSwitch_t pendingSwitchData
        as Vector2D lastVel
        as integer landedSFXFrames
End type

#endif
