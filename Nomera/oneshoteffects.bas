#include "oneshoteffects.bi"
#include "gamespace.bi"
#include "debug.bi"
#include "level.bi"
#include "soundeffects.bi"


constructor OneShotEffects
    this.head_ = 0
    this.numNodes = 0
end constructor

destructor OneShotEffects
    dim as EffectNode_t ptr curNode
    dim as EffectNode_t ptr oldNode
    
    curNode = this.head_
    while curNode <> 0
        oldNode = curNode
        curNode = curNode->next_
        delete(oldNode)
    wend 
    
end destructor

sub OneShotEffects.create(p_ as Vector2D, fx as EffectType_ = EXPLODE, _
                          d_ as Vector2D = Vector2D(0,0), s_ as integer = 1) 
    dim as EffectNode_t ptr temp
    dim as GameSpace ptr GS
    
    temp = this.head_
    this.head_ = new EffectNode_t 'allocate(sizeof(EffectNode_t))
    this.head_->prev_ = 0
    this.head_->next_ = temp
    if temp <> 0 then temp->prev_ = this.head_
    
    this.head_->data_.p = p_
    this.head_->data_.v = d_
    this.head_->data_.isFlash = 0
    this.head_->data_.endIt = 0
    select case fx
    case FLASH
		this.head_->data_.isFlash = 1
        this.head_->data_.endIt = 4
    case BLUE_FLASH
        this.head_->data_.isFlash = 1
        this.head_->data_.endIt = 4
    case ELECTRIC_FLASH
        this.head_->data_.anim.load("electricflash.txt")
        this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)
        this.head_->data_.isFlash = 1
        this.head_->data_.endIt = 3
    case EXPLODE
        this.head_->data_.anim.load("splode.txt")
        this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)
    case SMOKE
        this.head_->data_.anim.load("smokeanim.txt")
        this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)
    case SPARKLE
        this.head_->data_.anim.load("sparkle.txt")
        this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)
    case RADAR
        this.head_->data_.anim.load("radaranim.txt")
        this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)
    case LITTLE_PULSE
        this.head_->data_.anim.load("objects\media\ledflash.txt")
        this.head_->data_.anim.hardSwitch(1)
        this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)    
    case FALLOUT_EXPLODE
	    this.head_->data_.anim.load("splode.txt")
	    level_parent->addFallout(p_.x(), p_.y())
	    GS = cast(GameSpace ptr, parent)
	    GS->vibrateScreen()
	   	this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)
	case WATER_SPLASH
	    this.head_->data_.anim.load("drip.txt")
	    this.head_->data_.anim.hardSwitch(1)
		this.head_->data_.anim.play()
		this.head_->data_.anim.setSpeed(s_)
    end select
    this.head_->data_.fx = fx
    this.head_->data_.firstDraw = 1
    
    this.numNodes += 1
end sub

sub OneShotEffects.proc_effects(t as double)
    dim as EffectNode_t ptr curNode
    dim as EffectNode_t ptr oldNode
    dim as Effect_t         cur
    
    curNode = this.head_
    while curNode <> 0
        cur = curNode->data_
        
        curNode->data_.p = curNode->data_.p + curNode->data_.v
        curNode->data_.endIt -= 1
        
        curNode->data_.anim.step_animation()
        
        if (curNode->data_.anim.done() = 1 andALso curNode->data_.isFlash = 0) orElse (curNode->data_.isFlash = 1 andAlso curNode->data_.endIt <= 0) then 
            if curNode->prev_ <> 0 then curNode->prev_->next_ = curNode->next_
            if curNode->next_ <> 0 then curNode->next_->prev_ = curNode->prev_
            if curNode = this.head_ then head_ = curNode->next_
            oldNode = curNode
            curNode = curNode->next_
            delete(oldNode)
            this.numNodes -= 1
        else
            curNode = curNode->next_
        end if
    wend 
end sub

sub OneShotEffects.setParent(par as any ptr, lev as Level ptr)
    parent = par
    level_parent = lev
end sub

sub OneShotEffects.setLink(link_ as objectLink)
	link = link_
end sub

sub OneShotEffects.draw_effects(scnbuff as uinteger ptr)
    dim as EffectNode_t ptr curNode
    dim as Effect_t         cur
    curNode = this.head_
    while curNode <> 0
        cur = curNode->data_
        
        if cur.fx = FLASH then
        	if cur.endIt >= 2 then
				circle scnbuff, (cur.p.x(), cur.p.y()), 40, rgb(255,255,128),,,,F   
			else
				circle scnbuff, (cur.p.x(), cur.p.y()), 20, rgb(0,0,0),,,,F   
			end if 
        elseif cur.fx = BLUE_FLASH then
        	if cur.endIt >= 2 then
				circle scnbuff, (cur.p.x(), cur.p.y()), 20, rgb(255,255,255),,,,F   
			else
				circle scnbuff, (cur.p.x(), cur.p.y()), 10, rgb(200,200,255),,,,F   
			end if 
        else 
      		cur.anim.drawAnimation(scnbuff, cur.p.x(), cur.p.y())
        end if
        		    

        curNode->data_.firstDraw = 0
        curNode = curNode->next_
    wend 
end sub
