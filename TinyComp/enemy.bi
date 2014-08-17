#ifndef ENEMY_BI
#define ENEMY_BI

#include "TinyBody.bi"
#include "TinySpace.bi"
#include "level.bi"
#include "animation.bi"
#include "projectilecollection.bi"


enum EnemyPhysicalState
    E_JUMPING
    E_FREE_FALLING
    E_GROUNDED
end enum

enum EnemeyThoughtState
	IDLE
	CONCERNED
	PURSUIT
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
        declare sub setParent(p as TinySpace ptr, l as Level ptr, g as ProjectileCollection ptr,_
                              gs as any ptr, ply as Player_ ptr)
                              
        declare sub process(t as double)
        declare sub loadType(type_ as EnemyType)
        declare sub drawEnemy(scnbuff as uinteger ptr)
        declare function getState() as EnemyPhysicalState
    
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
		declare sub processControls(dire as integer, jump as integer,_
								    ups as integer, fire as integer,_
								    shift as integer, t as double)
								    
		as EnemyType enemy_type
		as EnemeyThoughtState thought
        as any ptr game_parent
        as integer groundSwitchAnimFrames
        as integer groundedFrames
        as integer lastUps
        as EnemyPhysicalState state
        as integer facing
        as TinySpace ptr parent
        as Level ptr level_parent
        as Player_ ptr player_parent
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

