#ifndef EFFECTCONTROLLER_BI
#define EFFECTCONTROLLER_BI

#include "constants.bi"
#include "oneshoteffects.bi"
#include "projectilecollection.bi"
#include "vector2d.bi"
#include "hash2d.bi"

enum EffectControllerType_e
    RADAR_PULSE      = 0
    SHIMMER          = 1
    STEAM            = 2
    DRIP             = 3
    ONE_SHOT_SMOKE   = 4
    ONE_SHOT_EXPLODE = 5
    OPEN_DOOR        = 6
    ACTIVE_SPEAKER   = 7
end enum

type ObjectEffect_t
    as zstring ptr            effect_name
    as EffectControllerType_e effect_type
    as Vector2D               p
    as Vector2D               size
    as shapeType              shape
    as double                 density
    as orderType              inRangeSet 
    as integer                counter
    as Animation              anim
end type

type ProjectileCollection_ as ProjectileCollection
 

type EffectController
    public:
        declare constructor()
        declare destructor()
        declare sub setParent(ose_ptr as OneShotEffects ptr, _
                              pc_ptr as ProjectileCollection_ ptr)
                         
        declare sub create(effect_name as string,_
                           effect_type as EffectControllerType_e,_
                           shape as shapeType,_
                           p as Vector2D,_
                           size as Vector2D,_
                           density as double,_
                           inRangeSet as orderType)
                           
        declare sub init(lvlWidth as integer, lvlHeight as integer)
                           
        declare sub processFrame(camera as Vector2D)
        declare sub drawEffects(scnbuff as integer ptr,_
                                camera as Vector2D,_
                                inRangeSet as orderType)
                                
        declare sub explodeEffects(p as Vector2D)
        
        declare sub flush()

    private:
        declare function processEffect(byref effect_p as ObjectEffect_t) as integer
        declare sub drawEffect(scnbuff as integer ptr, effect_p as ObjectEffect_t)
        
        as OneShotEffects ptr        oneshots
        as ProjectileCollection_ ptr particles
        as Hash2D                    effectContainer

end type


#endif
