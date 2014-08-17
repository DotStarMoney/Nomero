#include "projectilecollection.bi"
#include "gamespace.bi"
#include "debug.bi"

constructor ProjectileCollection
    this.head_ = 0
    this.numNodes = 0
    parent_space = 0
end constructor



destructor ProjectileCollection
    dim as ProjectileNode_t ptr curNode
    dim as ProjectileNode_t ptr oldNode
    dim as Projectile_t         cur
    
    curNode = this.head_
    while curNode <> 0
        cur = curNode->data_
        parent_space->removeBody(cur.body_i)
        oldNode = curNode
        curNode = curNode->next_
        deallocate(oldNode)
    wend 
    
    this.head_ = 0
    this.numNodes = 0
end destructor

sub ProjectileCollection.flush()
    dim as ProjectileNode_t ptr curNode
    dim as ProjectileNode_t ptr oldNode
    dim as Projectile_t         cur
    
    curNode = this.head_
    while curNode <> 0
        cur = curNode->data_
        parent_space->removeBody(cur.body_i)
        oldNode = curNode
        curNode = curNode->next_
        deallocate(oldNode)
    wend 
end sub

sub ProjectileCollection.setEffectsGenerator(s as OneShotEffects ptr)
    effects = s
end sub




sub ProjectileCollection.create(p_ as Vector2D, v_ as Vector2D, f_ as integer = CHERRY_BOMB)
    dim as ProjectileNode_t ptr temp
    if parent_space = 0 then exit sub
    
    temp = this.head_
    this.head_ = new ProjectileNode_t
    this.head_->prev_ = 0
    this.head_->next_ = temp
    if temp <> 0 then temp->prev_ = this.head_
    
    select case f_
    case CHERRY_BOMB
            
        this.head_->data_.body   = TinyBody(p_, 8, 10)
        this.head_->data_.body.noCollide = 0
        this.head_->data_.body.v = v_
        this.head_->data_.body_i = parent_space->addBody(@this.head_->data_.body)
        this.head_->data_.flavor = CHERRY_BOMB
        this.head_->data_.anim.load("bombanim.txt")
        this.head_->data_.anim.play()
    case DETRITIS
        this.head_->data_.body   = TinyBody(p_, 8, 10)
        this.head_->data_.body.elasticity = 1
        'this.head_->data_.body.noCollide = 1
        this.head_->data_.body.v = v_
        this.head_->data_.body_i = parent_space->addBody(@this.head_->data_.body)
        this.head_->data_.flavor = DETRITIS
        this.head_->data_.anim.load("bombanim.txt")
        this.head_->data_.anim.hardSwitch(int(rnd * 2) + 1)
        this.head_->data_.anim.play()
        this.head_->data_.lifeFrames = 10
	case WATER_DROP
	    this.head_->data_.body   = TinyBody(p_, 4, 2)
        this.head_->data_.body.noCollide = 0
        this.head_->data_.body.v = v_
        this.head_->data_.body_i = parent_space->addBody(@this.head_->data_.body)
        this.head_->data_.anim.load("drip.txt")
        this.head_->data_.anim.hardSwitch(0)
        this.head_->data_.anim.play()
        this.head_->data_.flavor = WATER_DROP
    end select
        
    this.numNodes += 1
end sub

sub ProjectileCollection.proc_collection(t as double)
    dim as ProjectileNode_t ptr curNode
    dim as ProjectileNode_t ptr oldNode
    dim as Projectile_t         cur
    dim as integer deleteMe, i
    dim as GameSpace ptr GS
    
    
    curNode = this.head_
    while curNode <> 0
        cur = curNode->data_
        deleteMe = 0
        
        select case cur.flavor
        case DETRITIS
            curNode->data_.lifeFrames -= 1
            curNode->data_.body.v = curNode->data_.body.v * 0.9
            if curNode->data_.lifeFrames < 0 then
                
                deleteMe = 1
            end if
        case WATER_DROP
			if cur.body.didCollide > 0 then 
				deleteMe = 1
				effects->create(cur.body.p, WATER_SPLASH)
			end if
        case CHERRY_BOMB
            if cur.body.didCollide > 0 then 
                
                effects->create(cur.body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,1)
                effects->create(cur.body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,2)
                effects->create(cur.body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
                effects->create(cur.body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
                
                for i = 1 to 5
                    create(cur.body.p, Vector2D(rnd*2 - 1, rnd*2 - 1) * (1 + rnd*700), DETRITIS)
                next i
                
                GS = cast(GameSpace ptr, game_space)
                GS->vibrateScreen()
        
                
                parent_level->addFallout(cur.body.p.x(), cur.body.p.y(), 1)
        
                deleteMe = 1
            end if
        end select
        if deleteMe = 1 then
            if curNode->prev_ <> 0 then curNode->prev_->next_ = curNode->next_
            if curNode->next_ <> 0 then curNode->next_->prev_ = curNode->prev_
            if curNode = this.head_ then head_ = curNode->next_
            parent_space->removeBody(cur.body_i)
            oldNode = curNode
            curNode = curNode->next_
            delete(oldNode)
            this.numNodes -= 1
        else
            curNode = curNode->next_
        end if
    wend 
end sub

sub ProjectileCollection.draw_collection(scnbuff as uinteger ptr)
    dim as ProjectileNode_t ptr curNode
    dim as Projectile_t         cur
    curNode = this.head_
    while curNode <> 0
        cur = curNode->data_
        
        select case cur.flavor
        case CHERRY_BOMB
            cur.anim.drawAnimation(scnbuff, cur.body.p.x(), cur.body.p.y())

        case DETRITIS
            cur.anim.drawAnimation(scnbuff, cur.body.p.x(), cur.body.p.y())
		case WATER_DROP
            cur.anim.drawAnimation(scnbuff, cur.body.p.x(), cur.body.p.y())
        end select
        
        
        curNode = curNode->next_
    wend 
    
    
end sub

sub ProjectileCollection.setParent(TS as TinySpace ptr, LS as Level ptr, GS as any ptr)
    parent_space = TS
    game_space = GS
    parent_level = LS
end sub
