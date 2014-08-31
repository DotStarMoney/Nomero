#include "projectilecollection.bi"
#include "gamespace.bi"
#include "utility.bi"
#include "debug.bi"
#include "tinyspace.bi"
#include "player.bi"


constructor ProjectileCollection
    parent_space = 0
    proj_list.init(sizeof(Projectile_t))
end constructor

destructor ProjectileCollection
    flush()
end destructor

sub ProjectileCollection.flush()
    dim as Projectile_t ptr curNode
    
    proj_list.rollReset()
    do
		curNode = proj_list.roll()
		if curNode <> 0 then
			link.tinyspace_ptr->removeBody(curNode->body_i)
		else
			exit do
		end if
	loop
	proj_list.flush()
end sub

sub ProjectileCollection.setEffectsGenerator(s as OneShotEffects ptr)
    effects = s
end sub

sub ProjectileCollection.setLink(link_ as ObjectLink)
	link = link_
end sub

sub ProjectileCollection.create(p_ as Vector2D, v_ as Vector2D, f_ as integer = CHERRY_BOMB)
    dim as Projectile_t data_
    dim as Projectile_t ptr data_ptr
    if parent_space = 0 then exit sub
  	
    select case f_
    case CHERRY_BOMB    
        data_.body   = TinyBody(p_, 8, 10)
        data_.body.noCollide = 0
        data_.body.v = v_
        data_.flavor = CHERRY_BOMB
        data_.anim.load("bombanim.txt")
        data_.anim.play()
    case DETRITIS
        data_.body   = TinyBody(p_, 8, 10)
        data_.body.elasticity = 1
        data_.body.noCollide = 1
        data_.body.v = v_
        data_.flavor = DETRITIS
        data_.anim.load("bombanim.txt")
        data_.anim.hardSwitch(int(rnd * 2) + 1)
        data_.anim.play()
        data_.lifeFrames = 15
	case WATER_DROP
	    data_.body   = TinyBody(p_ + Vector2D(12,4), 4, 2)
        data_.body.noCollide = 0
        data_.body.v = v_
        data_.anim.load("drip.txt")
        data_.anim.hardSwitch(0)
        data_.anim.play()
        data_.flavor = WATER_DROP
    case HEART
		
        data_.body   = TinyBody(p_, 8, 10)
        data_.body.elasticity = 1
        data_.body.noCollide = 1
        data_.body.v = v_
        data_.flavor = DETRITIS
        data_.anim.load("bombanim.txt")
        data_.anim.hardSwitch(3)
        data_.anim.play()
        data_.lifeFrames = 20
        
    case BULLET
		data_.body   = TinyBody(p_, 1, 2)
        data_.body.noCollide = 0
        data_.body.v = v_
        data_.body.f = Vector2D(0, -2 * DEFAULT_GRAV)
        data_.anim.load("bullet.txt")
        data_.anim.hardSwitch(0)
        data_.anim.play()
        data_.flavor = BULLET
    end select
    data_ptr = proj_list.push_back(@data_)

	
    data_ptr->body_i = link.tinyspace_ptr->addBody(@data_ptr->body)
end sub

sub ProjectileCollection.checkDynamicCollision(p_ as Vector2D, size_ as Vector2D)
    dim as Projectile_t ptr curNode
    dim as Projectile_t cur
    dim as integer deleteMe, i
    dim as GameSpace ptr GS
    dim as Vector2D p, size
    p = p_
    size = size_
   
	proj_list.rollReset()
	do
		curNode = proj_list.roll()
		if curNode <> 0 then
			cur = *curNode
			if cur.flavor = CHERRY_BOMB then
				if circleBox(cur.body.p.x(), cur.body.p.y(), cur.body.r,_
							 p.x(), p.y(), p.x() + size.x(), p.y() + size.y()) = 1 then
					effects->create(cur.body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,1)
					effects->create(cur.body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,2)
					effects->create(cur.body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
					effects->create(cur.body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
					link.soundeffects_ptr->playSound(SND_EXPLODE)

					for i = 1 to 5
						create(cur.body.p, Vector2D(rnd*2 - 1, rnd*2 - 1) * (1 + rnd*700), DETRITIS)
					next i
					
					GS = cast(GameSpace ptr, game_space)
					GS->vibrateScreen()
			
					parent_level->addFallout(cur.body.p.x(), cur.body.p.y())
			
					deleteMe = 1	 
						 
				end if
			end if
			if deleteMe = 1 then
				parent_space->removeBody(cur.body_i)
				proj_list.rollRemove()
			end if
		else 
			exit do
		end if
	loop
end sub

sub ProjectileCollection.proc_collection(t as double)
	dim as Projectile_t ptr     curNode
    dim as Projectile_t         cur
    dim as Vector2D p, plyr_p, plyr_sz
    dim as integer deleteMe, i
    dim as GameSpace ptr GS
    
    
    proj_list.rollReset()
	do
        curNode = proj_list.roll()
        if curNode <> 0 then
			cur = *curNode
			deleteMe = 0
			
			select case cur.flavor
			case DETRITIS
				curNode->lifeFrames -= 1
				curNode->body.v = curNode->body.v * 0.9
				if curNode->lifeFrames < 0 then
					
					deleteMe = 1
				end if
			case HEART
				curNode->lifeFrames -= 1
				curNode->body.v = curNode->body.v * 0.9
				if curNode->lifeFrames < 0 then
					
					deleteMe = 1
				end if
			case WATER_DROP
				if cur.body.didCollide > 0 then 
					deleteMe = 1
					effects->create(cur.body.p, WATER_SPLASH)
					link.soundeffects_ptr->playSound(SND_DRIP)
				end if
			case BULLET
				link.player_ptr->getBounds(plyr_p, plyr_sz)
				plyr_sz = plyr_sz + plyr_p
				if circleBox(cur.body.p.x(), cur.body.p.y(), 2,_
							 plyr_p.x(), plyr_p.y(),_
							 plyr_sz.x(), plyr_sz.y()) = 1 then
					link.player_ptr->harm(cur.body.p, 10)
					deleteMe = 1
					link.soundeffects_ptr->playSound(SND_HURT)
				end if
				if cur.body.didCollide > 0	then 
					deleteMe = 1
				end if
			case CHERRY_BOMB
				if cur.body.didCollide > 0 then 
					
					effects->create(cur.body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,1)
					effects->create(cur.body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,2)
					effects->create(cur.body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
					effects->create(cur.body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
					
					link.soundeffects_ptr->playSound(SND_EXPLODE)

					for i = 1 to 5
						create(cur.body.p, Vector2D(rnd*2 - 1, rnd*2 - 1) * (1 + rnd*700), DETRITIS)
					next i
					
					GS = cast(GameSpace ptr, game_space)
					GS->vibrateScreen()
			
					parent_level->addFallout(cur.body.p.x(), cur.body.p.y(), 1)
					
					deleteMe = 1
				end if
			end select
			p = curNode->body.p
			if p.x() < 0 orElse p.y() < 0 orElse _
			   p.x() >= (parent_level->getWidth() * 16) orElse _
			   p.y() >= (parent_level->getHeight() * 16) then
			   
			   deleteMe = 1
			   
			end if 
			curNode->anim.step_animation()
			if deleteMe = 1 then  
				link.tinyspace_ptr->removeBody(curNode->body_i)
				proj_list.rollRemove()     
			end if
		else
			exit do
		end if
    loop
end sub

sub ProjectileCollection.draw_collection(scnbuff as uinteger ptr)
    dim as Projectile_t ptr curNode
    
    proj_list.rollReset()
    do
        curNode = proj_list.roll()
        if curNode <> 0 then
			curNode->anim.drawAnimation(scnbuff, curNode->body.p.x(), curNode->body.p.y()) 
        else
			exit do
		end if
    loop 
end sub

sub ProjectileCollection.setParent(TS as TinySpace ptr, LS as Level ptr, GS as any ptr)
    parent_space = TS
    game_space = GS
    parent_level = LS
end sub
