sub Item.ACCENTLIGHT_PROC_INIT()
    data_.ACCENTLIGHT_DATA = new ITEM_ACCENTLIGHT_TYPE_DATA
    dim as integer flavor
    dim as integer fast
    dim as string  lightfn
    
    getParameter(flavor, "flavor")
    getParameter(fast, "fast")
    getParameter(data_.ACCENTLIGHT_DATA->mode, "mode")
    getParameter(data_.ACCENTLIGHT_DATA->minVal, "minValue")
    getParameter(data_.ACCENTLIGHT_DATA->maxVal, "maxValue")
    
    anims_n = 2
    anims = new Animation[anims_n]
    select case flavor
    case 0
        lightfn = "LightOrange"
    case 1
        lightfn = "PaleBlue"
    case 2
        lightfn = "RedOrange"
    case else
        lightfn = "LightOrange"
    end select

    anims[0].load(MEDIA_PATH + "Lights\" + lightfn + "_Diffuse.txt")
    anims[1].load(MEDIA_PATH + "Lights\" + lightfn + "_Specular.txt")
  
    light.texture.diffuse_fbimg = anims[0].getRawImage()
    light.texture.specular_fbimg = anims[1].getRawImage()
    light.texture.x = p.x
    light.texture.y = p.y
    light.texture.w = anims[0].getWidth()
    light.texture.h = anims[0].getHeight()
    light.shaded = light.texture
    if fast <> 65535 then
        light.shaded.diffuse_fbimg = 0
        light.shaded.specular_fbimg = 0   
        light.occlusion_fbimg = 0       
    else
        light.shaded.diffuse_fbimg = imagecreate(light.texture.w, light.texture.h)
        light.shaded.specular_fbimg = imagecreate(light.texture.w, light.texture.h)   
        light.occlusion_fbimg = imagecreate(light.texture.w, light.texture.h)
    end if
    light.last_tl_x = 0
    light.last_tl_y = 0
    light.last_br_x = light.texture.w - 1
    light.last_br_y = light.texture.h - 1    
    lightState = 1
    
end sub
sub Item.ACCENTLIGHT_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.ACCENTLIGHT_DATA then delete(data_.ACCENTLIGHT_DATA)
    data_.ACCENTLIGHT_DATA = 0
end sub
function Item.ACCENTLIGHT_PROC_RUN(t as double) as integer
    
    return 0
end function
sub Item.ACCENTLIGHT_PROC_DRAW(scnbuff as integer ptr)

end sub
sub Item.ACCENTLIGHT_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.ACCENTLIGHT_PROC_CONSTRUCT()
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
    _initAddParameter_("MINVALUE", _ITEM_VALUE_DOUBLE)
    _initAddParameter_("MAXVALUE", _ITEM_VALUE_DOUBLE)
    _initAddParameter_("MODE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("FAST", _ITEM_VALUE_INTEGER)
end sub
sub Item.ALIENSPINNER_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)

end sub
sub Item.ALIENSPINNER_PROC_INIT()
    data_.ALIENSPINNER_DATA = new ITEM_ALIENSPINNER_TYPE_DATA
    anims_n = 6
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "alienspinner.txt")
    anims[0].hardSwitch(3)
    anims[1].load(MEDIA_PATH + "alienspinner.txt")
    anims[1].hardSwitch(2)
    anims[1].play()
    anims[2].load(MEDIA_PATH + "alienspinner.txt")
    anims[2].hardSwitch(0)
    anims[3].load(MEDIA_PATH + "alienspinner.txt")
    anims[3].hardSwitch(1)   
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\Cyan_Diffuse.txt", MEDIA_PATH + "Lights\Cyan_Specular.txt", 4, 5, 0)  

    data_.ALIENSPINNER_DATA->curFrame = 0
    data_.ALIENSPINNER_DATA->delay = int(rnd * 60) + 30
    data_.ALIENSPINNER_DATA->transitType = 1
    
    data_.ALIENSPINNER_DATA->lightUFO = 0
    data_.ALIENSPINNER_DATA->scrollLights = 1
    data_.ALIENSPINNER_DATA->scrollLightsDelay = 0
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 64)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.ALIENSPINNER_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.ALIENSPINNER_DATA then delete(data_.ALIENSPINNER_DATA)
    data_.ALIENSPINNER_DATA = 0
end sub
function Item.ALIENSPINNER_PROC_RUN(t as double) as integer
    dim as integer nextDir

    anims[1].step_animation()
    if anims[1].done() andALso data_.ALIENSPINNER_DATA->scrollLights = 1 then 
        data_.ALIENSPINNER_DATA->scrollLights = 0
        data_.ALIENSPINNER_DATA->scrollLightsDelay = 60
    end if
    if data_.ALIENSPINNER_DATA->scrollLightsDelay > 0 then data_.ALIENSPINNER_DATA->scrollLightsDelay -= 1
    if data_.ALIENSPINNER_DATA->scrollLightsDelay <= 0 andALso data_.ALIENSPINNER_DATA->scrollLights = 0 then
        data_.ALIENSPINNER_DATA->scrollLights = 1
        anims[1].restart()
        anims[1].play()
    end if
    
    if data_.ALIENSPINNER_DATA->transitType = 1 then
        if data_.ALIENSPINNER_DATA->delay <= 0 then
            nextDir = data_.ALIENSPINNER_DATA->transitType
            if data_.ALIENSPINNER_DATA->curFrame = 3 then
                data_.ALIENSPINNER_DATA->delay = int(rnd * 120) + 60
                data_.ALIENSPINNER_DATA->transitType = -1
            else
                data_.ALIENSPINNER_DATA->delay = 3
            end if
            data_.ALIENSPINNER_DATA->curFrame += nextDir
        else
            data_.ALIENSPINNER_DATA->delay -= 1
        end if
    elseif data_.ALIENSPINNER_DATA->transitType = -1 then
        if data_.ALIENSPINNER_DATA->delay <= 0 then
            nextDir = data_.ALIENSPINNER_DATA->transitType
            if data_.ALIENSPINNER_DATA->curFrame = 1 then
                data_.ALIENSPINNER_DATA->delay = int(rnd * 120) + 60
                data_.ALIENSPINNER_DATA->transitType = 1
            else
                data_.ALIENSPINNER_DATA->delay = 3
            end if
            data_.ALIENSPINNER_DATA->curFrame += nextDir
        else
            data_.ALIENSPINNER_DATA->delay -= 1
        end if        
    end if
    
    if (data_.ALIENSPINNER_DATA->curFrame > 0 andAlso data_.ALIENSPINNER_DATA->curFrame < 4) orElse (data_.ALIENSPINNER_DATA->delay > 60) then
        if (int(rnd * 60) < 5) then 
            data_.ALIENSPINNER_DATA->lightUFO = 0
        else
            data_.ALIENSPINNER_DATA->lightUFO = 1
        end if
    else
        data_.ALIENSPINNER_DATA->lightUFO = 0
    end if
    
    lightState = data_.ALIENSPINNER_DATA->lightUFO
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + 8 + data_.ALIENSPINNER_DATA->curFrame * 3
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
   
    return 0
end function
sub Item.ALIENSPINNER_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()

    DRAW_LIT_ANIMATION(0, p.x, p.y + 32, 0, 1)
    if data_.ALIENSPINNER_DATA->scrollLights then anims[1].drawAnimation(scnbuff, p.x, p.y + 32,,,ANIM_GLOW)
    anims[2].drawImageLit(scnbuff, p.x, p.y, data_.ALIENSPINNER_DATA->curFrame*32, 0, data_.ALIENSPINNER_DATA->curFrame*32 + 31, 31,_
                          lights, numLights, link.level_ptr->getHiddenObjectAmbientLevel(),,,1,ANIM_TRANS)
    if data_.ALIENSPINNER_DATA->lightUFO then 
        anims[3].drawImageLit(scnbuff, p.x, p.y, 160 + data_.ALIENSPINNER_DATA->curFrame*32, 0, data_.ALIENSPINNER_DATA->curFrame*32 + 191, 31,_
                              lights, numLights, link.level_ptr->getHiddenObjectAmbientLevel(),,,,ANIM_GLOW)
    end if
end sub
sub Item.ALIENSPINNER_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.ALIENSPINNER_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_ALIENSPINNER_SLOT_INTERACT_E)
end sub
#define ITEM_ANTIPERSONNELMINE_DEFINE_BOMB_STICKYNESS 0
#define ITEM_ANTIPERSONNELMINE_DEFINE_MINE_FREEFALL_MAX 30
sub Item.ANTIPERSONNELMINE_SLOT_EXPLODE(pvPair() as _Item_slotValuePair_t)
    dim as integer i

    if data_.ANTIPERSONNELMINE_DATA->death = 0 then
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
        link.gamespace_ptr->setShakeStyle(0)
        link.gamespace_ptr->vibrateScreen()
        link.level_ptr->addFallout(p.x, p.y)
    end if
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
    anims[2].hardSwitch(0)
    
    anims[0].play()
    anims[1].play()
    anims[2].play()

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
    
    p = data_.ANTIPERSONNELMINE_DATA->body.p
    bounds_tl = anims[0].getOffset() + p
    bounds_br = bounds_tl + Vector2D(anims[0].getWidth(), anims[0].getHeight())
    
    anims[0].step_animation()
	anims[1].step_animation()
    anims[2].step_animation()
   
    if link.tinyspace_ptr->getArbiterN(data_.ANTIPERSONNELMINE_DATA->body_i) = 0 then
        data_.ANTIPERSONNELMINE_DATA->freeFallingFrames += 1
    else
        data_.ANTIPERSONNELMINE_DATA->freeFallingFrames = 0
    end if
    
    if (data_.ANTIPERSONNELMINE_DATA->death = 0) andAlso (data_.ANTIPERSONNELMINE_DATA->freeFallingFrames >= ITEM_ANTIPERSONNELMINE_DEFINE_MINE_FREEFALL_MAX) then fireSlot("explode")
           
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
    anims[1].drawAnimation(scnbuff, p.x, p.y)
    anims[2].drawAnimation(scnbuff, p.x, p.y - 16)
    colorIndex += 1
    
    addColor col, &h101010
    drawStringShadow scnbuff, p.x - 20, p.y - 20, iif(colorIndex < 10, str(colorIndex), "0"), col

end sub
sub Item.ANTIPERSONNELMINE_PROC_CONSTRUCT()
    _initAddSlot_("EXPLODE", ITEM_ANTIPERSONNELMINE_SLOT_EXPLODE_E)
    _initAddParameter_("ORIENTATION", _ITEM_VALUE_INTEGER)
    _initAddParameter_("COLORINDEX", _ITEM_VALUE_INTEGER)
end sub
sub Item.BIGOSCILLOSCOPE_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    data_.BIGOSCILLOSCOPE_DATA->dontDraw = 1 - data_.BIGOSCILLOSCOPE_DATA->dontDraw
end sub
sub Item.BIGOSCILLOSCOPE_PROC_INIT()
    data_.BIGOSCILLOSCOPE_DATA = new ITEM_BIGOSCILLOSCOPE_TYPE_DATA
    dim as integer flavor
    dim as integer i
    dim as integer steps

    getParameter(flavor, "flavor")

    anims_n = 2
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "bigoscilloscope.txt")
    anims[0].play()
    
    anims[1].load(MEDIA_PATH + "bigoscilloscope.txt")
    anims[1].play()      
    
    if flavor = 1 then
        anims[1].hardSwitch(2)
    else
        anims[1].hardSwitch(1)
    end if
    steps = int(rnd * 30)
    for i = 0 to steps: anims[0].step_animation(): next i
    data_.BIGOSCILLOSCOPE_DATA->dontDraw = 0
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(64, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.BIGOSCILLOSCOPE_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.BIGOSCILLOSCOPE_DATA then delete(data_.BIGOSCILLOSCOPE_DATA)
    data_.BIGOSCILLOSCOPE_DATA = 0
end sub
function Item.BIGOSCILLOSCOPE_PROC_RUN(t as double) as integer
    anims[0].step_animation()    
    return 0
end function
sub Item.BIGOSCILLOSCOPE_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()

    DRAW_LIT_ANIMATION(1, p.x, p.y, 0, 0)            
    if data_.BIGOSCILLOSCOPE_DATA->dontDraw = 0 then anims[0].drawAnimation(scnbuff, p.x, p.y,,,ANIM_GLOW)
end sub
sub Item.BIGOSCILLOSCOPE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.BIGOSCILLOSCOPE_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_BIGOSCILLOSCOPE_SLOT_INTERACT_E)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
end sub
#define ITEM_COVERSMOKE_DEFINE_LIFETIME 300
#define ITEM_COVERSMOKE_DEFINE_DAMPING_MAX 0.95
sub Item.COVERSMOKE_PROC_INIT()
    data_.COVERSMOKE_DATA = new ITEM_COVERSMOKE_TYPE_DATA
    dim as integer isSolid
    dim as Vector2D initVelocity
    
    data_.COVERSMOKE_DATA->body = TinyBody(p, 16, 10)
    data_.COVERSMOKE_DATA->body_i = -1
    data_.COVERSMOKE_DATA->lifeFrames = ITEM_COVERSMOKE_DEFINE_LIFETIME
    data_.COVERSMOKE_DATA->driftVelocity = 0
    data_.COVERSMOKE_DATA->driftForce = 0
    data_.COVERSMOKE_DATA->animSpeed = 1
    
    anims_n = 1
    anims = new Animation[anims_n]   
    anims[0].load(MEDIA_PATH + "coversmoke.txt")
    anims[0].play()
                
    getParameter(isSolid, "isSolid")
    if isSolid then
        data_.COVERSMOKE_DATA->body_i = link.tinyspace_ptr->addBody(@(data_.COVERSMOKE_DATA->body))
    else
        data_.COVERSMOKE_DATA->body.noCollide = 1
        data_.COVERSMOKE_DATA->driftForce = 1700
    end if
    
    getParameter(initVelocity, "initVelocity")
    data_.COVERSMOKE_DATA->body.v = initVelocity

    
    data_.COVERSMOKE_DATA->body.friction = 0
    data_.COVERSMOKE_DATA->body.elasticity = 0.4+rnd*0.3
    
end sub
sub Item.COVERSMOKE_PROC_FLUSH()
    if data_.COVERSMOKE_DATA->body_i <> -1 then link.tinyspace_ptr->removeBody(data_.COVERSMOKE_DATA->body_i)
    if anims_n then delete(anims)
    if data_.COVERSMOKE_DATA then delete(data_.COVERSMOKE_DATA)
    data_.COVERSMOKE_DATA = 0
end sub
function Item.COVERSMOKE_PROC_RUN(t as double) as integer
    dim as integer isSolid
    
    anims[0].setSpeed(data_.COVERSMOKE_DATA->animSpeed)
    anims[0].step_animation()
    
    
    data_.COVERSMOKE_DATA->body.f = Vector2D(0, -data_.COVERSMOKE_DATA->body.m * DEFAULT_GRAV) * (0.7 + ((data_.COVERSMOKE_DATA->driftForce / 10000.0)^(2))*0.3)
    data_.COVERSMOKE_DATA->body.v = data_.COVERSMOKE_DATA->body.v * ((ITEM_COVERSMOKE_DEFINE_DAMPING_MAX - 1) * (data_.COVERSMOKE_DATA->driftVelocity / 10000.0) + 1)
    
    if data_.COVERSMOKE_DATA->body.v.magnitude() < 2.0 then data_.COVERSMOKE_DATA->body.noCollide = 1 
    
    getParameter(isSolid, "isSolid")
    if isSolid = 0 then
        data_.COVERSMOKE_DATA->body.v = data_.COVERSMOKE_DATA->body.v + ((Vector2D(0, data_.COVERSMOKE_DATA->body.m * DEFAULT_GRAV) + data_.COVERSMOKE_DATA->body.f) / data_.COVERSMOKE_DATA->body.m) * t
        data_.COVERSMOKE_DATA->body.p = data_.COVERSMOKE_DATA->body.p + data_.COVERSMOKE_DATA->body.v*t
    end if
    
    
    if data_.COVERSMOKE_DATA->body.didCollide then 
        data_.COVERSMOKE_DATA->body.v *= 0.75
        data_.COVERSMOKE_DATA->body.didCollide = 0
    end if
    
    p = data_.COVERSMOKE_DATA->body.p
     
    LOCK_TO_SCREEN()
        anims[0].drawAnimation(link.level_ptr->getSmokeTexture(), p.x, p.y,,,,-link.gamespace_ptr->camera + Vector2D(SCRX*0.5, SCRY*0.5))
    UNLOCK_TO_SCREEN()
    
    data_.COVERSMOKE_DATA->driftForce += 100
    data_.COVERSMOKE_DATA->driftVelocity += 10
    data_.COVERSMOKE_DATA->lifeFrames -= 1
    if data_.COVERSMOKE_DATA->driftForce > 10000    then data_.COVERSMOKE_DATA->driftForce = 10000
    if data_.COVERSMOKE_DATA->driftVelocity > 10000 then data_.COVERSMOKE_DATA->driftVelocity = 10000
    if anims[0].done then 
        return 1
    end if
    return 0
end function
sub Item.COVERSMOKE_PROC_DRAW(scnbuff as integer ptr)
    
end sub
sub Item.COVERSMOKE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.COVERSMOKE_PROC_CONSTRUCT()
    _initAddParameter_("ISSOLID", _ITEM_VALUE_INTEGER)
    _initAddParameter_("INITVELOCITY", _ITEM_VALUE_VECTOR2D)
end sub
sub Item.DEEPSPOTLIGHT_SLOT_ENABLE(pvPair() as _Item_slotValuePair_t)
    
    setParameter(0, "disable")
end sub
sub Item.DEEPSPOTLIGHT_PROC_INIT()
    
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "lightflare.txt")

    
end sub
sub Item.DEEPSPOTLIGHT_PROC_FLUSH()

    if anims_n then delete(anims)
end sub
function Item.DEEPSPOTLIGHT_PROC_RUN(t as double) as integer


    return 0
end function
sub Item.DEEPSPOTLIGHT_PROC_DRAW(scnbuff as integer ptr)
    dim as integer disable
    getParameter(disable, "disable")
    if disable = 0 then        
        anims[0].setGlow(&h9fffffff)
        anims[0].drawAnimation(scnbuff, drawX, drawY)
        pset scnbuff, (drawX, drawY), &hffff00ff
    end if
end sub
sub Item.DEEPSPOTLIGHT_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    dim as integer col, glow
    dim as integer disable
    getParameter(disable, "disable")
    if disable = 0 then
        if drawX > link.gamespace_ptr->camera.x - SCRX*0.5 andAlso drawX < link.gamespace_ptr->camera.x + SCRX*0.5 then
            if drawY > link.gamespace_ptr->camera.y - SCRY*0.5 andAlso drawY < link.gamespace_ptr->camera.y + SCRY*0.5 then
                col = point(drawX, drawY, scnbuff)
                if col = &hfefe00fe then 
                    col = &hffffffff
                else
                    col = 0
                end if
                glow = (col shr 24) and &hff
        
                anims[0].setGlow((glow shl 24) or &h00ffffff)
                anims[0].drawAnimation(scnbuff, drawX, drawY)
            end if
        end if
    end if
end sub
sub Item.DEEPSPOTLIGHT_PROC_CONSTRUCT()
    _initAddSlot_("ENABLE", ITEM_DEEPSPOTLIGHT_SLOT_ENABLE_E)
    _initAddParameter_("DISABLE", _ITEM_VALUE_INTEGER)
end sub
#define ITEM_ELECTRICMINE_DEFINE_MAX_RAYCAST_ATTEMPTS 10
#define ITEM_ELECTRICMINE_DEFINE_RAYCAST_DIST 80
#define ITEM_ELECTRICMINE_DEFINE_RUN_TIME 50
#define ITEM_ELECTRICMINE_DEFINE_BOMB_STICKYNESS 0
#define ITEM_ELECTRICMINE_DEFINE_MINE_FREEFALL_MAX 30
sub Item.ELECTRICMINE_SLOT_EXPLODE(pvPair() as _Item_slotValuePair_t)
    dim as integer i, targetMember
    dim as double randAngle, dist, minDist
    dim as Vector2D v, pt, btl, bbr, centroid, destP
    dim as Vector2D minCentroid, minTL, minBR
    dim as Shape2D ptr shape
    dim as ObjectSlotSet targets
    
    if data_.ELECTRICMINE_DATA->death = 0 then
        data_.ELECTRICMINE_DATA->death = 1
        link.oneshoteffects_ptr->create(p, ELECTRIC_FLASH,,1)
        link.soundeffects_ptr->playSound(SND_EXPLODE_3)
        link.soundeffects_ptr->playSound(SND_ARC)
        anims[0].hardSwitch(2)
        
        querySlots(targets, "shock target", @Circle2D(Vector2D(p.x, p.y), ITEM_ELECTRICMINE_DEFINE_RAYCAST_DIST))
        
        minDist = ITEM_ELECTRICMINE_DEFINE_RAYCAST_DIST + 1
        targetMember = -1
        for i = 0 to targets.getMember_N() - 1
            targets.getGeometry(shape, i)
            shape->getBoundingBox(btl, bbr)
            centroid = (btl + bbr) * 0.5
            dist = (centroid - p).magnitude()
            if dist < minDist then
                minTL = btl
                minBR = bbr
                minDist = dist
                targetMember = i
                minCentroid = centroid
            end if
        next i
        if targetMember <> -1 then
            targets.throwMember(targetMember)
            data_.ELECTRICMINE_DATA->arcs_n = int(rnd * 2) + 1
            
            for i = 0 to data_.ELECTRICMINE_DATA->arcs_n - 1
                centroid = Vector2D((minBR.x - minTL.x), (minBR.y - minTL.y)) / Sqr(2)
                destP = Vector2D(centroid.x * rnd, centroid.y * rnd) - centroid*0.5 + minCentroid
          
                data_.ELECTRICMINE_DATA->arcs[i].arcID = link.electricarc_ptr->create()
                data_.ELECTRICMINE_DATA->arcs[i].bPos = (Vector2D(0,rnd)-Vector2D(0,0.5))*10 - Vector2D(1,4)
                data_.ELECTRICMINE_DATA->arcs[i].endPos = destP
                link.electricarc_ptr->setPoints(data_.ELECTRICMINE_DATA->arcs[i].arcID, p + data_.ELECTRICMINE_DATA->arcs[i].bPos, data_.ELECTRICMINE_DATA->arcs[i].endPos)                
            next i
        end if
            
        if data_.ELECTRICMINE_DATA->arcs_n < 4 then
            for i = 0 to ITEM_ELECTRICMINE_DEFINE_MAX_RAYCAST_ATTEMPTS - 1
                randAngle = rnd*(_PI_*2)
                if targetMember = -1 then
                    v = Vector2D(cos(randAngle), sin(randAngle))*ITEM_ELECTRICMINE_DEFINE_RAYCAST_DIST
                else
                    v = Vector2D(cos(randAngle), sin(randAngle))*ITEM_ELECTRICMINE_DEFINE_RAYCAST_DIST*0.25
                end if
                dist = link.tinyspace_ptr->raycast(p, v, pt)
                if dist >= 0 then
               
                    data_.ELECTRICMINE_DATA->arcs[data_.ELECTRICMINE_DATA->arcs_n].arcID = link.electricarc_ptr->create()
                    data_.ELECTRICMINE_DATA->arcs[data_.ELECTRICMINE_DATA->arcs_n].bPos = (Vector2D(0,rnd)-Vector2D(0,0.5))*10 - Vector2D(1,4)
                    data_.ELECTRICMINE_DATA->arcs[data_.ELECTRICMINE_DATA->arcs_n].endPos = pt
                    link.electricarc_ptr->setPoints(data_.ELECTRICMINE_DATA->arcs[data_.ELECTRICMINE_DATA->arcs_n].arcID, p + data_.ELECTRICMINE_DATA->arcs[data_.ELECTRICMINE_DATA->arcs_n].bPos, pt)

                    data_.ELECTRICMINE_DATA->arcs_n += 1
                    if data_.ELECTRICMINE_DATA->arcs_n = 4 then exit for
                end if
            next i
        end if
        
        data_.ELECTRICMINE_DATA->deathFrames = ITEM_ELECTRICMINE_DEFINE_RUN_TIME
    end if
end sub
sub Item.ELECTRICMINE_PROC_INIT()
    data_.ELECTRICMINE_DATA = new ITEM_ELECTRICMINE_TYPE_DATA
    dim as integer orientation
    data_.ELECTRICMINE_DATA->body = TinyBody(p, 8, 10)
    data_.ELECTRICMINE_DATA->death = 0
    data_.ELECTRICMINE_DATA->freeFallingFrames = 0
    data_.ELECTRICMINE_DATA->death = 0
    data_.ELECTRICMINE_DATA->deathFrames = 0
    
    data_.ELECTRICMINE_DATA->arcs_n = 0
    data_.ELECTRICMINE_DATA->arcs = new ITEM_ELECTRICMINE_TYPE_ElectricMine_ArcData_t[4]
    
    anims_n = 3
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "mines.txt")
    anims[1].load(MEDIA_PATH + "silhouette.txt")
    anims[2].load(MEDIA_PATH + "ledflash.txt")
    
    anims[0].hardSwitch(1)
    anims[1].hardSwitch(1)    
    anims[2].hardSwitch(0)
    
    anims[0].play()
    anims[1].play()
    anims[2].play()

    data_.ELECTRICMINE_DATA->body.friction = 20
    getParameter(orientation, "orientation")
    
    select case orientation
    case 0
        data_.ELECTRICMINE_DATA->body.f = data_.ELECTRICMINE_DATA->body.f + Vector2D(0, ITEM_ELECTRICMINE_DEFINE_BOMB_STICKYNESS)
    case 1
        data_.ELECTRICMINE_DATA->body.f = data_.ELECTRICMINE_DATA->body.f + Vector2D(-ITEM_ELECTRICMINE_DEFINE_BOMB_STICKYNESS, 0)
    case 2
        data_.ELECTRICMINE_DATA->body.f = data_.ELECTRICMINE_DATA->body.f + Vector2D(0, -ITEM_ELECTRICMINE_DEFINE_BOMB_STICKYNESS)
    case 3
        data_.ELECTRICMINE_DATA->body.f = data_.ELECTRICMINE_DATA->body.f + Vector2D(ITEM_ELECTRICMINE_DEFINE_BOMB_STICKYNESS, 0)
    end select    
    data_.ELECTRICMINE_DATA->body_i = link.tinyspace_ptr->addBody(@(data_.ELECTRICMINE_DATA->body))
end sub
sub Item.ELECTRICMINE_PROC_FLUSH()
    if data_.ELECTRICMINE_DATA->arcs then delete(data_.ELECTRICMINE_DATA->arcs)
    link.tinyspace_ptr->removeBody(data_.ELECTRICMINE_DATA->body_i)
    if anims_n then delete(anims)
    if data_.ELECTRICMINE_DATA then delete(data_.ELECTRICMINE_DATA)
    data_.ELECTRICMINE_DATA = 0
end sub
function Item.ELECTRICMINE_PROC_RUN(t as double) as integer
    dim as integer i
    
    p = data_.ELECTRICMINE_DATA->body.p
    bounds_tl = anims[0].getOffset() + p
    bounds_br = bounds_tl + Vector2D(anims[0].getWidth(), anims[0].getHeight())
    
    anims[0].step_animation()
	anims[1].step_animation()
    anims[2].step_animation()
   
    if link.tinyspace_ptr->getArbiterN(data_.ELECTRICMINE_DATA->body_i) = 0 then
        data_.ELECTRICMINE_DATA->freeFallingFrames += 1
    else
        data_.ELECTRICMINE_DATA->freeFallingFrames = 0
    end if
    
    if (data_.ELECTRICMINE_DATA->death = 0) andAlso (data_.ELECTRICMINE_DATA->freeFallingFrames >= ITEM_ELECTRICMINE_DEFINE_MINE_FREEFALL_MAX) then fireSlot("explode")
           
           
    if data_.ELECTRICMINE_DATA->death then
        data_.ELECTRICMINE_DATA->deathFrames -= 1
        if data_.ELECTRICMINE_DATA->arcs_n > 0 then
            for i = 0 to data_.ELECTRICMINE_DATA->arcs_n - 1
                link.electricarc_ptr->setPoints(data_.ELECTRICMINE_DATA->arcs[i].arcID, p + data_.ELECTRICMINE_DATA->arcs[i].bPos, data_.ELECTRICMINE_DATA->arcs[i].endPos)
            next i
        end if
    
        if data_.ELECTRICMINE_DATA->deathFrames <= 0 then
            if data_.ELECTRICMINE_DATA->arcs_n > 0 then
                for i = 0 to data_.ELECTRICMINE_DATA->arcs_n - 1
                    link.electricarc_ptr->destroy(data_.ELECTRICMINE_DATA->arcs[i].arcID)
                next i
            end if  
                
            link.oneshoteffects_ptr->create(p, BLUE_FLASH,,1)
            return 1       
        end if
    end if

    return 0
end function
sub Item.ELECTRICMINE_PROC_DRAW(scnbuff as integer ptr)
	anims[0].drawAnimation(scnbuff, p.x, p.y)
    
end sub
sub Item.ELECTRICMINE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    dim as integer colorIndex
    dim as integer col
    
    if data_.ELECTRICMINE_DATA->death = 0 then
        getParameter(colorIndex, "colorIndex")
        col = getIndicatorColor(colorIndex)
        
        anims[1].setGlow(col)
        anims[1].drawAnimation(scnbuff, p.x, p.y)
        anims[2].drawAnimation(scnbuff, p.x - 1, p.y - 14)
        colorIndex += 1
        
        addColor col, &h101010
        drawStringShadow scnbuff, p.x - 20, p.y - 20, iif(colorIndex < 10, str(colorIndex), "0"), col
    end if
end sub
sub Item.ELECTRICMINE_PROC_CONSTRUCT()
    _initAddSlot_("EXPLODE", ITEM_ELECTRICMINE_SLOT_EXPLODE_E)
    _initAddParameter_("ORIENTATION", _ITEM_VALUE_INTEGER)
    _initAddParameter_("COLORINDEX", _ITEM_VALUE_INTEGER)
end sub
sub Item.togglePath()
    link.soundeffects_ptr->playSound(SND_SELECT)
    data_.FREIGHTELEVATOR_DATA->gearSound = link.soundeffects_ptr->playSound(SND_GEARS)
    data_.FREIGHTELEVATOR_DATA->platformLow->togglePath()
    data_.FREIGHTELEVATOR_DATA->platformHi->togglePath()
end sub
sub Item.FREIGHTELEVATOR_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    togglePath()
end sub
sub Item.FREIGHTELEVATOR_PROC_INIT()
    data_.FREIGHTELEVATOR_DATA = new ITEM_FREIGHTELEVATOR_TYPE_DATA
    dim as TinyDynamic_BASICPATH pathData
    dim as Vector2D path(0 to 1) 
    dim as Vector2D shape(0 to 4)
    
    data_.FREIGHTELEVATOR_DATA->lastState = 0
    
    path(1) = p 
    path(0) = p + Vector2D(0, size.y - 96)
    
    pathData.pathPointsN = 2
    pathData.pathPoints = @(path(0))
    pathData.type_ = TOGGLE
    pathData.speed = 80
    pathData.segment = 0    
    pathData.segment_pos = 0
        
    data_.FREIGHTELEVATOR_DATA->platformHi = new TinyDynamic(DYNA_BASICPATH)
    data_.FREIGHTELEVATOR_DATA->platformLow = new TinyDynamic(DYNA_BASICPATH)
    data_.FREIGHTELEVATOR_DATA->platformHi->importParams(@pathData)
    data_.FREIGHTELEVATOR_DATA->platformLow->importParams(@pathData)
    
    shape(0) = Vector2D(0,0)
    shape(1) = Vector2D(96, 0)
    shape(2) = Vector2D(96, 9)
    shape(3) = Vector2D(0, 9)
    shape(4) = shape(0)
    data_.FREIGHTELEVATOR_DATA->platformHi->importShape(@(shape(0)), 5)
    shape(0) = Vector2D(0,80)
    shape(1) = Vector2D(96, 80)
    shape(2) = Vector2D(96, 96)
    shape(3) = Vector2D(0, 96)
    shape(4) = shape(0)
    data_.FREIGHTELEVATOR_DATA->platformLow->importShape(@(shape(0)), 5)
    data_.FREIGHTELEVATOR_DATA->platformHi->calcBB()
    data_.FREIGHTELEVATOR_DATA->platformLow->calcBB()
    data_.FREIGHTELEVATOR_DATA->platformHi->activate()
    data_.FREIGHTELEVATOR_DATA->platformLow->activate()
    
    data_.FREIGHTELEVATOR_DATA->platformHi_i = link.tinyspace_ptr->addDynamic(data_.FREIGHTELEVATOR_DATA->platformHi)
    data_.FREIGHTELEVATOR_DATA->platformLow_i = link.tinyspace_ptr->addDynamic(data_.FREIGHTELEVATOR_DATA->platformLow)
    
    anims_n = 4
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "elevator.txt")
    anims[0].play()
    anims[1].load(MEDIA_PATH + "elevator.txt")
    anims[1].hardSwitch(1)
    anims[1].play()
    anims[2].load(MEDIA_PATH + "elevator2.txt")
    anims[3].load(MEDIA_PATH + "elevator2.txt")
    anims[3].hardSwitch(1)
    anims[3].play()
    
    setValue(0, "interact")
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(50,32), Vector2D(70, 52)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
    _initAddValue_("INTERACT", _ITEM_VALUE_INTEGER)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "INTERACT")
end sub
sub Item.FREIGHTELEVATOR_PROC_FLUSH()
    
    link.tinyspace_ptr->removeDynamic(data_.FREIGHTELEVATOR_DATA->platformLow_i)  
    link.tinyspace_ptr->removeDynamic(data_.FREIGHTELEVATOR_DATA->platformHi_i)    
    delete(data_.FREIGHTELEVATOR_DATA->platformHi)
    delete(data_.FREIGHTELEVATOR_DATA->platformLow)
    if anims_n then delete(anims)
    if data_.FREIGHTELEVATOR_DATA then delete(data_.FREIGHTELEVATOR_DATA)
    data_.FREIGHTELEVATOR_DATA = 0
end sub
function Item.FREIGHTELEVATOR_PROC_RUN(t as double) as integer
    data_.FREIGHTELEVATOR_DATA->elevatorPos = data_.FREIGHTELEVATOR_DATA->platformHi->getPointP(0)
    
    DControl->setTargetSlotOffset(ID, "interact", data_.FREIGHTELEVATOR_DATA->elevatorPos) 
    if data_.FREIGHTELEVATOR_DATA->platformHi->getToggleState > 1 then
        setValue(-1, "interact")
        anims[3].play()
    else
        if data_.FREIGHTELEVATOR_DATA->lastState > 1 then 
            link.soundeffects_ptr->playSound(SND_COLLIDE)
            link.soundeffects_ptr->stopSound(data_.FREIGHTELEVATOR_DATA->gearSound)            
        end if
        setValue(0, "interact")
        anims[3].pause()
    end if
    
    data_.FREIGHTELEVATOR_DATA->lastState = data_.FREIGHTELEVATOR_DATA->platformHi->getToggleState
    
    anims[3].step_animation()
    
    return 0
end function
sub Item.FREIGHTELEVATOR_PROC_DRAW(scnbuff as integer ptr)
    dim as integer interact
    dim as Vector2D startPos
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION_BRIGHT(0, data_.FREIGHTELEVATOR_DATA->elevatorPos.x, data_.FREIGHTELEVATOR_DATA->elevatorPos.y, 0, 0)
    
    getValue(interact, "interact")
    if interact = 0 then anims[1].drawAnimation(scnbuff, data_.FREIGHTELEVATOR_DATA->elevatorPos.x + 55, data_.FREIGHTELEVATOR_DATA->elevatorPos.y + 36)
    
    startPos = vector2d(data_.FREIGHTELEVATOR_DATA->elevatorPos.x, _min_(data_.FREIGHTELEVATOR_DATA->elevatorPos.y - 16, link.gamespace_ptr->camera.y + SCRY*0.5 - 16))
    while startPos.y > (link.gamespace_ptr->camera.y - SCRY*0.5 - 16)
        if startPos.y > p.y then 
            anims[2].setClippingBoundaries(0,0,0,0)
            DRAW_LIT_ANIMATION(2, startPos.x, startPos.y, 0, 0)
            startPos.ys -= 16
        else
            anims[2].setClippingBoundaries(0,p.y - startPos.y,0,0)
            DRAW_LIT_ANIMATION(2, startPos.x, p.y, 0, 0)            
            exit while
        end if
    wend 
    
    DRAW_LIT_ANIMATION(3, data_.FREIGHTELEVATOR_DATA->elevatorPos.x, data_.FREIGHTELEVATOR_DATA->elevatorPos.y - 32, 0, 0)

end sub
sub Item.FREIGHTELEVATOR_PROC_DRAWOVERLAY(scnbuff as integer ptr)

    
end sub
sub Item.FREIGHTELEVATOR_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_FREIGHTELEVATOR_SLOT_INTERACT_E)
    _initAddParameter_("STARTSIDE", _ITEM_VALUE_INTEGER)
end sub
sub Item.FREQUENCYCOUNTER_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)

end sub
sub Item.FREQUENCYCOUNTER_PROC_INIT()
    data_.FREQUENCYCOUNTER_DATA = new ITEM_FREQUENCYCOUNTER_TYPE_DATA
    dim as integer flavor
    
    getParameter(flavor, "flavor")

    anims_n = 2
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "freqcounter.txt")
    anims[0].play()
    
    anims[1].load(MEDIA_PATH + "freqcounter.txt")
    anims[1].play()      
    if flavor = 1 then
        anims[1].hardSwitch(2)
    else
        anims[1].hardSwitch(1)    
    end if

    data_.FREQUENCYCOUNTER_DATA->cycleState = 0
    data_.FREQUENCYCOUNTER_DATA->cycleTime = int(rnd * 60) + 30
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.FREQUENCYCOUNTER_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.FREQUENCYCOUNTER_DATA then delete(data_.FREQUENCYCOUNTER_DATA)
    data_.FREQUENCYCOUNTER_DATA = 0
end sub
function Item.FREQUENCYCOUNTER_PROC_RUN(t as double) as integer
    data_.FREQUENCYCOUNTER_DATA->cycleTime -= 1
    if data_.FREQUENCYCOUNTER_DATA->cycleTime <= 0 then
        data_.FREQUENCYCOUNTER_DATA->cycleState = 1 - data_.FREQUENCYCOUNTER_DATA->cycleState
        if data_.FREQUENCYCOUNTER_DATA->cycleState = 0 then
            data_.FREQUENCYCOUNTER_DATA->cycleTime = int(rnd * 120) + 30
        else
            data_.FREQUENCYCOUNTER_DATA->cycleTime = 2
        end if
    end if
    return 0
end function
sub Item.FREQUENCYCOUNTER_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()

    DRAW_LIT_ANIMATION(1, p.x, p.y, 0, 0)            
    if data_.FREQUENCYCOUNTER_DATA->cycleState = 0 then anims[0].drawAnimation(scnbuff, p.x, p.y,,,ANIM_GLOW)
end sub
sub Item.FREQUENCYCOUNTER_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.FREQUENCYCOUNTER_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_FREQUENCYCOUNTER_SLOT_INTERACT_E)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
end sub
sub Item.INTERFACE_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)

    data_.INTERFACE_DATA->dontDraw = 1 - data_.INTERFACE_DATA->dontDraw
end sub
sub Item.INTERFACE_PROC_INIT()
    data_.INTERFACE_DATA = new ITEM_INTERFACE_TYPE_DATA

    anims_n = 3
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "interface.txt")
    anims[0].play()
    anims[1].load(MEDIA_PATH + "interface.txt")
    anims[1].play()       
    anims[1].hardSwitch(1)
    anims[2].load(MEDIA_PATH + "interface.txt")
    anims[2].play()       
    anims[2].hardSwitch(2)
    
    data_.INTERFACE_DATA->dontDraw = 0
    data_.INTERFACE_DATA->cycleState = 0
    data_.INTERFACE_DATA->cycleTime = int(rnd * 10) + 10
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.INTERFACE_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.INTERFACE_DATA then delete(data_.INTERFACE_DATA)
    data_.INTERFACE_DATA = 0
end sub
function Item.INTERFACE_PROC_RUN(t as double) as integer
    data_.INTERFACE_DATA->cycleTime -= 1
    if data_.INTERFACE_DATA->cycleTime <= 0 then
        data_.INTERFACE_DATA->cycleTime = int(rnd * 10) + 10
        data_.INTERFACE_DATA->cycleState = 1 - data_.INTERFACE_DATA->cycleState
    end if
    return 0
end function
sub Item.INTERFACE_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()

    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0) 
    if data_.INTERFACE_DATA->dontDraw = 0 then
        anims[1].drawAnimation(scnbuff, p.x, p.y)
        if data_.INTERFACE_DATA->cycleState then anims[2].drawAnimation(scnbuff, p.x, p.y)
    end if
end sub
sub Item.INTERFACE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.INTERFACE_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_INTERFACE_SLOT_INTERACT_E)
end sub
sub Item.MOMENTARYTOGGLESWITCH_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    if data_.MOMENTARYTOGGLESWITCH_DATA->toggleCycle = 0 then
        data_.MOMENTARYTOGGLESWITCH_DATA->toggleCycle = 30
        link.soundeffects_ptr->playSound(SND_CLACKUP)
        anims[1].play()
        anims[2].play()    
        throw("ACTIVATE")
    end if
end sub
sub Item.MOMENTARYTOGGLESWITCH_PROC_INIT()
    data_.MOMENTARYTOGGLESWITCH_DATA = new ITEM_MOMENTARYTOGGLESWITCH_TYPE_DATA
    data_.MOMENTARYTOGGLESWITCH_DATA->toggleCycle = 0
    
    anims_n = 3
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "switch.txt")
    anims[1].load(MEDIA_PATH + "switch.txt")
    anims[1].hardSwitch(1)
    anims[2].load(MEDIA_PATH + "switch.txt")
    anims[2].hardSwitch(2)
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 48)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.MOMENTARYTOGGLESWITCH_PROC_FLUSH()
 
    if anims_n then delete(anims)
    if data_.MOMENTARYTOGGLESWITCH_DATA then delete(data_.MOMENTARYTOGGLESWITCH_DATA)
    data_.MOMENTARYTOGGLESWITCH_DATA = 0
end sub
function Item.MOMENTARYTOGGLESWITCH_PROC_RUN(t as double) as integer
    anims[1].step_animation()
    anims[2].step_animation()
    
    if data_.MOMENTARYTOGGLESWITCH_DATA->toggleCycle > 0 then
        data_.MOMENTARYTOGGLESWITCH_DATA->toggleCycle -= 1
        if data_.MOMENTARYTOGGLESWITCH_DATA->toggleCycle = 1 then link.soundeffects_ptr->playSound(SND_CLACKDOWN)
    else
        anims[1].restart()
        anims[2].restart()    
    end if
    return 0
end function
sub Item.MOMENTARYTOGGLESWITCH_PROC_DRAW(scnbuff as integer ptr)
    dim as integer facing, flags
    PREP_LIT_ANIMATION()
    
    flags = 0
    getParameter(facing, "facing")
    if facing = -1 then 
        flags = 0
    elseif facing = 1 then
        flags = 4
    end if
    
    DRAW_LIT_ANIMATION(0, p.x, p.y + 16, flags, 0)
    DRAW_LIT_ANIMATION(1, p.x, p.y, flags, 0)
    anims[2].drawAnimation(scnbuff, p.x, p.y,,flags)
end sub
sub Item.MOMENTARYTOGGLESWITCH_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.MOMENTARYTOGGLESWITCH_PROC_CONSTRUCT()
    _initAddSignal_("ACTIVATE")
    _initAddSlot_("INTERACT", ITEM_MOMENTARYTOGGLESWITCH_SLOT_INTERACT_E)
    _initAddParameter_("FACING", _ITEM_VALUE_INTEGER)
end sub
#define ITEM_PUZZLETUBE1_DEFINE_MAX_BUBBLES 20
sub Item.doBubbles(t as double)
    dim as integer i
    if int(rnd * 10) = 0 then
        for i = 0 to ITEM_PUZZLETUBE1_DEFINE_MAX_BUBBLES - 1
            if data_.PUZZLETUBE1_DATA->bubbles[i].exists = 0 then
                data_.PUZZLETUBE1_DATA->bubbles[i].exists = 1
                data_.PUZZLETUBE1_DATA->bubbles[i].p = p + Vector2D(10 + int(rnd * (size.x - 20)), size.y - int(rnd * 8) - 8)
                data_.PUZZLETUBE1_DATA->bubbles[i].v = Vector2D(0, -3)
                data_.PUZZLETUBE1_DATA->bubbles[i].size = int(rnd * 2) + 1
                exit for
            end if
        next i
    end if
    for i = 0 to ITEM_PUZZLETUBE1_DEFINE_MAX_BUBBLES - 1
        if data_.PUZZLETUBE1_DATA->bubbles[i].exists = 1 then
            data_.PUZZLETUBE1_DATA->bubbles[i].p += data_.PUZZLETUBE1_DATA->bubbles[i].v + vector2D(int(rnd * 3) - 1, 0)
            if data_.PUZZLETUBE1_DATA->bubbles[i].p.x < p.x + 10 then 
                data_.PUZZLETUBE1_DATA->bubbles[i].p.xs = p.x + 10
            elseif data_.PUZZLETUBE1_DATA->bubbles[i].p.x > p.x + size.x - 10 then 
                data_.PUZZLETUBE1_DATA->bubbles[i].p.xs =  p.x + size.x - 10
            end if
            if data_.PUZZLETUBE1_DATA->bubbles[i].p.y < (p.y + data_.PUZZLETUBE1_DATA->drawLevel + 15) then data_.PUZZLETUBE1_DATA->bubbles[i].exists = 0
        end if    
    next i
end sub
sub Item.PUZZLETUBE1_SLOT_ACTIVATE(pvPair() as _Item_slotValuePair_t)
    dim as integer amount
    matchParameter(amount, "AMOUNT", pvPair())
    if data_.PUZZLETUBE1_DATA->isLocked = 0 then data_.PUZZLETUBE1_DATA->targetLevel += amount
end sub
sub Item.PUZZLETUBE1_SLOT_RESET(pvPair() as _Item_slotValuePair_t)
    if data_.PUZZLETUBE1_DATA->isLocked = 0 then data_.PUZZLETUBE1_DATA->targetLevel = 0
end sub
sub Item.PUZZLETUBE1_SLOT_LOCKUP(pvPair() as _Item_slotValuePair_t)
    data_.PUZZLETUBE1_DATA->isLocked = 1
end sub
sub Item.PUZZLETUBE1_SLOT_SETUP(pvPair() as _Item_slotValuePair_t)
    dim as integer startLevel
    matchParameter(startLevel, "STARTLEVEL", pvPair())
    data_.PUZZLETUBE1_DATA->targetLevel = startLevel
end sub
sub Item.PUZZLETUBE1_PROC_INIT()
    data_.PUZZLETUBE1_DATA = new ITEM_PUZZLETUBE1_TYPE_DATA
    dim as integer i

    data_.PUZZLETUBE1_DATA->tubeLevel = 0
    data_.PUZZLETUBE1_DATA->targetLevel = 0
    data_.PUZZLETUBE1_DATA->isLocked = 0
    data_.PUZZLETUBE1_DATA->bubbles = new ITEM_PUZZLETUBE1_TYPE_bubble_t[ITEM_PUZZLETUBE1_DEFINE_MAX_BUBBLES]
    for i = 0 to ITEM_PUZZLETUBE1_DEFINE_MAX_BUBBLES - 1
        data_.PUZZLETUBE1_DATA->bubbles[i].exists = 0
    next i

    setValue(0, "level")
    
    
    CREATE_ANIMS(3)
    anims[0].load(MEDIA_PATH + "teleportertubes.txt")
    anims[1].load(MEDIA_PATH + "teleportertubes.txt")
    anims[1].hardSwitch(1)
    anims[2].load(MEDIA_PATH + "teleportertubes.txt")
    anims[2].hardSwitch(2)    
    

    _initAddValue_("LEVEL", _ITEM_VALUE_INTEGER)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "LEVEL")
end sub
sub Item.PUZZLETUBE1_PROC_FLUSH()
    delete(data_.PUZZLETUBE1_DATA->bubbles)
    if anims_n then delete(anims)
    if data_.PUZZLETUBE1_DATA then delete(data_.PUZZLETUBE1_DATA)
    data_.PUZZLETUBE1_DATA = 0
end sub
function Item.PUZZLETUBE1_PROC_RUN(t as double) as integer
        
    if abs(data_.PUZZLETUBE1_DATA->tubeLevel - data_.PUZZLETUBE1_DATA->targetLevel) > 0.09 then
        if data_.PUZZLETUBE1_DATA->tubeLevel < data_.PUZZLETUBE1_DATA->targetLevel then
            data_.PUZZLETUBE1_DATA->tubeLevel += 0.1
        elseif data_.PUZZLETUBE1_DATA->tubeLevel > data_.PUZZLETUBE1_DATA->targetLevel then
            data_.PUZZLETUBE1_DATA->tubeLevel -= 0.1    
        end if
    else
        setValue(data_.PUZZLETUBE1_DATA->targetLevel, "level")
    end if
    if data_.PUZZLETUBE1_DATA->tubeLevel > 20.0000001 then          
        data_.PUZZLETUBE1_DATA->tubeLevel = 20
        data_.PUZZLETUBE1_DATA->targetLevel = 0
        throw("FAILURE")
    end if
    doBubbles(t)
    return 0
end function
sub Item.PUZZLETUBE1_PROC_DRAW(scnbuff as integer ptr)
    dim as integer i
    
    data_.PUZZLETUBE1_DATA->drawLevel = 142 - data_.PUZZLETUBE1_DATA->tubeLevel * (142.0 / 20.0)
    anims[1].setClippingBoundaries(0, 16 + data_.PUZZLETUBE1_DATA->drawLevel, 0, 0)
    anims[1].drawAnimation(scnbuff, p.x, 17 + p.y + data_.PUZZLETUBE1_DATA->drawLevel,,,ANIM_TRANS)
    anims[1].setClippingBoundaries(0, 0, 0, 175)
    anims[1].drawAnimation(scnbuff, p.x, p.y + data_.PUZZLETUBE1_DATA->drawLevel,,,ANIM_TRANS)
    
    for i = 0 to ITEM_PUZZLETUBE1_DEFINE_MAX_BUBBLES - 1
        if data_.PUZZLETUBE1_DATA->bubbles[i].exists = 1 then
            circle scnbuff, (data_.PUZZLETUBE1_DATA->bubbles[i].p.x, data_.PUZZLETUBE1_DATA->bubbles[i].p.y), data_.PUZZLETUBE1_DATA->bubbles[i].size, rgb(110,180,255),,,,F
        end if
    next i
  
    bitblt_addRGBA_Clip(scnbuff, p.x - link.gamespace_ptr->camera.x + SCRX*0.5, p.y - link.gamespace_ptr->camera.y + SCRY*0.5, anims[2].getRawImage, 96, 0, 143, 191)   
    anims[0].drawAnimation(scnbuff, p.x, p.y,,,ANIM_TRANS)
end sub
sub Item.PUZZLETUBE1_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.PUZZLETUBE1_PROC_CONSTRUCT()
    _initAddSignal_("FAILURE")
    _initAddSlot_("ACTIVATE", ITEM_PUZZLETUBE1_SLOT_ACTIVATE_E)
    _initAddSlot_("RESET", ITEM_PUZZLETUBE1_SLOT_RESET_E)
    _initAddSlot_("LOCKUP", ITEM_PUZZLETUBE1_SLOT_LOCKUP_E)
    _initAddSlot_("SETUP", ITEM_PUZZLETUBE1_SLOT_SETUP_E)
end sub
sub Item.initializeTubes()
    dim as integer i
    if data_.PUZZLE1234_DATA->hasInit = 0 then
        data_.PUZZLE1234_DATA->hasInit = 1
        for i = 0 to 3
            fireExternalSlot(*(data_.PUZZLE1234_DATA->tubeIDs[i]), "setup", "startLevel = " + str(data_.PUZZLE1234_DATA->startValues[i]))                    
        next i        
    end if
end sub
sub Item.PUZZLE1234_SLOT_RESET(pvPair() as _Item_slotValuePair_t)
    if data_.PUZZLE1234_DATA->complete = 0 then
        data_.PUZZLE1234_DATA->curValue = data_.PUZZLE1234_DATA->startValue
        data_.PUZZLE1234_DATA->hasInit = 0
    end if
end sub
sub Item.PUZZLE1234_SLOT_CYCLE(pvPair() as _Item_slotValuePair_t)
    dim as integer target
    matchParameter(target, "TARGET", pvPair())
    dim as string tubeID
    if data_.PUZZLE1234_DATA->complete = 0 then
        if target < 1 orElse target > 4 then target = 1
        fireExternalSlot(*(data_.PUZZLE1234_DATA->tubeIDs[target - 1]), "activate", "amount = " + str(data_.PUZZLE1234_DATA->curValue + 1))
        data_.PUZZLE1234_DATA->curValue = (data_.PUZZLE1234_DATA->curValue + 1) mod 4
    end if
end sub
sub Item.PUZZLE1234_PROC_INIT()
    data_.PUZZLE1234_DATA = new ITEM_PUZZLE1234_TYPE_DATA
    dim as integer i
    dim as string tubeName
    
    data_.PUZZLE1234_DATA->startValue = 0
    data_.PUZZLE1234_DATA->complete = 0
    
    data_.PUZZLE1234_DATA->startValues = new integer[4]
    data_.PUZZLE1234_DATA->startValues[0] = 16 
    data_.PUZZLE1234_DATA->startValues[1] = 14 
    data_.PUZZLE1234_DATA->startValues[2] = 10 
    data_.PUZZLE1234_DATA->startValues[3] = 10 
    
    data_.PUZZLE1234_DATA->values = new integer[4]
    data_.PUZZLE1234_DATA->values[0] = 1
    data_.PUZZLE1234_DATA->values[1] = 2
    data_.PUZZLE1234_DATA->values[2] = 3
    data_.PUZZLE1234_DATA->values[3] = 4
    data_.PUZZLE1234_DATA->hasInit = 0
    
    data_.PUZZLE1234_DATA->curValue = data_.PUZZLE1234_DATA->startValue
    
    
    anims_n = 1
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "nixie.txt")
    
    data_.PUZZLE1234_DATA->tubeIDs = new zstring ptr[4]
    
    for i = 0 to 3
        getParameter(tubeName, "tubeID" + str(i + 1))
        data_.PUZZLE1234_DATA->tubeIDs[i] = allocate(len(tubeName) + 1)
        *(data_.PUZZLE1234_DATA->tubeIDs[i]) = tubeName
    next i
    
    _initAddValue_("CURCYCLE", _ITEM_VALUE_INTEGER)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "CURCYCLE")
end sub
sub Item.PUZZLE1234_PROC_FLUSH()
    dim as integer i
    for i = 0 to 3
        deallocate(data_.PUZZLE1234_DATA->tubeIDs[i])
    next i
    delete(data_.PUZZLE1234_DATA->tubeIDs)
    delete(data_.PUZZLE1234_DATA->values)
    delete(data_.PUZZLE1234_DATA->tubeIDs)
    if anims_n then delete(anims)
    if data_.PUZZLE1234_DATA then delete(data_.PUZZLE1234_DATA)
    data_.PUZZLE1234_DATA = 0
end sub
function Item.PUZZLE1234_PROC_RUN(t as double) as integer
    dim as integer total, i, curLevel
    
    initializeTubes()
    
    total = 0
    for i = 0 to 3
        getOtherValue(curLevel, *(data_.PUZZLE1234_DATA->tubeIDs[i]), "level")        
        total += curLevel
    next i
    if total = 80 andAlso data_.PUZZLE1234_DATA->complete = 0 then
        data_.PUZZLE1234_DATA->complete = 1
        data_.PUZZLE1234_DATA->completeDance = 94
        data_.PUZZLE1234_DATA->curValue = 0
        for i = 0 to 3
            fireExternalSlot(*(data_.PUZZLE1234_DATA->tubeIDs[i]), "lockUp")        
        next i    
        throw("SOLVED")
        link.soundeffects_ptr->playSound(SND_SUCCESS)
        
        
    end if
    if data_.PUZZLE1234_DATA->completeDance > 0 then 
        data_.PUZZLE1234_DATA->completeDance -= 1
        if (data_.PUZZLE1234_DATA->completeDance mod 4) = 0 then data_.PUZZLE1234_DATA->curValue = (data_.PUZZLE1234_DATA->curValue + 1) mod 4
    end if
    if data_.PUZZLE1234_DATA->completeDance = 0 andAlso data_.PUZZLE1234_DATA->complete = 1 then data_.PUZZLE1234_DATA->curValue = -1
    return 0
end function
sub Item.PUZZLE1234_PROC_DRAW(scnbuff as integer ptr)
    dim as integer posX, posY, frame
    dim as integer i
    dim as zimage ptr nimage
    PREP_LIT_ANIMATION()
    for i = 0 to 3
       
        frame = data_.PUZZLE1234_DATA->values[i]
        if i <> data_.PUZZLE1234_DATA->curValue then frame = 36
        
        posX = (frame * 16) mod 320
        posY = int((frame * 16) / 320) * 32
        if data_.PUZZLE1234_DATA->curValue = i then
            nimage = anims[0].getRawZImage()
            nimage->putTRANS(scnbuff, p.x + i*16, p.y, posX, posY, posX+15, posY+31)  
        else
            anims[0].drawImageLit(scnbuff, p.x + i*16, p.y, posX, posY, posX+15, posY+31,_
                                 lights, numLights, link.level_ptr->getObjectAmbientLevel())   
        end if
 
    next i
    for i = 0 to 3
        if data_.PUZZLE1234_DATA->curValue = i then nimage->putGLOW(scnbuff, p.x + i*16 - 16, p.y - 5, 272, 32, 319, 63, &hFFFFFFFF)
    next i
end sub
sub Item.PUZZLE1234_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.PUZZLE1234_PROC_CONSTRUCT()
    _initAddSignal_("SOLVED")
    _initAddSlot_("RESET", ITEM_PUZZLE1234_SLOT_RESET_E)
    _initAddSlot_("CYCLE", ITEM_PUZZLE1234_SLOT_CYCLE_E)
    _initAddParameter_("TUBEID1", _ITEM_VALUE_ZSTRING)
    _initAddParameter_("TUBEID2", _ITEM_VALUE_ZSTRING)
    _initAddParameter_("TUBEID3", _ITEM_VALUE_ZSTRING)
    _initAddParameter_("TUBEID4", _ITEM_VALUE_ZSTRING)
end sub
sub Item.SHOCKTARGET1_SLOT_SHOCKTARGET(pvPair() as _Item_slotValuePair_t)
    throw("ACTIVATE")
    data_.SHOCKTARGET1_DATA->cycleTime = 50
    anims[1].play()
end sub
sub Item.SHOCKTARGET1_PROC_INIT()
    data_.SHOCKTARGET1_DATA = new ITEM_SHOCKTARGET1_TYPE_DATA

    data_.SHOCKTARGET1_DATA->cycleTime = 0
    
    anims_n = 5
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "pawn.txt")
    anims[1].load(MEDIA_PATH + "pawn.txt")
    anims[1].hardSwitch(1)
    anims[2].load(MEDIA_PATH + "pawn.txt")
    anims[2].hardSwitch(2)    
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\SmallWhite_Diffuse.txt", MEDIA_PATH + "Lights\SmallWhite_Specular.txt", 3, 4, 0)  

    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    fastLight = 0
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "SHOCK TARGET", "SHOCKTARGET", new Circle2D(Vector2D(24,19), 5))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "SHOCK TARGET", p)
end sub
sub Item.SHOCKTARGET1_PROC_FLUSH()
 
    if anims_n then delete(anims)
    if data_.SHOCKTARGET1_DATA then delete(data_.SHOCKTARGET1_DATA)
    data_.SHOCKTARGET1_DATA = 0
end sub
function Item.SHOCKTARGET1_PROC_RUN(t as double) as integer
    
    anims[1].step_animation()

    if data_.SHOCKTARGET1_DATA->cycleTime > 0 then 
        if data_.SHOCKTARGET1_DATA->cycleTime >= 45 then
            link.projectilecollection_ptr->create(Vector2D(p.x + 24, p.y + 19), Vector2D((rnd * 2 - 1), (rnd * 2 - 1)) * 200, SPARK)
            link.projectilecollection_ptr->create(Vector2D(p.x + 24, p.y + 19), Vector2D((rnd * 2 - 1), (rnd * 2 - 1)) * 200, SPARK)
        end if
        if (data_.SHOCKTARGET1_DATA->cycleTime shr 1) and 1 then
            lightState = 1
        else
            lightState = 0
        end if
        data_.SHOCKTARGET1_DATA->cycleTime -= 1
    else
        anims[1].restart()
    end if
    return 0
end function
sub Item.SHOCKTARGET1_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
    
    if anims[1].getFrame() = 0 then
        DRAW_LIT_ANIMATION_BRIGHT(1, p.x, p.y, 0, 0)
    else
        anims[1].drawAnimation(scnbuff, p.x, p.y,,,ANIM_TRANS)
        anims[2].drawAnimation(scnbuff, p.x, p.y)
    end if
end sub
sub Item.SHOCKTARGET1_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.SHOCKTARGET1_PROC_CONSTRUCT()
    _initAddSignal_("ACTIVATE")
    _initAddSlot_("SHOCKTARGET", ITEM_SHOCKTARGET1_SLOT_SHOCKTARGET_E)
end sub
sub Item.SMALLOSCILLOSCOPE_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    data_.SMALLOSCILLOSCOPE_DATA->dontDraw = 1 - data_.SMALLOSCILLOSCOPE_DATA->dontDraw
end sub
sub Item.SMALLOSCILLOSCOPE_PROC_INIT()
    data_.SMALLOSCILLOSCOPE_DATA = new ITEM_SMALLOSCILLOSCOPE_TYPE_DATA
    dim as integer i
    dim as integer steps

    anims_n = 2
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "smallscope.txt")
    anims[0].play()
    
    anims[1].load(MEDIA_PATH + "smallscope.txt")
    anims[1].play()      

    anims[1].hardSwitch(1)
    steps = int(rnd * 30)
    for i = 0 to steps: anims[0].step_animation(): next i
    data_.SMALLOSCILLOSCOPE_DATA->dontDraw = 0
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.SMALLOSCILLOSCOPE_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.SMALLOSCILLOSCOPE_DATA then delete(data_.SMALLOSCILLOSCOPE_DATA)
    data_.SMALLOSCILLOSCOPE_DATA = 0
end sub
function Item.SMALLOSCILLOSCOPE_PROC_RUN(t as double) as integer
    anims[0].step_animation()    
    return 0
end function
sub Item.SMALLOSCILLOSCOPE_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()

    DRAW_LIT_ANIMATION(1, p.x, p.y, 0, 0)            
    if data_.SMALLOSCILLOSCOPE_DATA->dontDraw = 0 then anims[0].drawAnimation(scnbuff, p.x, p.y,,,ANIM_GLOW)
end sub
sub Item.SMALLOSCILLOSCOPE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.SMALLOSCILLOSCOPE_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_SMALLOSCILLOSCOPE_SLOT_INTERACT_E)
end sub
#define ITEM_SMOKEMINE_DEFINE_BOMB_STICKYNESS 0
#define ITEM_SMOKEMINE_DEFINE_MINE_FREEFALL_MAX 30
#define ITEM_SMOKEMINE_DEFINE_RELEASE_TIME 150
sub Item.SMOKEMINE_SLOT_EXPLODE(pvPair() as _Item_slotValuePair_t)
    if data_.SMOKEMINE_DATA->death = 0 then
        data_.SMOKEMINE_DATA->death = 1
        link.soundeffects_ptr->playSound(SND_EXPLODE_4)
    end if
end sub
sub Item.SMOKEMINE_PROC_INIT()
    data_.SMOKEMINE_DATA = new ITEM_SMOKEMINE_TYPE_DATA
    dim as integer orientation
    data_.SMOKEMINE_DATA->body = TinyBody(p, 8, 10)
    data_.SMOKEMINE_DATA->death = 0
    data_.SMOKEMINE_DATA->freeFallingFrames = 0
    
    anims_n = 4
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "mines.txt")
    anims[1].load(MEDIA_PATH + "silhouette.txt")
    anims[2].load(MEDIA_PATH + "ledflash.txt")
    anims[3].load(MEDIA_PATH + "smokerel.txt")

    anims[0].hardSwitch(3)
    anims[1].hardSwitch(2)    
    anims[2].hardSwitch(0)
    
    anims[0].play()
    anims[1].play()
    anims[2].play()
    anims[3].play()

    data_.SMOKEMINE_DATA->body.friction = 20
    data_.SMOKEMINE_DATA->dyingFrames = 0
    getParameter(orientation, "orientation")
    
    select case orientation
    case 0
        data_.SMOKEMINE_DATA->body.f = data_.SMOKEMINE_DATA->body.f + Vector2D(0, ITEM_SMOKEMINE_DEFINE_BOMB_STICKYNESS)
    case 1
        data_.SMOKEMINE_DATA->body.f = data_.SMOKEMINE_DATA->body.f + Vector2D(-ITEM_SMOKEMINE_DEFINE_BOMB_STICKYNESS, 0)
    case 2
        data_.SMOKEMINE_DATA->body.f = data_.SMOKEMINE_DATA->body.f + Vector2D(0, -ITEM_SMOKEMINE_DEFINE_BOMB_STICKYNESS)
    case 3
        data_.SMOKEMINE_DATA->body.f = data_.SMOKEMINE_DATA->body.f + Vector2D(ITEM_SMOKEMINE_DEFINE_BOMB_STICKYNESS, 0)
    end select    
    data_.SMOKEMINE_DATA->body_i = link.tinyspace_ptr->addBody(@(data_.SMOKEMINE_DATA->body))
end sub
sub Item.SMOKEMINE_PROC_FLUSH()
    link.tinyspace_ptr->removeBody(data_.SMOKEMINE_DATA->body_i)
    if anims_n then delete(anims)
    if data_.SMOKEMINE_DATA then delete(data_.SMOKEMINE_DATA)
    data_.SMOKEMINE_DATA = 0
end sub
function Item.SMOKEMINE_PROC_RUN(t as double) as integer
    dim as integer i
    dim as item ptr curItem
    
    p = data_.SMOKEMINE_DATA->body.p
    bounds_tl = anims[0].getOffset() + p
    bounds_br = bounds_tl + Vector2D(anims[0].getWidth(), anims[0].getHeight())
    
    anims[0].step_animation()
	anims[1].step_animation()
    anims[2].step_animation()
   
    if link.tinyspace_ptr->getArbiterN(data_.SMOKEMINE_DATA->body_i) = 0 then
        data_.SMOKEMINE_DATA->freeFallingFrames += 1
    else
        data_.SMOKEMINE_DATA->freeFallingFrames = 0
    end if
    
    if data_.SMOKEMINE_DATA->death = 0 then
        if data_.SMOKEMINE_DATA->freeFallingFrames >= ITEM_SMOKEMINE_DEFINE_MINE_FREEFALL_MAX then fireSlot("explode")
    else
        data_.SMOKEMINE_DATA->dyingFrames += 1
        anims[3].step_animation()
        if (data_.SMOKEMINE_DATA->dyingFrames mod 2) = 0 then 
            curItem = DControl->constructItem(DControl->itemStringToType("coversmoke"))
            
            curItem->setParameter(data_.SMOKEMINE_DATA->dyingFrames mod 4, "isSolid")
            curItem->setParameter(Vector2D(((2.0*rnd) - 1.0)*80.0, -100 - rnd*25), "initVelocity")
        
            DControl->initItem(curItem, p + Vector2D(0, -100 + data_.SMOKEMINE_DATA->dyingFrames*0.25))
        end if
        if data_.SMOKEMINE_DATA->dyingFrames = ITEM_SMOKEMINE_DEFINE_RELEASE_TIME - 4 then link.oneshoteffects_ptr->create(p, SMOKE,,1)
        if data_.SMOKEMINE_DATA->dyingFrames >= ITEM_SMOKEMINE_DEFINE_RELEASE_TIME then return 1
    end if

    return 0
end function
sub Item.SMOKEMINE_PROC_DRAW(scnbuff as integer ptr)
	anims[0].drawAnimation(scnbuff, p.x, p.y)
end sub
sub Item.SMOKEMINE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    dim as integer colorIndex
    dim as integer col
    dim as integer value
    
    if data_.SMOKEMINE_DATA->death = 0 then
        getParameter(colorIndex, "colorIndex")
        col = getIndicatorColor(colorIndex)  
        anims[1].setGlow(col)
        anims[1].drawAnimation(scnbuff, p.x, p.y)
        anims[2].drawAnimation(scnbuff, p.x - 1, p.y - 16)
        colorIndex += 1       
        addColor col, &h101010
        drawStringShadow scnbuff, p.x - 20, p.y - 20, iif(colorIndex < 10, str(colorIndex), "0"), col
    else 
        value = 50 + (ITEM_SMOKEMINE_DEFINE_RELEASE_TIME - data_.SMOKEMINE_DATA->dyingFrames)*2
        if value > 255 then value = 255
        value = ((value/255.0)^0.5)*255
        anims[3].setGlow(&h00ffffff or (value shl 24))
        anims[3].drawAnimation(scnbuff, p.x-2, p.y-7)     
    end if
        
end sub
sub Item.SMOKEMINE_PROC_CONSTRUCT()
    _initAddSlot_("EXPLODE", ITEM_SMOKEMINE_SLOT_EXPLODE_E)
    _initAddParameter_("ORIENTATION", _ITEM_VALUE_INTEGER)
    _initAddParameter_("COLORINDEX", _ITEM_VALUE_INTEGER)
end sub
sub Item.TANDY2000_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)

end sub
sub Item.TANDY2000_PROC_INIT()
    dim as integer flavor
    dim as integer i
    dim as integer steps
    
    getParameter(flavor, "flavor")

    anims_n = 2
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "tandy2000.txt")
    anims[0].play()
    anims[0].hardSwitch(2)
    anims[1].load(MEDIA_PATH + "tandy2000.txt")
    anims[1].play()     
    
    if flavor = 1 then
        anims[1].hardSwitch(1)
    else
        anims[1].hardSwitch(0)
    end if
    
    steps = int(rnd * 30)
    for i = 0 to steps: anims[0].step_animation(): next i
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.TANDY2000_PROC_FLUSH()

    if anims_n then delete(anims)
end sub
function Item.TANDY2000_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    return 0
end function
sub Item.TANDY2000_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()

    DRAW_LIT_ANIMATION(1, p.x, p.y, 0, 0)            
    anims[0].drawAnimation(scnbuff, p.x, p.y) 
end sub
sub Item.TANDY2000_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.TANDY2000_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_TANDY2000_SLOT_INTERACT_E)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
end sub
sub Item.setAmbientLevels(glowAmount as integer, subAmountPlayer as integer, subAmountUnlit as integer)
    dim as integer col
    dim as integer i
    dim as integer layersN
    col = link.level_ptr->getObjectAmbientLevel()
    subColor(col, subAmountUnlit)
    link.level_ptr->setObjectAmbientLevel(col)
    col = link.level_ptr->getHiddenObjectAmbientLevel()
    subColor(col, subAmountPlayer)
    link.level_ptr->setHiddenObjectAmbientLevel(col)   
    for i = 0 to link.level_ptr->getLayerN() - 1
        link.level_ptr->setGlow(i, glowAmount)
        col = link.level_ptr->getAmbientLevel(i)
        subColor(col, subAmountUnlit)
        link.level_ptr->setAmbientLevel(i, col)
    next i
end sub
sub Item.TELEPORTERREVEALSEQUENCE_SLOT_START(pvPair() as _Item_slotValuePair_t)
    link.level_ptr->fadeMistOut()
    link.gamespace_ptr->lockAction = 1
    link.gamespace_ptr->fadeMusicOut()
    data_.TELEPORTERREVEALSEQUENCE_DATA->enable = 1
    data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 0
end sub
sub Item.TELEPORTERREVEALSEQUENCE_PROC_INIT()
    data_.TELEPORTERREVEALSEQUENCE_DATA = new ITEM_TELEPORTERREVEALSEQUENCE_TYPE_DATA
    dim as string revealTag
    dim as string hideTag
    dim as integer i
    data_.TELEPORTERREVEALSEQUENCE_DATA->enable = 0
    data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 0
  
  
    data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets = new integer[4]
    data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent = new integer[4]
    
    for i = 0 to 3
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[i] = 0
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] = 0
    next i
   
  
    getParameter(hideTag, "hideLayers")
    getParameter(revealTag, "showLayers")

  
    link.level_ptr->getGroup(hideTag, data_.TELEPORTERREVEALSEQUENCE_DATA->hideLayers)
    link.level_ptr->getGroup(revealTag, data_.TELEPORTERREVEALSEQUENCE_DATA->revealLayers)
    
   
end sub
sub Item.TELEPORTERREVEALSEQUENCE_PROC_FLUSH()
    if data_.TELEPORTERREVEALSEQUENCE_DATA->hideLayers then delete(data_.TELEPORTERREVEALSEQUENCE_DATA->hideLayers)
    if data_.TELEPORTERREVEALSEQUENCE_DATA->revealLayers then delete(data_.TELEPORTERREVEALSEQUENCE_DATA->revealLayers)
    delete(data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets)
    delete(data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent)
    if anims_n then delete(anims)
    if data_.TELEPORTERREVEALSEQUENCE_DATA then delete(data_.TELEPORTERREVEALSEQUENCE_DATA)
    data_.TELEPORTERREVEALSEQUENCE_DATA = 0
end sub
function Item.TELEPORTERREVEALSEQUENCE_PROC_RUN(t as double) as integer
    dim as integer i
    if data_.TELEPORTERREVEALSEQUENCE_DATA->enable then data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame += 1
    
    if data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 125 then
        link.soundeffects_ptr->playSound(SND_RUMBLE)
    elseif data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 130 then
        link.gamespace_ptr->vibrateScreen(510)
    elseif data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 250 then 
        

        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[3] = &hff
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[2] = &h7f
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[1] = &h4f
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[0] = &h10
        link.soundeffects_ptr->playSound(SND_POW)
        
        setAmbientLevels(&hffffffff, &h00020203, &h00020203)

  
    elseif data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 370 then

        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[2] = &hff
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[1] = &h7f
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[0] = &h46
        link.soundeffects_ptr->playSound(SND_POW)

        setAmbientLevels(&hffffffff, &h00040406, &h00040406)

    elseif data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 490 then
    
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[1] = &hff
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[0] = &h4F
        link.soundeffects_ptr->playSound(SND_POW)
        
        setAmbientLevels(&hffffffff, &h00000000, &h00000000)

    
    elseif data_.TELEPORTERREVEALSEQUENCE_DATA->countFrame = 640 then
    
        data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[0] = &hff
        link.soundeffects_ptr->playSound(SND_POW)
        link.gamespace_ptr->lockAction = 0
        throw("ENDSEQUENCE")
        
        setAmbientLevels(&hff000000, &h00ffffff, &h00ffffff)

    end if
    
    for i = 0 to 3
        if data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] < data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[i] then data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] += 45
        if data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] > data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[i] then data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] = data_.TELEPORTERREVEALSEQUENCE_DATA->glowTargets[i]
        if data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] = 0 then
            link.level_ptr->setHide(data_.TELEPORTERREVEALSEQUENCE_DATA->revealLayers[i])
        else
            link.level_ptr->setUnhide(data_.TELEPORTERREVEALSEQUENCE_DATA->revealLayers[i])
        end if
        if data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] = 255 then
            link.level_ptr->setHide(data_.TELEPORTERREVEALSEQUENCE_DATA->hideLayers[i])
        else
            link.level_ptr->setUnhide(data_.TELEPORTERREVEALSEQUENCE_DATA->hideLayers[i])
        end if
        link.level_ptr->setGlow(data_.TELEPORTERREVEALSEQUENCE_DATA->revealLayers[i], (data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i] shl 24) or ((data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i]) shl 16) or ((data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i]) shl 8) or ((data_.TELEPORTERREVEALSEQUENCE_DATA->glowCurrent[i])))
    next i
    
    return 0
end function
sub Item.TELEPORTERREVEALSEQUENCE_PROC_DRAW(scnbuff as integer ptr)
   
end sub
sub Item.TELEPORTERREVEALSEQUENCE_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.TELEPORTERREVEALSEQUENCE_PROC_CONSTRUCT()
    _initAddSignal_("ENDSEQUENCE")
    _initAddSlot_("START", ITEM_TELEPORTERREVEALSEQUENCE_SLOT_START_E)
    _initAddParameter_("HIDELAYERS", _ITEM_VALUE_ZSTRING)
    _initAddParameter_("SHOWLAYERS", _ITEM_VALUE_ZSTRING)
end sub
sub Item.TELEPORTERSWITCH_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    dim as integer enabled
    dim as integer i
    getParameter(enabled, "disable")
    enabled = 1 - enabled
    if data_.TELEPORTERSWITCH_DATA->cycleTime = 0 then
        if enabled = 0 then
            data_.TELEPORTERSWITCH_DATA->cycleTime = 30 
        else
            data_.TELEPORTERSWITCH_DATA->state = 1  
            setValue(1, "interact")
            data_.TELEPORTERSWITCH_DATA->flashCycle = 2
            for i = 0 to 9
                link.projectilecollection_ptr->create(Vector2D(p.x + 16, p.y + 33), Vector2D((rnd * 2 - 1), (rnd * 2 - 1)) * 200, SPARK)
                link.projectilecollection_ptr->create(Vector2D(p.x + 16, p.y + 33), Vector2D((rnd * 2 - 1), (rnd * 2 - 1)) * 200, SPARK)
            next i
            lightState = 1
            throw("ACTIVATE")

        end if
        anims[0].play()
        link.soundeffects_ptr->playSound(SND_CLACKDOWN)
    end if
end sub
sub Item.TELEPORTERSWITCH_SLOT_ENABLE(pvPair() as _Item_slotValuePair_t)
    setParameter(0, "disable")
end sub
sub Item.TELEPORTERSWITCH_PROC_INIT()
    data_.TELEPORTERSWITCH_DATA = new ITEM_TELEPORTERSWITCH_TYPE_DATA

    data_.TELEPORTERSWITCH_DATA->cycleTime = 0
    data_.TELEPORTERSWITCH_DATA->state = 0
    
    CREATE_ANIMS(4)
    anims[0].load(MEDIA_PATH + "teleporterswitch.txt")
    anims[1].load(MEDIA_PATH + "teleporterswitch.txt")
    anims[1].hardSwitch(1)
    
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\BrightWhite_Diffuse.txt", MEDIA_PATH + "Lights\BrightWhite_Specular.txt", 2, 3, 1)  

    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
   
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 64)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
    _initAddValue_("INTERACT", _ITEM_VALUE_INTEGER)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "INTERACT")
end sub
sub Item.TELEPORTERSWITCH_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.TELEPORTERSWITCH_DATA then delete(data_.TELEPORTERSWITCH_DATA)
    data_.TELEPORTERSWITCH_DATA = 0
end sub
function Item.TELEPORTERSWITCH_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    if data_.TELEPORTERSWITCH_DATA->cycleTime = 1 then link.soundeffects_ptr->playSound(SND_CLACKUP)
    if data_.TELEPORTERSWITCH_DATA->cycleTime > 0 then data_.TELEPORTERSWITCH_DATA->cycleTime -= 1
    if data_.TELEPORTERSWITCH_DATA->cycleTime = 0 andAlso data_.TELEPORTERSWITCH_DATA->state = 0 then
        anims[0].restart()
        anims[0].pause()    
    end if
    if data_.TELEPORTERSWITCH_DATA->flashCycle > 0 then 
        lightState = 1
        data_.TELEPORTERSWITCH_DATA->flashCycle -= 1
    else
        lightState = 0
    end if
    
    return 0
end function
sub Item.TELEPORTERSWITCH_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
     
    if data_.TELEPORTERSWITCH_DATA->flashCycle = 0 then
        DRAW_LIT_ANIMATION_BRIGHT(0, p.x, p.y, 0, 0)
    else
        anims[1].drawAnimation(scnbuff, p.x, p.y)
    end if
end sub
sub Item.TELEPORTERSWITCH_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.TELEPORTERSWITCH_PROC_CONSTRUCT()
    _initAddSignal_("ACTIVATE")
    _initAddSlot_("INTERACT", ITEM_TELEPORTERSWITCH_SLOT_INTERACT_E)
    _initAddSlot_("ENABLE", ITEM_TELEPORTERSWITCH_SLOT_ENABLE_E)
    _initAddParameter_("DISABLE", _ITEM_VALUE_INTEGER)
end sub
sub Item.TUBEPUZZLEMAP_SLOT_UPDATE(pvPair() as _Item_slotValuePair_t)
    data_.TUBEPUZZLEMAP_DATA->cycle = 20
    data_.TUBEPUZZLEMAP_DATA->state = 1
end sub
sub Item.TUBEPUZZLEMAP_PROC_INIT()
    data_.TUBEPUZZLEMAP_DATA = new ITEM_TUBEPUZZLEMAP_TYPE_DATA
    
    data_.TUBEPUZZLEMAP_DATA->cycle = 0
    data_.TUBEPUZZLEMAP_DATA->state = 0
    
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "roommapled.txt")
    
    
end sub
sub Item.TUBEPUZZLEMAP_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.TUBEPUZZLEMAP_DATA then delete(data_.TUBEPUZZLEMAP_DATA)
    data_.TUBEPUZZLEMAP_DATA = 0
end sub
function Item.TUBEPUZZLEMAP_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    if data_.TUBEPUZZLEMAP_DATA->cycle > 0 then 
        data_.TUBEPUZZLEMAP_DATA->cycle -= 1
    else
        if data_.TUBEPUZZLEMAP_DATA->state > 0 andAlso data_.TUBEPUZZLEMAP_DATA->state < 4 then
            if data_.TUBEPUZZLEMAP_DATA->state = 2 then anims[0].play()
            data_.TUBEPUZZLEMAP_DATA->state += 1
            data_.TUBEPUZZLEMAP_DATA->cycle = 20
        end if
    end if
    return 0
end function
sub Item.TUBEPUZZLEMAP_PROC_DRAW(scnbuff as integer ptr)
    if data_.TUBEPUZZLEMAP_DATA->state = 0 then
        anims[0].drawAnimation(scnbuff, p.x, p.y)
    elseif data_.TUBEPUZZLEMAP_DATA->state = 1 then 
        if int(rnd * 3) = 0 then anims[0].drawAnimation(scnbuff, p.x, p.y)
    elseif data_.TUBEPUZZLEMAP_DATA->state = 2 then
        
    elseif data_.TUBEPUZZLEMAP_DATA->state = 3 then
        if int(rnd * 3) = 0 then anims[0].drawAnimation(scnbuff, p.x, p.y)
    elseif data_.TUBEPUZZLEMAP_DATA->state = 4 then
        anims[0].drawAnimation(scnbuff, p.x, p.y)
    end if
end sub
sub Item.TUBEPUZZLEMAP_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.TUBEPUZZLEMAP_PROC_CONSTRUCT()
    _initAddSlot_("UPDATE", ITEM_TUBEPUZZLEMAP_SLOT_UPDATE_E)
end sub
