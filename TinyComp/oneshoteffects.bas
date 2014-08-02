#include "oneshoteffects.bi"
#include "gamespace.bi"
#include "debug.bi"

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
        deallocate(oldNode)
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
    this.head_->data_.anim.load("splode.txt")
    this.head_->data_.anim.play()
    this.head_->data_.anim.setSpeed(s_)
    
    
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
        curNode->data_.anim.step_animation()
        
        if curNode->data_.anim.done() = 1 then 
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

sub OneShotEffects.setParent(par as any ptr)
    parent = par
end sub


sub OneShotEffects.draw_effects(scnbuff as uinteger ptr)
    dim as EffectNode_t ptr curNode
    dim as Effect_t         cur
    curNode = this.head_
    while curNode <> 0
        cur = curNode->data_
        
        cur.anim.drawAnimation(scnbuff, cur.p.x(), cur.p.y())
        
        curNode = curNode->next_
    wend 
    
    
end sub
