#ifndef ENEMY_BI
#define ENEMY_BI

#include "TinyBody.bi"
#include "TinySpace.bi"
#include "level.bi"
#include "animation.bi"
#include "projectilecollection.bi"
#include "objectlink.bi"

#define E_LADDER_GRAB_EDGE_LENGTH 24
#define E_CLIMBING_SPEED 82
#define E_GROUND_FRAMES 1

enum EnemyState
    E_JUMPING
    E_FREE_FALLING
    E_GROUNDED
    E_ON_LADDER
end enum


enum EnemyType
	SOLDIER_1
	SOLDIER_2
	BEAR
end enum

#define ENEMY_GROUND_FRAMES 1

type Player_ as Player


type Enemy
    public:
        declare constructor
        declare destructor
        declare sub setParent(p as TinySpace ptr, l as Level ptr)
        declare sub setLink(link_ as objectLink)
        declare function process(t as double) as integer
        declare sub loadType(type_ as EnemyType)
        declare sub drawEnemy(scnbuff as uinteger ptr)
        declare function getState() as EnemyState
        declare sub explosionAlert(p as Vector2D)
    
        body           as TinyBody
        body_i         as integer
        acc            as double
        air_acc        as double
        top_speed      as double
        air_top_speed  as double
        facing         as integer
        top_speed_mul  as double
        groundDot      as double
        cutSpeed       as double
        stopFriction   as double
        boostFrames    as integer
        boostForce     as double
        jumpImpulse    as double
        freeJumpFrames as integer
        anim           as Animation
        suspicionLevel as double
        canShoot       as integer
        death          as integer
        alertOthers    as integer
        receivedAlert  as integer
    private: 
        declare function onLadder() as integer
        declare function onSpikes() as integer
		declare sub processControls(dire as integer, jump as integer,_
								    ups as integer, fire as integer,_
								    shift as integer, t as double)
		
		as objectLink link    
		as EnemyType enemy_type
        as any ptr game_parent
        as integer groundSwitchAnimFrames
        as integer groundedFrames
        as integer lastUps
        as EnemyState state
        as TinySpace ptr parent
        as Level ptr level_parent
        as integer lastJump
        as integer isJumping
        as integer jumpBoostFrames
        as integer freeJump
        as integer lastFire 
        as double lastTopSpeed
        as integer jumpHoldFrames
        as integer lastJumpMemory
        as integer lastJumpMemoryFrames
        as integer lastGrounded
        as EnemyState lastState
        as vector2D lastVel
        as integer landedSFXFrames
        as integer isCrouching
        as integer lastSpikes
        
        as integer dire_
        as integer jump_
        as integer ups_
        as integer fire_
        as integer shift_
        
        as integer health

End type

#endif

