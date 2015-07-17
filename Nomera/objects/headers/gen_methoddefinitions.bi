#define ITEM_ANTIPERSONNELMINE_DEFINE_BOMB_STICKYNESS 0
#define ITEM_ANTIPERSONNELMINE_DEFINE_MINE_FREEFALL_MAX 30
sub Item.ANTIPERSONNELMINE_SLOT_EXPLODE(pvPair() as _Item_slotValuePair_t)

   data_.ANTIPERSONNELMINE_DATA->death = 1

end sub
sub Item.ANTIPERSONNELMINE_PROC_INIT()
    data_.ANTIPERSONNELMINE_DATA = new ITEM_ANTIPERSONNELMINE_TYPE_DATA
    dim as integer orientation
    data_.ANTIPERSONNELMINE_DATA->body = TinyBody(p, 8, 10)
    data_.ANTIPERSONNELMINE_DATA->death = 0
    data_.ANTIPERSONNELMINE_DATA->freeFallingFrames = 0
    
    anims_n = 3
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "mines.txt")
    anims[1].load(MEDIA_PATH + "silhouette.txt")
    anims[2].load(MEDIA_PATH + "ledflash.txt")
    
    anims[0].hardSwitch(0)
    anims[1].hardSwitch(0)    
    
    if anims_n <> 0 then
        anims[2].hardSwitch(0)
        anims[0].play()
        anims[1].play()
        anims[2].play()
    end if
    data_.ANTIPERSONNELMINE_DATA->body.friction = 20
    getParameter(orientation, "orientation")
    
    select case orientation
    case 0
        data_.ANTIPERSONNELMINE_DATA->body.f = data_.ANTIPERSONNELMINE_DATA->body.f + Vector2D(0, ITEM_ANTIPERSONNELMINE_DEFINE_BOMB_STICKYNESS)
    case 1
        data_.ANTIPERSONNELMINE_DATA->body.f = data_.ANTIPERSONNELMINE_DATA->body.f + Vector2D(-ITEM_ANTIPERSONNELMINE_DEFINE_BOMB_STICKYNESS, 0)
    case 2
        data_.ANTIPERSONNELMINE_DATA->body.f = data_.ANTIPERSONNELMINE_DATA->body.f + Vector2D(0, -ITEM_ANTIPERSONNELMINE_DEFINE_BOMB_STICKYNESS)
    case 3
        data_.ANTIPERSONNELMINE_DATA->body.f = data_.ANTIPERSONNELMINE_DATA->body.f + Vector2D(ITEM_ANTIPERSONNELMINE_DEFINE_BOMB_STICKYNESS, 0)
    end select    
    data_.ANTIPERSONNELMINE_DATA->body_i = link.tinyspace_ptr->addBody(@(data_.ANTIPERSONNELMINE_DATA->body))
end sub
sub Item.ANTIPERSONNELMINE_PROC_FLUSH()
 
    link.tinyspace_ptr->removeBody(data_.ANTIPERSONNELMINE_DATA->body_i)
    if anims_n then delete(anims)
    if data_.ANTIPERSONNELMINE_DATA then delete(data_.ANTIPERSONNELMINE_DATA)
    data_.ANTIPERSONNELMINE_DATA = 0
end sub
function Item.ANTIPERSONNELMINE_PROC_RUN(t as double) as integer
    dim as integer i
    
    p = data_.ANTIPERSONNELMINE_DATA->body.p
    bounds_tl = anims[0].getOffset() + data_.ANTIPERSONNELMINE_DATA->body.p
    bounds_br = bounds_tl + Vector2D(anims[0].getWidth(), anims[0].getHeight())
    
    anims[0].step_animation()
	anims[1].step_animation()
    anims[2].step_animation()
   
    if link.tinyspace_ptr->getArbiterN(data_.ANTIPERSONNELMINE_DATA->body_i) = 0 then
        data_.ANTIPERSONNELMINE_DATA->freeFallingFrames += 1
    else
        data_.ANTIPERSONNELMINE_DATA->freeFallingFrames = 0
    end if
    
    if data_.ANTIPERSONNELMINE_DATA->death orElse (data_.ANTIPERSONNELMINE_DATA->freeFallingFrames >= ITEM_ANTIPERSONNELMINE_DEFINE_MINE_FREEFALL_MAX) then
        data_.ANTIPERSONNELMINE_DATA->death = 1 
        
        link.oneshoteffects_ptr->create(p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,1)
        link.oneshoteffects_ptr->create(p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,2)
        link.oneshoteffects_ptr->create(p + Vector2D(rnd * 64 - 32, rnd * 64 - 32),,,2)
        link.oneshoteffects_ptr->create(p + Vector2D(rnd * 64 - 32, rnd * 64 - 32),,,2)
        link.oneshoteffects_ptr->create(p, FLASH,,1)
        link.soundeffects_ptr->playSound(SND_EXPLODE)
        for i = 1 to 5
            link.projectilecollection_ptr->create(p, Vector2D(rnd*2 - 1.0, rnd*2 - 1.0) * (300 + rnd*700), DETRITIS)
        next i
        link.gamespace_ptr->vibrateScreen()
        link.level_ptr->addFallout(p.x, p.y)
        
    end if
           
    return data_.ANTIPERSONNELMINE_DATA->death

    return 0
end function
sub Item.ANTIPERSONNELMINE_PROC_DRAW(scnbuff as integer ptr)
	anims[0].drawAnimation(scnbuff, p.x, p.y)
    
end sub
sub Item.ANTIPERSONNELMINE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    dim as integer colorIndex
    dim as integer col
    
    getParameter(colorIndex, "colorIndex")
    col = getIndicatorColor(colorIndex)
    
    anims[1].setGlow(col)
    anims[1].drawAnimation(scnbuff, data_.ANTIPERSONNELMINE_DATA->body.p.x, data_.ANTIPERSONNELMINE_DATA->body.p.y)
    anims[2].drawAnimation(scnbuff, data_.ANTIPERSONNELMINE_DATA->body.p.x, data_.ANTIPERSONNELMINE_DATA->body.p.y - 16)
    colorIndex += 1
    
    addColor col, &h101010
    drawStringShadow scnbuff, data_.ANTIPERSONNELMINE_DATA->body.p.x - 20, data_.ANTIPERSONNELMINE_DATA->body.p.y - 20, iif(colorIndex < 10, str(colorIndex), "0"), col

end sub
sub Item.ANTIPERSONNELMINE_PROC_CONSTRUCT()
    _initAddSlot_("EXPLODE", ITEM_ANTIPERSONNELMINE_SLOT_EXPLODE_E)
    _initAddParameter_("ORIENTATION", _ITEM_VALUE_INTEGER)
    _initAddParameter_("COLORINDEX", _ITEM_VALUE_INTEGER)
end sub
