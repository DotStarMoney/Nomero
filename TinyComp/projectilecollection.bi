#ifndef PROJECTILECOLLECTION_BI
#define PROJECTILECOLLECTION_BI

#include "vector2d.bi"
#include "tinyspace.bi"
#include "tinybody.bi"
#include "oneshoteffects.bi"
#include "animation.bi"
#include "level.bi"

enum Projectiles
    CHERRY_BOMB
    DETRITIS
end enum

type Projectile_t
    as TinyBody body
    as integer  body_i
    as Animation anim
    as Projectiles flavor
    as integer lifeFrames
end type

type ProjectileNode_t
    as Projectile_t data_
    as ProjectileNode_t ptr next_
    as ProjectileNode_t ptr prev_
end type

type Level_ as Level

type ProjectileCollection
    public:
        declare constructor()
        declare destructor()
        declare sub create(p_ as Vector2D, v_ as Vector2D, f_ as integer = CHERRY_BOMB)
        declare sub draw_collection(scnbuff as uinteger ptr)
        declare sub proc_collection(t as double)
        declare sub setParent(TS as TinySpace ptr, LS as Level_ ptr, GS as any ptr)
        declare sub setEffectsGenerator(s as OneShotEffects ptr)
        declare sub flush()
    private:
        as TinySpace ptr parent_space
        as ProjectileNode_t ptr head_
        as integer              numNodes
        as OneShotEffects ptr   effects
        as any ptr game_space
        as Level_ ptr parent_level
end type



#endif