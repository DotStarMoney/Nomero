#ifndef ONESHOTEFFECTS_BI
#define ONESHOTEFFECTS_BI

#include "vector2d.bi"
#include "animation.bi"
#include "objectlink.bi"

enum EffectType_
    EXPLODE
    FALLOUT_EXPLODE
    SPARKLE
    SMOKE
    RADAR
    WATER_SPLASH
    FLASH
    BLUE_FLASH
    ELECTRIC_FLASH
    LITTLE_PULSE
    SPARKLE2
    SPARKLE3
end enum

type Effect_t
    as Vector2D p
    as Vector2D v
    as Animation anim
    as integer firstDraw
    as EffectType_ fx
    as integer isFlash
    as integer endIt
end type

type EffectNode_t
    as Effect_t data_
    as EffectNode_t ptr next_
    as EffectNode_t ptr prev_
end type

type level_ as Level

type OneShotEffects
    public:
        declare constructor()
        declare destructor()
        declare sub setParent(par as any ptr, lev as level_ ptr)
        declare sub create(p_ as Vector2D, fx as EffectType_ = EXPLODE, _
                           d_ as Vector2D = Vector2D(0,0), s_ as integer = 1) 
        declare sub proc_effects(t as double)
        declare sub draw_effects(scnbuff as uinteger ptr)
        declare sub setLink(link_ as objectLink)
    private:
        as EffectNode_t ptr head_
        as objectLink	link
        as integer          numNodes
        as any ptr parent
        as level_ ptr level_parent
end type


#endif





