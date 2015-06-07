#include "effectcontroller.bi"
#include "projectilecollection.bi"
#include "oneshoteffects.bi"
#include "utility.bi"
#include "soundeffects.bi"
#include "gamespace.bi"

constructor EffectController()
    ''
end constructor

destructor EffectController()
    flush()
end destructor

sub EffectController.setLink(link_ as objectlink)
	link = link_
end sub	

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
    effectContainer.flush()
end sub

sub EffectController.init(lvlWidth as integer, lvlHeight as integer)
	flush()
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
	tempObj.counter = 0
	select case effect_type 
	case ACTIVE_SPEAKER
		tempObj.anim.load("speaker.txt")
		if density > 0.5 then tempObj.anim.hardSwitch(1)
		tempObj.anim.play()
	case OPEN_DOOR
		tempObj.anim.load("door.txt")
		tempObj.anim.play()
	case TELEPORTER_SHIELD
		tempObj.anim.load("teleportershield.txt")
		tempObj.anim.play()
	end select

   
	effectContainer.insert(tempObj.p, tempObj.p + tempObj.size, @tempObj)
                            
end sub
           
sub EffectController.processFrame(camera as Vector2D)
    dim as any ptr ptr effect_list
    dim as integer effect_N, i
    dim as ObjectEffect_t ptr tempObj_
    dim as Vector2D a, b
    a = camera - Vector2D(SCRX, SCRY)*0.5
    b = camera + Vector2D(SCRX, SCRY)*0.5
    
    effect_N = effectContainer.search(a, b, effect_list)
    if effect_N > 0 then
        for i = 0 to effect_N - 1
            tempObj_ = effect_list[i]
            if processEffect(*tempObj_) = 1 then
				effectContainer.remove(tempObj_)
            end if
        next i
        deallocate(effect_list)
    end if
    
end sub
    
sub EffectController.drawEffects(scnbuff as integer ptr,_
                                 camera as Vector2D,_
                                 inRangeSet as orderType)
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
            drawEffect(scnbuff, *tempObj_)
        next i
        deallocate(effect_list)
    end if                               
end sub


sub EffectController.removeEffect(name_ as string)
	dim as ObjectEffect_t ptr obj_ptr
	effectContainer.rollReset()
	do
		obj_ptr = effectContainer.roll()
		if obj_ptr <> 0 then
			if ucase(*(obj_ptr->effect_name)) = ucase(name_) then 
				deallocate(obj_ptr->effect_name)
				effectContainer.remove(obj_ptr)
				exit do
			end if
		else
			exit do
		end if
	loop
end sub

function EffectController.processEffect(byref effect_p as ObjectEffect_t) as integer
    dim as Vector2D e_loc
    dim as integer i
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
    case ACTIVE_SPEAKER
		if effect_p.counter = 0 then
			effect_p.counter = 126
		elseif effect_p.counter > 1 then
			effect_p.counter -= 1
		else
			effect_p.counter = 126
		end if
		if effect_p.counter > 70 then
			effect_p.anim.step_animation()
		end if
    case RADAR_PULSE
		if effect_p.counter = 0 then
			if effect_p.counter = 0 then 
				effect_p.counter = effect_p.density * 60
			else
				effect_p.counter -= 1
			end if
			oneshots->create(effect_p.p + effect_p.size*0.5, RADAR, Vector2D(0,0))
		else
			effect_p.counter -= 1
		end if
    case SHIMMER
        if int(rnd * effect_p.density * 50) = 0 then
            oneshots->create(e_loc, SPARKLE, Vector2D(0, 0))
        end if
    case STEAM
        if int(rnd * effect_p.density * 25) = 0 then
			oneshots->create(e_loc, SMOKE, Vector2D(0, -2.5))
        end if
    case ONE_SHOT_SMOKE 
		if effect_p.counter = 0 then
			effect_p.counter = 1 + int(rnd * 16)
		else
			effect_p.counter -= 1
			if effect_p.counter = 1 then
				oneshots->create(effect_p.p + effect_p.size*0.5, SMOKE, Vector2D(int(rnd * 2) - 1,-1 + -int(rnd * 2)))
				return 1
			end if
		end if
	case ONE_SHOT_EXPLODE
		if effect_p.counter = 0 then
			effect_p.counter = 2 + int(rnd * 14)
		else
			effect_p.counter -= 1
			if effect_p.counter = 1 then
			
				link.oneshoteffects_ptr->create(e_loc + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,1)
				link.oneshoteffects_ptr->create(e_loc + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,2)
				link.oneshoteffects_ptr->create(e_loc + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
				link.soundeffects_ptr->playSound(SND_EXPLODE)

				for i = 1 to 3
					link.projectilecollection_ptr->create(e_loc, Vector2D(rnd*2 - 1, rnd*2 - 1) * (1 + rnd*700), DETRITIS)
				next i
			
				link.level_ptr->addFallout(e_loc.x(), e_loc.y())
				link.gamespace_ptr->vibrateScreen()	
				
				link.soundeffects_ptr->playSound(SND_EXPLODE)
				return 1
			end if
		end if
	case DRIP
		if effect_p.counter <= 1 then
			effect_p.counter = effect_p.density * 80 + int(rnd * effect_p.density * 80)
		else
			effect_p.counter -= 1
			if effect_p.counter = 1 then
				particles->create(effect_p.p + Vector2D(0, 10), Vector2D(0,0), WATER_DROP)
			end if
		end if
    end select   
    return 0
end function
sub EffectController.explodeEffects(p as Vector2D)
	dim as any ptr ptr effect_list
    dim as integer effect_N, i
    dim as ObjectEffect_t ptr tempObj_
    dim effect_p as ObjectEffect_t
    dim as Vector2D a, b
    a = p
    b = p
    
    effect_N = effectContainer.search(a, b, effect_list)
    if effect_N > 0 then
        for i = 0 to effect_N - 1
            tempObj_ = effect_list[i]
            effect_p = *tempObj_
            if (effect_p.effect_type = RADAR_PULSE) orElse (effect_p.effect_type = SHIMMER) then
				deallocate(effect_p.effect_name)
				effectContainer.remove(tempObj_)
            end if
            
        next i
        deallocate(effect_list)
    end if
end sub

sub EffectController.drawEffect(scnbuff as integer ptr, effect_p as ObjectEffect_t)
	select case effect_p.effect_type
	case ACTIVE_SPEAKER
		effect_p.anim.drawAnimation(scnbuff, effect_p.p.x(), effect_p.p.y())
	case OPEN_DOOR
		effect_p.anim.drawAnimation(scnbuff, effect_p.p.x(), effect_p.p.y())
	case TELEPORTER_SHIELD
		effect_p.anim.drawAnimation(scnbuff, effect_p.p.x(), effect_p.p.y())
	end select
end sub
