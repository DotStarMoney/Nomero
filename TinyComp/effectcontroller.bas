#include "effectcontroller.bi"
#include "projectilecollection.bi"
#include "oneshoteffects.bi"

constructor EffectController()
    ''
end constructor

destructor EffectController()
    flush()
end destructor

sub EffectController.flush()
    dim as ObjectEffect_t ptr obj_ptr
    effectContainer.rollReset()
    do
        obj_ptr = effectContainer.roll()
        if obj_ptr <> 0 then
            if obj_ptr->effect_name <> 0 then deallocate(obj_ptr->effect_name)
        else
            exit do
        end if
    loop
end sub

sub EffectController.init(lvlWidth as integer, lvlHeight as integer)
    flush()
    effectContainer.flush()
    effectContainer.init(lvlWidth, lvlHeight, sizeof(ObjectEffect_t))
end sub

sub EffectController.setParent(ose_ptr as OneShotEffects ptr, _
                               pc_ptr as ProjectileCollection ptr)
    oneshots = ose_ptr
    particles = pc_ptr
end sub
         
sub EffectController.create(effect_name as string,_
                            effect_type as EffectControllerType_e,_
                            shape as shapeType,_
                            p as Vector2D,_
                            size as Vector2D,_
                            density as double,_
                            inRangeSet as orderType)
                            
   dim as ObjectEffect_t tempObj
   
   
   tempObj.effect_name = allocate(len(effect_name)+1)
   *(tempObj.effect_name) = effect_name
   tempObj.effect_type = effect_type
   tempObj.p = p 
   tempObj.size = size
   tempObj.density = density / 65535
   tempObj.shape = shape
   tempObj.inRangeSet = inRangeSet
   
   effectContainer.insert(tempObj.p, tempObj.p + tempObj.size, @tempObj)
                            
end sub
           
sub EffectController.processFrame(camera as Vector2D)
    dim as any ptr ptr effect_list
    dim as integer effect_N, i
    dim as ObjectEffect_t ptr tempObj_
    dim as Vector2D a, b
    a = camera - Vector2D(SCRX, SCRY) * 0.5
    b = camera + Vector2D(SCRX, SCRY) * 0.5
    
    effect_N = effectContainer.search(a, b, effect_list)
    if effect_N > 0 then
        for i = 0 to effect_N - 1
            tempObj_ = effect_list[i]
            processEffect(*tempObj_)
        next i
        deallocate effect_list
    end if
    
end sub
    
sub EffectController.drawEffects(scnbuff as integer ptr,_
                                 camera as Vector2D,_
                                 inRangeSet as orderType)
                                
end sub

sub EffectController.processEffect(effect_p as ObjectEffect_t)
    dim as Vector2D e_loc
    do
        e_loc = Vector2D(effect_p.size.x() * rnd, effect_p.size.y() * rnd)
        e_loc = e_loc - effect_p.size * 0.5
        if effect_p.shape = ELLIPSE then
            if (((e_loc.x()^2) / ((effect_p.size.x()*0.5)^2)) + _
                ((e_loc.y()^2) / ((effect_p.size.y()*0.5)^2))) <= 1 then
                exit do
            end if
        else
            exit do
        end if
    loop
    e_loc = e_loc + effect_p.size * 0.5 + effect_p.p

    select case effect_p.effect_type
    case RADAR_PULSE
    case SHIMMER
        if int(rnd * effect_p.density * 10) = 0 then
            oneshots->create(e_loc, SPARKLE, Vector2D(0, 0))
        end if
    case STEAM
        if int(rnd * effect_p.density * 10) = 0 then
            oneshots->create(e_loc, SMOKE, Vector2D(0, -5))
        end if
    end select   
end sub
sub EffectController.drawEffect(effect_p as ObjectEffect_t)

end sub
