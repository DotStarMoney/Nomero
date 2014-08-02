#ifndef ONESHOTEFFECTS_BI
#define ONESHOTEFFECTS_BI

#include "vector2d.bi"
#include "animation.bi"

enum EffectType_
    EXPLODE
end enum

type Effect_t
    as Vector2D p
    as Vector2D v
    as Animation anim
end type

type EffectNode_t
    as Effect_t data_
    as EffectNode_t ptr next_
    as EffectNode_t ptr prev_
end type

type OneShotEffects
    public:
        declare constructor()
        declare destructor()
        declare sub setParent(par as any ptr)
        declare sub create(p_ as Vector2D, fx as EffectType_ = EXPLODE, _
                           d_ as Vector2D = Vector2D(0,0), s_ as integer = 1) 
        declare sub proc_effects(t as double)
        declare sub draw_effects(scnbuff as uinteger ptr)
    private:
        as EffectNode_t ptr head_
        as integer          numNodes
        as any ptr parent
end type


#endif





