#ifndef PLAYER_BI
#define PLAYER_BI

#include "TinyBody.bi"
#include "TinySpace.bi"
#include "level.bi"
#include "animation.bi"
#include "projectilecollection.bi"
#include "objectlink.bi"
#Include "item.bi"

#define LADDER_GRAB_EDGE_LENGTH 24
#define CLIMBING_SPEED 82
#define GROUND_FRAMES 1
#define BOMB_TRANS_DIST 64
#define BOMB_TRANS_FRAMES 8.0
#define BOMB_SCREEN_IND_RAD 18
#define SCREEN_IND_BOUND 0

enum PlayerState
    ON_LADDER
    JUMPING
    FREE_FALLING
    GROUNDED
end enum

enum Player_BombIndicateState
	TOO_CLOSE
	PLAYER_ARROW
	SCREEN_ARROW
end enum

type Player_bombData
	as Player_BombIndicateState curState
	as Player_BombIndicateState nextState
    as double  tilePosY
    as integer bombType
	as integer isSwitching
	as integer switchFrame
	as Vector2D bombP
	as Vector2D indicatorP
	as double   angle
	as double   shrink
	as Vector2D offset
	as integer  animating
    as integer lastNumbers
    as integer lastHasBomb
    as integer cantPlace
    as string ID
    as integer deactivateGroupFlag
end type

type Player
    public:
        declare constructor
        declare sub setParent(p as TinySpace ptr, l as Level ptr, g as ProjectileCollection ptr,_
                              gs as any ptr)
        declare sub setLink(link_ as objectlink)
        declare sub processControls(dire as integer, jump as integer,_
                                    ups as integer, fire as integer,_
                                    shift as integer, numbers() as integer,_
                                    explodeAll as integer, deactivateAll as integer,_
                                    turnstyle as integer, activate as integer,_
                                    t as double)
        declare sub processItems(t as double)
        declare sub drawOverlay(scnbuff as uinteger ptr, offset as Vector2D = Vector2D(0,0))
        declare sub loadAnimations(filename as string)
        declare sub drawPlayer(scnbuff as uinteger ptr)
        declare sub drawPlayerInto(destbuff as uinteger ptr, posx as integer, posy as integer, positionless as integer = 0)
        declare function getState() as PlayerState
        declare sub explosionAlert(p as Vector2D)
        declare sub harm(p as Vector2D, amount as integer)
        declare sub getBounds(byref p as Vector2D, size as Vector2D)
        declare sub centerToMap(byref p as Vector2D)
        declare sub exportMovementParameters(byref dire_p as integer, byref jump_p as integer,_
											 byref ups_p as integer, byref shift_p as integer)
        declare function beingHarmed() as integer
        declare sub removeItemReference(data_ as integer)
		
		explodeAllHoldFrames as integer
		deactivateHoldFrames as integer
		
		explodeAllHoldFrames_time as integer
		deactivateHoldFrames_time as integer
		
    
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
        top_speed_mul  as double
        groundDot      as double
        cutSpeed       as double
        stopFriction   as double
        boostFrames    as integer
        boostForce     as double
        jumpImpulse    as double
        harmedFlashing as integer
        freeJumpFrames as integer
        as PlayerState state
        
    private: 
        declare function onLadder() as integer
        declare function onSpikes() as integer
        declare sub computeCoverage()
        declare sub switch(ls as LevelSwitch_t)
        declare sub drawDetectMeter(scnbuff as integer ptr, level as integer)
                
        as integer _dire_
        as integer _jump_
        as integer _ups_
        as integer _shift_
        as integer drawArrow

        as Player_bombData bombData(0 to 9)
        
        as double  coverValue
        as double  covered
        as integer lastGrounded
        as objectlink link
        as integer lastSpikes
        as any ptr game_parent
        as integer groundSwitchAnimFrames
        as integer groundedFrames
        as integer lastUps
        as PlayerState lastState
        as TinySpace ptr parent
        as Level ptr level_parent
        as ProjectileCollection ptr proj_parent
        as integer lastJump
        as integer lastJumpMemory
        as integer lastJumpMemoryFrames
        as integer isJumping
        as integer jumpBoostFrames
        as integer freeJump
        
        as Animation hudspinner
        as Animation anim
        as Animation silhouette
        as zimage bombListTiles
        as integer revealSilo
        
        as integer lastFire 
        as double lastTopSpeed
        as integer jumpHoldFrames
        as integer pendingSwitch
        as LevelSwitch_t pendingSwitchData
        as Vector2D lastVel
        as integer landedSFXFrames
        
        as integer spinnerItem
        as double spinnerAngle
        as double spinnerAngleTarget
        as double spinnerAngleAcc
        as double spinnerAngleV
        as integer spinnerCount(0 to 5)
        
        as integer itemBarLife
        as integer itemBarPos
        
        as zimage hudDigits
        as zimage healthindi
        as zimage hudTrim
        as zimage detectmeter
        as zimage huditembar
        
End type

#endif
