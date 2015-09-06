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
sub Item.ALARMSPINNER_PROC_INIT()
    data_.ALARMSPINNER_DATA = new ITEM_ALARMSPINNER_TYPE_DATA
    dim as integer i, amt
    data_.ALARMSPINNER_DATA->fade = int(rnd * 20) + 64
    data_.ALARMSPINNER_DATA->fadeDir =  3

    CREATE_ANIMS(2)
    anims[0].load(MEDIA_PATH + "alarmlight.txt")
    anims[1].load(MEDIA_PATH + "alarmlightoverlay.txt")
    anims[0].play()
    anims[1].play()
    
    amt = int(rnd * 60)
    for i = 0 to amt
        anims[0].step_animation()
        anims[1].step_animation()    
    next i
end sub
sub Item.ALARMSPINNER_PROC_FLUSH()
 
    if anims_n then delete(anims)
    if data_.ALARMSPINNER_DATA then delete(data_.ALARMSPINNER_DATA)
    data_.ALARMSPINNER_DATA = 0
end sub
function Item.ALARMSPINNER_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    anims[1].step_animation()
    data_.ALARMSPINNER_DATA->fade += data_.ALARMSPINNER_DATA->fadeDir
    if data_.ALARMSPINNER_DATA->fade > 100 then 
        data_.ALARMSPINNER_DATA->fade = 100
        data_.ALARMSPINNER_DATA->fadeDir *= -1
    elseif data_.ALARMSPINNER_DATA->fade < 64 then
        data_.ALARMSPINNER_DATA->fade = 64
        data_.ALARMSPINNER_DATA->fadeDir *= -1
    end if
    return 0
end function
sub Item.ALARMSPINNER_PROC_DRAW(scnbuff as integer ptr)
    anims[0].drawAnimation(scnbuff, p.x+size.x*0.5, p.y+size.y*0.5)
end sub
sub Item.ALARMSPINNER_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    anims[1].setGlow((data_.ALARMSPINNER_DATA->fade shl 24) or &h00ffffff)
    anims[1].drawAnimation(scnbuff, p.x+size.x*0.5, p.y+size.y*0.5)

end sub
sub Item.ALARMSPINNER_PROC_CONSTRUCT()
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
#define ITEM_ANTIPERSONNELMINE_DEFINE_EXPLOSION_RADIUS 150
sub Item.explodeReact()
    Dim as ObjectSlotSet reactions
    
    querySlots(reactions, "explosion reaction", new Circle2D(Vector2D(p.x, p.y), ITEM_ANTIPERSONNELMINE_DEFINE_EXPLOSION_RADIUS))
    reactions.throw("source = "+str(p))

end sub
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
        explodeReact()
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
sub Item.BALLSPAWNER_SLOT_SPAWN(pvPair() as _Item_slotValuePair_t)
    if data_.BALLSPAWNER_DATA->revUpFrames = 0 then
        data_.BALLSPAWNER_DATA->revUpFrames = 60
        link.gamespace_ptr->lockAction = 1
        link.gamespace_ptr->lockCamera = 0
    end if
end sub
sub Item.BALLSPAWNER_PROC_INIT()
    data_.BALLSPAWNER_DATA = new ITEM_BALLSPAWNER_TYPE_DATA

    data_.BALLSPAWNER_DATA->revUpFrames = 0

    CREATE_ANIMS(3)
    
    anims[0].load(MEDIA_PATH + "balllaunchdevice.txt")
    anims[1].load(MEDIA_PATH + "balllaunchdevice.txt")
    anims[1].hardSwitch(1)
    anims[1].play()
    
    anims[2].load(MEDIA_PATH + "balllaunch2.txt")
    anims[2].hardswitch(1)

    
end sub
sub Item.BALLSPAWNER_PROC_FLUSH()
    
    if anims_n then delete(anims)
    if data_.BALLSPAWNER_DATA then delete(data_.BALLSPAWNER_DATA)
    data_.BALLSPAWNER_DATA = 0
end sub
function Item.BALLSPAWNER_PROC_RUN(t as double) as integer
    dim as Item ptr eball
    anims[1].step_animation()

    if data_.BALLSPAWNER_DATA->revUpFrames > 0 then 
        data_.BALLSPAWNER_DATA->revUpFrames -= 1
        
        if data_.BALLSPAWNER_DATA->revUpFrames = 0 then
            eball = DControl->constructItem(DControl->itemStringToType("ENERGY BALL"))
            
            eball->setParameter(1, "takeCamera")
            
            DControl->initItem(eball, Vector2D(p.x + 24, p.y + 30))
            
        end if
    end if
    return 0
end function
sub Item.BALLSPAWNER_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
    
    
    anims[1].drawAnimation(scnbuff, p.x, p.y)
    
    
    anims[2].drawAnimation(scnbuff, p.x, p.y,,,ANIM_TRANS)

end sub
sub Item.BALLSPAWNER_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.BALLSPAWNER_PROC_CONSTRUCT()
    _initAddSlot_("SPAWN", ITEM_BALLSPAWNER_SLOT_SPAWN_E)
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
#DEFINE ITEM_CABINCONTROL_DEFINE_CHARGE_TIME 2700
sub Item.setAmbientLevels()
    dim as integer i
    dim as integer col
    if data_.CABINCONTROL_DATA->state = 1 then
        for i = 0 to link.level_ptr->getLayerN() - 1
            col = link.level_ptr->getAmbientLevel(i)
            addColor(col, &h3f3f3f)
            link.level_ptr->setAmbientLevel(i, col)
        next i
        col = link.level_ptr->getObjectAmbientLevel()
        addColor(col, &h3f3f3f)        
        link.level_ptr->setObjectAmbientLevel(col)
        col = link.level_ptr->getHiddenObjectAmbientLevel()
        addColor(col, &h3f3f3f)        
        link.level_ptr->setHiddenObjectAmbientLevel(col)
    else
        for i = 0 to link.level_ptr->getLayerN() - 1
            col = link.level_ptr->getAmbientLevel(i)
            subColor(col, &h3f3f3f)
            link.level_ptr->setAmbientLevel(i, col)
        next i    
        col = link.level_ptr->getObjectAmbientLevel()
        subColor(col, &h3f3f3f)        
        link.level_ptr->setObjectAmbientLevel(col)
        col = link.level_ptr->getHiddenObjectAmbientLevel()
        subColor(col, &h3f3f3f)        
        link.level_ptr->setHiddenObjectAmbientLevel(col)
    end if

end sub
sub Item.CABINCONTROL_SLOT_STARTSEQUENCE(pvPair() as _Item_slotValuePair_t)
    if data_.CABINCONTROL_DATA->startedSequence = 0 then
        data_.CABINCONTROL_DATA->startedSequence = 1
        link.gamespace_ptr->lockCamera = 0
        link.gamespace_ptr->lockAction = 1
    end if
end sub
sub Item.CABINCONTROL_SLOT_TOGGLELIGHTS(pvPair() as _Item_slotValuePair_t)
    data_.CABINCONTROL_DATA->state = 1 - data_.CABINCONTROL_DATA->state
    setAmbientLevels()
end sub
sub Item.CABINCONTROL_PROC_INIT()
    data_.CABINCONTROL_DATA = new ITEM_CABINCONTROL_TYPE_DATA
    data_.CABINCONTROL_DATA->state = 0
    data_.CABINCONTROL_DATA->glowChargeFrames = 0
    data_.CABINCONTROL_DATA->drawMural = 0
    data_.CABINCONTROL_DATA->startedSequence = 0
    data_.CABINCONTROL_DATA->enablePanel = 0
    data_.CABINCONTROL_DATA->actionTimer = 0
    data_.CABINCONTROL_DATA->playChime = 0
    getParameter(data_.CABINCONTROL_DATA->muralLoc, "muralTarget")
    getParameter(data_.CABINCONTROL_DATA->camTarget, "cameraTarget")

    CREATE_ANIMS(3)
    anims[0].load(MEDIA_PATH + "glowmural.txt")
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\PaleGreen_Diffuse.txt", MEDIA_PATH + "Lights\PaleGreen_Specular.txt", 1, 2, 1)  

end sub
sub Item.CABINCONTROL_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.CABINCONTROL_DATA then delete(data_.CABINCONTROL_DATA)
    data_.CABINCONTROL_DATA = 0
end sub
function Item.CABINCONTROL_PROC_RUN(t as double) as integer
    if data_.CABINCONTROL_DATA->state = 0 then
        data_.CABINCONTROL_DATA->glowChargeFrames -= 1
        if data_.CABINCONTROL_DATA->glowChargeFrames < 0 then data_.CABINCONTROL_DATA->glowChargeFrames = 0
    else
        data_.CABINCONTROL_DATA->glowChargeFrames += 1
        if data_.CABINCONTROL_DATA->glowChargeFrames > ITEM_CABINCONTROL_DEFINE_CHARGE_TIME then 
            data_.CABINCONTROL_DATA->glowChargeFrames = ITEM_CABINCONTROL_DEFINE_CHARGE_TIME
            data_.CABINCONTROL_DATA->drawMural = 1
        end if
    end if
    if data_.CABINCONTROL_DATA->drawMural andAlso (data_.CABINCONTROL_DATA->state = 0) then
        lightState = 1
        if data_.CABINCONTROL_DATA->playChime = 0 then link.soundeffects_ptr->playSound(SND_SUCCESS)
        data_.CABINCONTROL_DATA->playChime = 1
        if data_.CABINCONTROL_DATA->enablePanel = 0 then 
            throw("ENABLEPANEL")
            data_.CABINCONTROL_DATA->enablePanel = 1
        end if
    else
        lightState = 0
    end if
    
    if link.gamespace_ptr->lockCamera = 0 then
        link.gamespace_ptr->camera = Vector2D(650, 650) * 0.06 + link.gamespace_ptr->camera * 0.94
    end if
    
    if data_.CABINCONTROL_DATA->startedSequence = 1 then
        data_.CABINCONTROL_DATA->actionTimer += 1
        select case data_.CABINCONTROL_DATA->actionTimer 
        case 60
            throw("LAMPENABLE")
            throw("TURNLAMPON")
        case 120
            throw("MOVECOUCH")
        case 320
            throw("TURNLIGHTSON")
        case 340
            link.gamespace_ptr->lockCamera = 1
            link.gamespace_ptr->lockAction = 0
        end select
    end if
    
    light.texture.x = data_.CABINCONTROL_DATA->muralLoc.x
    light.texture.y = data_.CABINCONTROL_DATA->muralLoc.y
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y 

    return 0
end function
sub Item.CABINCONTROL_PROC_DRAW(scnbuff as integer ptr)
    if data_.CABINCONTROL_DATA->state = 0 andAlso data_.CABINCONTROL_DATA->drawMural = 1 then
        anims[0].drawAnimation(scnbuff, data_.CABINCONTROL_DATA->muralLoc.x, data_.CABINCONTROL_DATA->muralLoc.y)
        
    end if
end sub
sub Item.CABINCONTROL_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.CABINCONTROL_PROC_CONSTRUCT()
    _initAddSignal_("ENABLEPANEL")
    _initAddSignal_("LAMPENABLE")
    _initAddSignal_("TURNLAMPON")
    _initAddSignal_("MOVECOUCH")
    _initAddSignal_("TURNLIGHTSON")
    _initAddSlot_("STARTSEQUENCE", ITEM_CABINCONTROL_SLOT_STARTSEQUENCE_E)
    _initAddSlot_("TOGGLELIGHTS", ITEM_CABINCONTROL_SLOT_TOGGLELIGHTS_E)
    _initAddParameter_("MURALTARGET", _ITEM_VALUE_VECTOR2D)
    _initAddParameter_("CAMERATARGET", _ITEM_VALUE_VECTOR2D)
end sub
sub Item.CASH_PROC_INIT()
    data_.CASH_DATA = new ITEM_CASH_TYPE_DATA
    dim as integer animNum
    dim as integer i
    
    getParameter(data_.CASH_DATA->denom, "billType")
    
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "collectables.txt")
    select case data_.CASH_DATA->denom
    case 0
        animNum = 2
    case 1
        animNum = 3
    case 2
        animNum = 1
    end select
    anims[0].hardSwitch(animNum)
    anims[0].play()

    data_.CASH_DATA->frameCount = int(rnd * 64)
    for i = 0 to 19
        anims[0].step_animation()
    next i
    
    data_.CASH_DATA->body = TinyBody(p, 8, int(rnd * 5) + 10)
    data_.CASH_DATA->body.elasticity = 0.5
    data_.CASH_DATA->body.friction = 1
    data_.CASH_DATA->body_i = link.tinyspace_ptr->addBody(@(data_.CASH_DATA->body))
    data_.CASH_DATA->body.f = -Vector2D(0,DEFAULT_GRAV) * data_.CASH_DATA->body.m * 0.25
    data_.CASH_DATA->body.p = p
    getParameter(data_.CASH_DATA->body.v, "velocity") 
    
    data_.CASH_DATA->displayFrames = 0
    
    
    data_.CASH_DATA->state = 0
end sub
sub Item.CASH_PROC_FLUSH()

    if data_.CASH_DATA->body_i <> -1 then link.tinyspace_ptr->removeBody(data_.CASH_DATA->body_i)
    if anims_n then delete(anims)
    if data_.CASH_DATA then delete(data_.CASH_DATA)
    data_.CASH_DATA = 0
end sub
function Item.CASH_PROC_RUN(t as double) as integer
    dim as vector2d pv
    dim as double pmag
    anims[0].step_animation()
    data_.CASH_DATA->frameCount += 1
    
    if data_.CASH_DATA->state = 0 then
        p = data_.CASH_DATA->body.p
        
        data_.CASH_DATA->body.v *= 0.98
        

        
        
        pv = link.player_ptr->body.p - (p - Vector2D(0, -7))
        pmag = pv.magnitude()
    
        if pmag < 20 then
            link.tinyspace_ptr->removeBody(data_.CASH_DATA->body_i)
            data_.CASH_DATA->body_i = -1
            data_.CASH_DATA->state = 1
            data_.CASH_DATA->displayFrames = 60
            select case data_.CASH_DATA->denom
            case 0
                link.player_ptr->addMoney(1)
            case 1
                link.player_ptr->addMoney(5)
            case 2
                link.player_ptr->addMoney(10)
            end select
            return 0
        end if
    
        pv /= pmag
        if pmag < 80 then data_.CASH_DATA->body.v += pv*20
    else
        data_.CASH_DATA->displayFrames -= 1
        if data_.CASH_DATA->displayFrames <= 0 then return 1
    end if
    if int(rnd * 20) = 0 then
        link.oneshoteffects_ptr->create(p + Vector2D(rnd * 20 - 10, rnd * 20 - 10), SPARKLE3)
    end if
    return 0
end function
sub Item.CASH_PROC_DRAW(scnbuff as integer ptr)
    dim as double bob
    PREP_LIT_ANIMATION()
    
    
    bob = sin(data_.CASH_DATA->frameCount * 0.143) * 3 
    if data_.CASH_DATA->state = 0 then
        DRAW_LIT_ANIMATION(0, p.x, p.y + bob, 0, 0)
    else

    end if
end sub
sub Item.CASH_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    dim as double bob
    
    
    bob = sin(data_.CASH_DATA->frameCount * 0.143) * 3 
    if data_.CASH_DATA->state = 1 then
        select case data_.CASH_DATA->denom
        case 0
            drawStringShadow scnbuff, p.x - 8 , p.y - 5 + bob, "R1", &haf2f2f
        case 1
            drawStringShadow scnbuff, p.x - 8, p.y - 5 + bob, "R5", &hff7f4f        
        case 2
            drawStringShadow scnbuff, p.x - 12, p.y - 5 + bob, "R10", &h7faf3f
        end select
    end if
end sub
sub Item.CASH_PROC_CONSTRUCT()
    _initAddParameter_("BILLTYPE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("VELOCITY", _ITEM_VALUE_VECTOR2D)
end sub
sub Item.CEILINGFAN_PROC_INIT()
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "ceilingfan.txt")
    anims[0].play()
end sub
sub Item.CEILINGFAN_PROC_FLUSH()

    if anims_n then delete(anims)
end sub
function Item.CEILINGFAN_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    return 0
end function
sub Item.CEILINGFAN_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
end sub
sub Item.CEILINGFAN_PROC_DRAWOVERLAY(scnbuff as integer ptr)
  
end sub
sub Item.CEILINGFAN_PROC_CONSTRUCT()
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
sub Item.CRYSTALGLOW_PROC_INIT()
    dim as integer flavor
    
    getParameter(flavor, "flavor")
    
    CREATE_ANIMS(3)
    anims[0].load(MEDIA_PATH + "crystalglow.txt")
    anims[0].hardSwitch(flavor - 1)
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\SmallWhite_Diffuse.txt", MEDIA_PATH + "Lights\SmallWhite_Specular.txt", 1, 2, 1)  

    
    
end sub
sub Item.CRYSTALGLOW_PROC_FLUSH()

    if anims_n then delete(anims)
end sub
function Item.CRYSTALGLOW_PROC_RUN(t as double) as integer


    if int(rnd * 40) = 0 then 
        link.oneshoteffects_ptr->create(p + Vector2D(size.x*rnd, size.y*rnd), SPARKLE)
    
    end if

    lightState = 1
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    return 0
end function
sub Item.CRYSTALGLOW_PROC_DRAW(scnbuff as integer ptr)
    dim as integer flags
    
    getParameter(flags, "orientation")
    
    if flags and 1 then
        anims[0].drawAnimation(scnbuff, p.x, p.y + 2, ,flags)
    else
        anims[0].drawAnimation(scnbuff, p.x, p.y, ,flags)
    end if

end sub
sub Item.CRYSTALGLOW_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.CRYSTALGLOW_PROC_CONSTRUCT()
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
    _initAddParameter_("ORIENTATION", _ITEM_VALUE_INTEGER)
    _initAddParameter_("LOWCUTOFF", _ITEM_VALUE_VECTOR2D)
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
sub Item.DESKLAMP_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    if data_.DESKLAMP_DATA->isDisabled = 0 then
        data_.DESKLAMP_DATA->fCount = 10
        link.soundeffects_ptr->playSound(SND_LAMPPULL)
    end if
end sub
sub Item.DESKLAMP_SLOT_ENABLE(pvPair() as _Item_slotValuePair_t)
    data_.DESKLAMP_DATA->isDisabled = 0
end sub
sub Item.DESKLAMP_PROC_INIT()
    data_.DESKLAMP_DATA = new ITEM_DESKLAMP_TYPE_DATA
 
    
    data_.DESKLAMP_DATA->isDisabled = 0
    data_.DESKLAMP_DATA->state = 0
    data_.DESKLAMP_DATA->fCount = 0
    data_.DESKLAMP_DATA->flavor = 0
    
    getParameter(data_.DESKLAMP_DATA->isDisabled, "disable")
    getParameter(data_.DESKLAMP_DATA->state, "state")
    getParameter(data_.DESKLAMP_DATA->flavor, "flavor")
    
    CREATE_ANIMS(5)
    
    if data_.DESKLAMP_DATA->flavor = 0 then
        anims[0].load(MEDIA_PATH + "desklamp.txt")
        anims[0].hardswitch(0)
        anims[1].load(MEDIA_PATH + "desklamp.txt")
        anims[1].hardswitch(1)
        anims[2].load(MEDIA_PATH + "desklamp.txt")
        anims[2].hardswitch(2)   
    else
        anims[0].load(MEDIA_PATH + "desklamp.txt")
        anims[0].hardswitch(3)
        anims[1].load(MEDIA_PATH + "desklamp.txt")
        anims[1].hardswitch(4)
        anims[2].load(MEDIA_PATH + "desklamp.txt")
        anims[2].hardswitch(5)      
    end if
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\SmallWhite_Diffuse.txt", MEDIA_PATH + "Lights\SmallWhite_Specular.txt", 3, 4, 1)  
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.DESKLAMP_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.DESKLAMP_DATA then delete(data_.DESKLAMP_DATA)
    data_.DESKLAMP_DATA = 0
end sub
function Item.DESKLAMP_PROC_RUN(t as double) as integer
    if data_.DESKLAMP_DATA->state = 0 then
        anims[1].hardSwitch(1)
        lightState = 0
    else
        anims[1].hardSwitch(0)
        lightState = 1
    end if
    
    if data_.DESKLAMP_DATA->fCount > 0 then
        if data_.DESKLAMP_DATA->fCount = 1 then data_.DESKLAMP_DATA->state = 1 - data_.DESKLAMP_DATA->state
        data_.DESKLAMP_DATA->fCount -= 1
    end if
    
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.25
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y 
    return 0
end function
sub Item.DESKLAMP_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0 )
    if data_.DESKLAMP_DATA->state = 0 then
        DRAW_LIT_ANIMATION(1, p.x, p.y, 0, 0 )
    else
        anims[2].drawAnimation(scnbuff, p.x, p.y)
    end if
end sub
sub Item.DESKLAMP_PROC_DRAWOVERLAY(scnbuff as integer ptr)
  
end sub
sub Item.DESKLAMP_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_DESKLAMP_SLOT_INTERACT_E)
    _initAddSlot_("ENABLE", ITEM_DESKLAMP_SLOT_ENABLE_E)
    _initAddParameter_("DISABLE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("STATE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("FLAVOR", _ITEM_VALUE_INTEGER)
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
#define ITEM_ENERGYBALL_DEFINE_MAX_RAYCAST_ATTEMPTS 10
#define ITEM_ENERGYBALL_DEFINE_RAYCAST_DIST 150
sub Item.ENERGYBALL_SLOT_REACT(pvPair() as _Item_slotValuePair_t)
    dim as Vector2D source
    matchParameter(source, "SOURCE", pvPair())
    dim as Vector2D v
    dim as double mag
    v = source - p
    mag = v.magnitude()
    
    v.normalize()
    
    mag = 150 - mag
    if mag < 0 then mag = 0
    mag /= 150.0
    
    
    data_.ENERGYBALL_DATA->body.v -= (v * mag) * 300
    

end sub
sub Item.ENERGYBALL_PROC_INIT()
    data_.ENERGYBALL_DATA = new ITEM_ENERGYBALL_TYPE_DATA

    data_.ENERGYBALL_DATA->soundTimer = 0
    data_.ENERGYBALL_DATA->flashTimer = 0
    data_.ENERGYBALL_DATA->lastCollide = 0
    data_.ENERGYBALL_DATA->body = TinyBody(p, 16, 10)
    data_.ENERGYBALL_DATA->body.elasticity = 0.2
    data_.ENERGYBALL_DATA->body.friction = 0.5
    data_.ENERGYBALL_DATA->body.f += Vector2D(0, -DEFAULT_GRAV)*data_.ENERGYBALL_DATA->body.m*0.75
    data_.ENERGYBALL_DATA->body_i = link.tinyspace_ptr->addBody(@(data_.ENERGYBALL_DATA->body))

    CREATE_ANIMS(2)
    
    anims[0].load(MEDIA_PATH + "balllaunch2.txt")
    PREP_LIGHTS(MEDIA_PATH + "Lights\BrightWhite_Diffuse.txt", MEDIA_PATH + "Lights\BrightWhite_Specular.txt", 1, 2, 0)  

    data_.ENERGYBALL_DATA->arcs_n = 0
    data_.ENERGYBALL_DATA->arcs = new ITEM_ENERGYBALL_TYPE_arcData_t[2]
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "EXPLOSION REACTION", "REACT", new Circle2D(Vector2D(0,0), 17))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "EXPLOSION REACTION", p)
end sub
sub Item.ENERGYBALL_PROC_FLUSH()
    link.tinyspace_ptr->removeBody(data_.ENERGYBALL_DATA->body_i)
 
    if anims_n then delete(anims)
    if data_.ENERGYBALL_DATA then delete(data_.ENERGYBALL_DATA)
    data_.ENERGYBALL_DATA = 0
end sub
function Item.ENERGYBALL_PROC_RUN(t as double) as integer
    dim as integer takeCamera
    dim as integer i
    dim as double randAngle, dist
    dim as Vector2D v, pt, nv
    anims[0].step_animation()
    
    getParameter(takeCamera, "takeCamera")
    p = data_.ENERGYBALL_DATA->body.p
    
    
    DControl->setTargetSlotOffset(ID, "explosion reaction", p) 

    if link.gamespace_ptr->lockCamera = 0 andAlso takeCamera = 1 then
        link.gamespace_ptr->camera = p * 0.1 + link.gamespace_ptr->camera * 0.9
    end if
    
    if int(rnd * 30) = 0 then
        data_.ENERGYBALL_DATA->flashTimer = int(rnd * 4) + 5
        for i = 0 to data_.ENERGYBALL_DATA->arcs_n - 1
            link.electricarc_ptr->destroy(data_.ENERGYBALL_DATA->arcs[i].arcID)
        next i
        data_.ENERGYBALL_DATA->arcs_n = 0  
        if data_.ENERGYBALL_DATA->arcs_n < 2 then
            for i = 0 to ITEM_ENERGYBALL_DEFINE_MAX_RAYCAST_ATTEMPTS - 1
                randAngle = rnd*(_PI_*2)
                v = Vector2D(cos(randAngle), sin(randAngle))*ITEM_ENERGYBALL_DEFINE_RAYCAST_DIST
                dist = link.tinyspace_ptr->raycast(p, v, pt)
                if dist >= 0 then
               
                    data_.ENERGYBALL_DATA->arcs[data_.ENERGYBALL_DATA->arcs_n].arcID = link.electricarc_ptr->create()
                    data_.ENERGYBALL_DATA->arcs[data_.ENERGYBALL_DATA->arcs_n].bPos = Vector2D(0, 0)
                    data_.ENERGYBALL_DATA->arcs[data_.ENERGYBALL_DATA->arcs_n].endPos = pt
                    link.electricarc_ptr->setPoints(data_.ENERGYBALL_DATA->arcs[data_.ENERGYBALL_DATA->arcs_n].arcID, p + data_.ENERGYBALL_DATA->arcs[data_.ENERGYBALL_DATA->arcs_n].bPos, pt)

                    data_.ENERGYBALL_DATA->arcs_n += 1
                    if data_.ENERGYBALL_DATA->arcs_n = 2 then exit for
                end if
            next i
        end if
    end if
    
    
    for i = 0 to data_.ENERGYBALL_DATA->arcs_n - 1
        link.electricarc_ptr->setPoints(data_.ENERGYBALL_DATA->arcs[i].arcID, p + data_.ENERGYBALL_DATA->arcs[i].bPos, data_.ENERGYBALL_DATA->arcs[i].endPos)
    next i
    if data_.ENERGYBALL_DATA->flashTimer > 0 then
        lightState = 1
        data_.ENERGYBALL_DATA->flashTimer -= 1
        anims[0].play()
    else
        for i = 0 to data_.ENERGYBALL_DATA->arcs_n - 1
            link.electricarc_ptr->destroy(data_.ENERGYBALL_DATA->arcs[i].arcID)
        next i
        data_.ENERGYBALL_DATA->arcs_n = 0
        lightState = 0
        anims[0].restart()
        anims[0].pause()
    end if
 
    if data_.ENERGYBALL_DATA->body.didCollide andAlso data_.ENERGYBALL_DATA->lastCollide = 0 then
        v = link.tinyspace_ptr->getGroundingNormal(data_.ENERGYBALL_DATA->body_i, Vector2D(0, -1), Vector2D(0, -1), -1)
        for i = 0 to 20
            nv = Vector2D((rnd * 2 - 1), (rnd * 2 - 1))
            nv.normalize
            link.projectilecollection_ptr->create(p + -v*17, nv*100, BLUE_SPARK)
        next i
        data_.ENERGYBALL_DATA->flashTimer = 6
        if data_.ENERGYBALL_DATA->soundTimer = 0 then 
            link.soundeffects_ptr->playSound(SND_GLASSTAP)
            data_.ENERGYBALL_DATA->soundTimer = 10
        end if
    end if
    
    if data_.ENERGYBALL_DATA->soundTimer > 0 then data_.ENERGYBALL_DATA->soundTimer -= 1

    data_.ENERGYBALL_DATA->lastCollide = data_.ENERGYBALL_DATA->body.didCollide
    data_.ENERGYBALL_DATA->body.didCollide = 0
    
    light.texture.x = p.x
    light.texture.y = p.y
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    
    return 0
end function
sub Item.ENERGYBALL_PROC_DRAW(scnbuff as integer ptr)
        
    anims[0].setGlow(&h6fffffff)
    anims[0].drawAnimation(scnbuff, p.x+(int(rnd * 7) - 3), p.y+(int(rnd * 7) - 3))

    anims[0].setGlow(&hffffffff)
    anims[0].drawAnimation(scnbuff, p.x, p.y)
    
    anims[0].setGlow(&h5fffffff)
    anims[0].drawAnimation(scnbuff, p.x+(int(rnd * 5) - 2), p.y+(int(rnd * 5) - 2))
end sub
sub Item.ENERGYBALL_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.ENERGYBALL_PROC_CONSTRUCT()
    _initAddSlot_("REACT", ITEM_ENERGYBALL_SLOT_REACT_E)
    _initAddParameter_("TAKECAMERA", _ITEM_VALUE_INTEGER)
end sub
sub Item.FISHBOWL_PROC_INIT()
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "swimmingfish.txt")
    anims[0].play()
end sub
sub Item.FISHBOWL_PROC_FLUSH()

    if anims_n then delete(anims)
end sub
function Item.FISHBOWL_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    return 0
end function
sub Item.FISHBOWL_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
end sub
sub Item.FISHBOWL_PROC_DRAWOVERLAY(scnbuff as integer ptr)
  
end sub
sub Item.FISHBOWL_PROC_CONSTRUCT()
end sub
sub Item.FLOORLAMP_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    if data_.FLOORLAMP_DATA->isDisabled = 0 then 
        data_.FLOORLAMP_DATA->fCount = 10
        link.soundeffects_ptr->playSound(SND_LAMPPULL)
    end if
    
end sub
sub Item.FLOORLAMP_SLOT_TOGGLE(pvPair() as _Item_slotValuePair_t)
    data_.FLOORLAMP_DATA->state = 1 - data_.FLOORLAMP_DATA->state
end sub
sub Item.FLOORLAMP_SLOT_ENABLE(pvPair() as _Item_slotValuePair_t)
    data_.FLOORLAMP_DATA->isDisabled = 0
end sub
sub Item.FLOORLAMP_PROC_INIT()
    data_.FLOORLAMP_DATA = new ITEM_FLOORLAMP_TYPE_DATA
    CREATE_ANIMS(4)
    anims[0].load(MEDIA_PATH + "floorlamp.txt")
    anims[0].hardswitch(2)
    anims[1].load(MEDIA_PATH + "floorlamp.txt")
    anims[1].hardswitch(1)
    
    data_.FLOORLAMP_DATA->isDisabled = 0
    data_.FLOORLAMP_DATA->state = 0
    data_.FLOORLAMP_DATA->fCount = 0
    
    getParameter(data_.FLOORLAMP_DATA->isDisabled, "disable")
    getParameter(data_.FLOORLAMP_DATA->state, "state")
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\LightOrange_Diffuse.txt", MEDIA_PATH + "Lights\LightOrange_Specular.txt", 2, 3, 1)  
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.FLOORLAMP_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.FLOORLAMP_DATA then delete(data_.FLOORLAMP_DATA)
    data_.FLOORLAMP_DATA = 0
end sub
function Item.FLOORLAMP_PROC_RUN(t as double) as integer
    if data_.FLOORLAMP_DATA->state = 0 then
        anims[1].hardSwitch(1)
        lightState = 0
    else
        anims[1].hardSwitch(0)
        lightState = 1
    end if
    
    if data_.FLOORLAMP_DATA->fCount > 0 then
        if data_.FLOORLAMP_DATA->fCount = 1 then data_.FLOORLAMP_DATA->state = 1 - data_.FLOORLAMP_DATA->state
        data_.FLOORLAMP_DATA->fCount -= 1
    end if
    
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.25
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y 
    return 0
end function
sub Item.FLOORLAMP_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y+32, 0, 0 )
    if data_.FLOORLAMP_DATA->state = 0 then
        DRAW_LIT_ANIMATION(1, p.x, p.y, 0, 0 )
    else
        anims[1].drawAnimation(scnbuff, p.x, p.y)
    end if
end sub
sub Item.FLOORLAMP_PROC_DRAWOVERLAY(scnbuff as integer ptr)
  
end sub
sub Item.FLOORLAMP_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_FLOORLAMP_SLOT_INTERACT_E)
    _initAddSlot_("TOGGLE", ITEM_FLOORLAMP_SLOT_TOGGLE_E)
    _initAddSlot_("ENABLE", ITEM_FLOORLAMP_SLOT_ENABLE_E)
    _initAddParameter_("DISABLE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("STATE", _ITEM_VALUE_INTEGER)
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
sub Item.HANGINGBULB_SLOT_TOGGLE(pvPair() as _Item_slotValuePair_t)
    data_.HANGINGBULB_DATA->state = 1 - data_.HANGINGBULB_DATA->state
end sub
sub Item.HANGINGBULB_PROC_INIT()
    data_.HANGINGBULB_DATA = new ITEM_HANGINGBULB_TYPE_DATA
    dim as integer i, noSpec
    
    getParameter(data_.HANGINGBULB_DATA->state, "state")
    getParameter(noSpec, "noSpecular")

    
    CREATE_ANIMS(3)
    if noSpec = 0 then
        PREP_LIGHTS(MEDIA_PATH + "Lights\LightOrange_Diffuse.txt", MEDIA_PATH + "Lights\LightOrange_Specular.txt", 1, 2, 1)  
    else
        PREP_LIGHTS(MEDIA_PATH + "Lights\LightOrange_Diffuse.txt", MEDIA_PATH + "Lights\black_specular.txt", 1, 2, 1)  
    end if
    
    
    anims[0].load(MEDIA_PATH + "bulb.txt")
    
 
end sub
sub Item.HANGINGBULB_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.HANGINGBULB_DATA then delete(data_.HANGINGBULB_DATA)
    data_.HANGINGBULB_DATA = 0
end sub
function Item.HANGINGBULB_PROC_RUN(t as double) as integer

    if data_.HANGINGBULB_DATA->state = 1 then
        lightState = 1
        anims[0].hardSwitch(1)
    else
        lightState = 0
        anims[0].hardSwitch(0)
    end if
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.2
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    return 0
end function
sub Item.HANGINGBULB_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    if data_.HANGINGBULB_DATA->state = 0 then
        DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
    else
        anims[0].drawAnimation(scnbuff, p.x, p.y)
    end if

end sub
sub Item.HANGINGBULB_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.HANGINGBULB_PROC_CONSTRUCT()
    _initAddSlot_("TOGGLE", ITEM_HANGINGBULB_SLOT_TOGGLE_E)
    _initAddParameter_("STATE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("NOSPECULAR", _ITEM_VALUE_INTEGER)
end sub
sub Item.HIDDENSWITCH_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    
    if data_.HIDDENSWITCH_DATA->disable = 0 then
        data_.HIDDENSWITCH_DATA->state = 1 - data_.HIDDENSWITCH_DATA->state
        throw("TOGGLE")
        if data_.HIDDENSWITCH_DATA->state = 1 then
            throw("TURNON")
                
        else
            throw("TURNOFF")
                
        end if
    end if
    
end sub
sub Item.HIDDENSWITCH_SLOT_ENABLE(pvPair() as _Item_slotValuePair_t)
    data_.HIDDENSWITCH_DATA->disable = 0
end sub
sub Item.HIDDENSWITCH_PROC_INIT()
    data_.HIDDENSWITCH_DATA = new ITEM_HIDDENSWITCH_TYPE_DATA
 
    
    data_.HIDDENSWITCH_DATA->state = 0
    getParameter(data_.HIDDENSWITCH_DATA->disable, "disable")

    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(8,8), Vector2D(24, 24)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.HIDDENSWITCH_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.HIDDENSWITCH_DATA then delete(data_.HIDDENSWITCH_DATA)
    data_.HIDDENSWITCH_DATA = 0
end sub
function Item.HIDDENSWITCH_PROC_RUN(t as double) as integer

    
    return 0
end function
sub Item.HIDDENSWITCH_PROC_DRAW(scnbuff as integer ptr)

end sub
sub Item.HIDDENSWITCH_PROC_DRAWOVERLAY(scnbuff as integer ptr)
  
end sub
sub Item.HIDDENSWITCH_PROC_CONSTRUCT()
    _initAddSignal_("TURNON")
    _initAddSignal_("TURNOFF")
    _initAddSignal_("TOGGLE")
    _initAddSlot_("INTERACT", ITEM_HIDDENSWITCH_SLOT_INTERACT_E)
    _initAddSlot_("ENABLE", ITEM_HIDDENSWITCH_SLOT_ENABLE_E)
    _initAddParameter_("STATE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("DISABLE", _ITEM_VALUE_INTEGER)
end sub
sub Item.INTELLIGENCE_SUB_serialize_in()
	
end sub
sub Item.INTELLIGENCE_SUB_serialize_out()
	
end sub
sub Item.INTELLIGENCE_PROC_INIT()
    data_.INTELLIGENCE_DATA = new ITEM_INTELLIGENCE_TYPE_DATA
    data_.INTELLIGENCE_DATA->img = new zImage()
    data_.INTELLIGENCE_DATA->img->load(MEDIA_PATH + "burst3.png")
    data_.INTELLIGENCE_DATA->frameCount = int(rnd * 1000)
    
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "collectables.txt")
    anims[0].hardSwitch(9)
    anims[0].play()
    
    
end sub
sub Item.INTELLIGENCE_PROC_FLUSH()
    delete(data_.INTELLIGENCE_DATA->img)
    if anims_n then delete(anims)
    if data_.INTELLIGENCE_DATA then delete(data_.INTELLIGENCE_DATA)
    data_.INTELLIGENCE_DATA = 0
end sub
function Item.INTELLIGENCE_PROC_RUN(t as double) as integer
    dim as vector2D v
    dim as integer i
    anims[0].step_animation()
    data_.INTELLIGENCE_DATA->frameCount += 1
    
    v = link.player_ptr->body.p - (p + size*0.5)
    
    if v.magnitude < 32 then 
        for i = 0 to 9
        
            link.oneshoteffects_ptr->create(p + Vector2D(size.x*rnd, size.y*rnd), SPARKLE)        
        next i
        link.oneshoteffects_ptr->create(p + size*0.5, BLUE_FLASH)        

        return 1
    end if
    if data_.INTELLIGENCE_DATA->frameCount mod 7 = 0 then link.oneshoteffects_ptr->create(p + Vector2D(size.x*rnd, size.y*rnd), SPARKLE)
    
    
    return 0
end function
sub Item.INTELLIGENCE_PROC_DRAW(scnbuff as integer ptr)
    dim as integer dx, dy
    dim as Vector2D odraw
    
    
    odraw = p + size*0.5
    dx = odraw.x
    dy = odraw.y
    pmapFix(dx, dy)
    rotozoom_alpha2(scnbuff, data_.INTELLIGENCE_DATA->img->getData(), dx, dy, data_.INTELLIGENCE_DATA->frameCount, 1, 1)
    
    anims[0].drawAnimation(scnbuff, odraw.x, odraw.y)
    
end sub
sub Item.INTELLIGENCE_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.INTELLIGENCE_PROC_CONSTRUCT()
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
sub Item.LANTERN_SLOT_TOGGLE(pvPair() as _Item_slotValuePair_t)
    data_.LANTERN_DATA->state = 1 - data_.LANTERN_DATA->state

end sub
sub Item.LANTERN_PROC_INIT()
    data_.LANTERN_DATA = new ITEM_LANTERN_TYPE_DATA
    dim as integer i, noSpec
    
    getParameter(data_.LANTERN_DATA->state, "state")
    getParameter(noSpec, "noSpecular")

 
    CREATE_ANIMS(4)
    if noSpec = 0 then
        PREP_LIGHTS(MEDIA_PATH + "Lights\LightOrange_Diffuse.txt", MEDIA_PATH + "Lights\LightOrange_Specular.txt", 2, 3, 1)  
    else
        PREP_LIGHTS(MEDIA_PATH + "Lights\LightOrange_Diffuse.txt", MEDIA_PATH + "Lights\black_specular.txt", 2, 3, 1)  
    end if
    
    anims[0].load(MEDIA_PATH + "lantern.txt")
    anims[1].load(MEDIA_PATH + "lantern.txt")
    anims[1].hardswitch(1)
 
end sub
sub Item.LANTERN_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.LANTERN_DATA then delete(data_.LANTERN_DATA)
    data_.LANTERN_DATA = 0
end sub
function Item.LANTERN_PROC_RUN(t as double) as integer

    if data_.LANTERN_DATA->state = 1 then
        lightState = 1
    else
        lightState = 0
    end if
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.5 + 8
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    return 0
end function
sub Item.LANTERN_PROC_DRAW(scnbuff as integer ptr)
    dim as integer i
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
    if data_.LANTERN_DATA->state = 1 then anims[1].drawAnimation(scnbuff, p.x, p.y)
    

end sub
sub Item.LANTERN_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.LANTERN_PROC_CONSTRUCT()
    _initAddSlot_("TOGGLE", ITEM_LANTERN_SLOT_TOGGLE_E)
    _initAddParameter_("STATE", _ITEM_VALUE_INTEGER)
    _initAddParameter_("NOSPECULAR", _ITEM_VALUE_INTEGER)
end sub
sub Item.LASEREMITTER_PROC_INIT()
    data_.LASEREMITTER_DATA = new ITEM_LASEREMITTER_TYPE_DATA
    dim as Vector2D t_p, t_size
    dim as integer facing
    getParameter(facing, "facing")
    
    CREATE_ANIMS(3)
    anims = new Animation[anims_n]
    anims[0].load(MEDIA_PATH + "laser.txt")
    anims[0].play()
    anims[1].load(MEDIA_PATH + "laser.txt")
    anims[1].play()
    anims[1].hardSwitch(4)
    anims[1].setPrealphaTarget(link.level_ptr->getSmokeTexture())
    anims[2].load(MEDIA_PATH + "laserhit.txt")
    anims[2].play()
    link.player_ptr->getBounds(t_p, t_size)
    if facing = 1 orElse facing = 3 then
        data_.LASEREMITTER_DATA->collisionTexture = imagecreate(t_size.x, 1)
    else
        data_.LASEREMITTER_DATA->collisionTexture = imagecreate(1, t_size.y)    
    end if
    data_.LASEREMITTER_DATA->lengthHit = 0
    data_.LASEREMITTER_DATA->drawHit = 0
end sub
sub Item.LASEREMITTER_PROC_FLUSH()
    if data_.LASEREMITTER_DATA->collisionTexture then
        imagedestroy(data_.LASEREMITTER_DATA->collisionTexture)
        data_.LASEREMITTER_DATA->collisionTexture = 0
    end if
    if anims_n then delete(anims)
    if data_.LASEREMITTER_DATA then delete(data_.LASEREMITTER_DATA)
    data_.LASEREMITTER_DATA = 0
end sub
function Item.LASEREMITTER_PROC_RUN(t as double) as integer
    dim as Vector2d tl, hitsize, br, pt
    dim as integer hit, facing
    dim as double dist, firstX, firstY
    dim as integer length
    dim as ObjectSlotSet hitTargets
    getParameter(facing, "facing")
    link.player_ptr->getBounds(tl, hitsize)
    br = tl + hitsize
    data_.LASEREMITTER_DATA->drawHit = 0
    hit = 0
    window
    select case facing
    case 2
        line data_.LASEREMITTER_DATA->collisionTexture, (0, 0)-(0, hitsize.y - 1), &hffff00ff
        dist = link.tinyspace_ptr->raycast(p + Vector2D(16, 13), Vector2D(0, 2000), pt)
        if (tl.x <= (p.x + 16)) andAlso (br.x >= (p.x + 16)) andAlso (br.y >= (p.y + 13)) then
            firstY = _max_(p.y + 13, tl.y) - tl.y
            length = firstY
            firstX = tl.x - (p.x + 16)
            
            link.player_ptr->drawPlayerInto(data_.LASEREMITTER_DATA->collisionTexture, firstX, length, 1)
            
            if raycastImage(data_.LASEREMITTER_DATA->collisionTexture, 0, length, 0, 1) then
                hit = 1
                if firstY > 0 then
                    length = length - firstY
                else
                    length = (tl.y + length) - (p.y + 13)
                end if
            end if
        end if   
    case 3
        line data_.LASEREMITTER_DATA->collisionTexture, (0, 0)-(hitsize.x - 1, 0), &hffff00ff
        dist = link.tinyspace_ptr->raycast(p + Vector2D(size.x - 13, 16), Vector2D(-2000, 0), pt)
        if (tl.y <= (p.y + 16)) andAlso (br.y >= (p.y + 16)) andAlso (tl.x <= (p.x + size.x - 13)) then
            firstX = br.x - _min_(p.x + size.x - 13, br.x)
            length = firstX
            firstY = tl.y - (p.y + 16)
            link.player_ptr->drawPlayerInto(data_.LASEREMITTER_DATA->collisionTexture, length, firstY, 1)
            if raycastImage(data_.LASEREMITTER_DATA->collisionTexture, hitsize.x - 1 - length, 0, -1, 0) then
                hit = 1
                if firstX > 0 then
                    length = length - firstX
                else
                    length = (p.x + size.x - 13) - (br.x - length)
                end if
            end if
        end if
    case 1
        line data_.LASEREMITTER_DATA->collisionTexture, (0, 0)-(hitsize.x - 1, 0), &hffff00ff
        dist = link.tinyspace_ptr->raycast(p + Vector2D(13, 16), Vector2D(2000, 0), pt)
        if (tl.y <= (p.y + 16)) andAlso (br.y >= (p.y + 16)) andAlso (br.x >= (p.x + 13)) then
            firstX = _max_(p.x + 13, tl.x) - tl.x
            length = firstX
            firstY = tl.y - (p.y + 16)
            link.player_ptr->drawPlayerInto(data_.LASEREMITTER_DATA->collisionTexture, length, firstY, 1)
            if raycastImage(data_.LASEREMITTER_DATA->collisionTexture, length, 0, 1, 0) then
                hit = 1
                if firstX > 0 then
                    length = length - firstX
                else
                    length = (tl.x + length) - (p.x + 13)
                end if
            end if
        end if
    end select
    if length < dist andAlso hit then 
        dist = length
        data_.LASEREMITTER_DATA->drawHit = 1
    else
        dist += 2
    end if
    if dist = -1 then dist = 0
    data_.LASEREMITTER_DATA->lengthHit = dist
    select case facing
    case 2
        data_.LASEREMITTER_DATA->hitSpot = p + Vector2D(16, 29) + Vector2D(0, data_.LASEREMITTER_DATA->lengthHit - 16)
        querySlots(hitTargets, "laser recieve", new Circle2D(data_.LASEREMITTER_DATA->hitSpot, 10))
        hitTargets.throw()
    end select
    return 0
end function
sub Item.LASEREMITTER_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    dim as integer facing, i
    dim as vector2d ptn
    getParameter(facing, "facing")
    select case facing
    case 0
        ptn = p + Vector2D(0, 0)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 3, 0)           
    case 1
        ptn = p + Vector2D(0, size.y*0.5)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 0, 0)     
    case 2
        ptn = p + Vector2D(0, 16)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 1, 0) 
    case 3
        ptn = p + Vector2D(-32 + size.x, size.y*0.5)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 4, 0)
    end select
end sub
sub Item.LASEREMITTER_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    dim as integer facing
    dim as Vector2D start, curPos
    dim as double length
    getParameter(facing, "facing")
    select case facing
    case 2
        start = p + Vector2D(16, 29)
        length = data_.LASEREMITTER_DATA->lengthHit
        curPos = start
        if data_.LASEREMITTER_DATA->drawHit = 0 then length -= 12
        while length >= 32
            anims[1].drawAnimation(scnbuff, curPos.x-17, curPos.y,,1,ANIM_PREALPHA_TARGET)        
            curPos += Vector2D(0, 32)
            length -= 32
        wend
        anims[1].setClippingBoundaries(0, 0, 0, 32 - length)
        anims[1].drawAnimation(scnbuff, curPos.x-17, curPos.y,,1,ANIM_PREALPHA_TARGET)        
        anims[1].setClippingBoundaries(0, 0, 0, 0)
        if data_.LASEREMITTER_DATA->drawHit = 1 then
            anims[2].drawAnimation(scnbuff, start.x, start.y + data_.LASEREMITTER_DATA->lengthHit - 16)                
        end if
    case 1
        start = p + Vector2D(13, 16)
        length = data_.LASEREMITTER_DATA->lengthHit
        curPos = start
        if data_.LASEREMITTER_DATA->drawHit = 0 then length -= 12
        while length >= 32
            anims[1].drawAnimation(scnbuff, curPos.x, curPos.y,,,ANIM_PREALPHA_TARGET)        
            curPos += Vector2D(32, 0)
            length -= 32
        wend
        anims[1].setClippingBoundaries(0, 0, 32 - length, 0)
        anims[1].drawAnimation(scnbuff, curPos.x, curPos.y,,,ANIM_PREALPHA_TARGET)        
        anims[1].setClippingBoundaries(0, 0, 0, 0)
        if data_.LASEREMITTER_DATA->drawHit = 1 then
            anims[2].drawAnimation(scnbuff, start.x + data_.LASEREMITTER_DATA->lengthHit, start.y)                
        end if
    case 3
        start = p + Vector2D(size.x - 13, 16)
        length = data_.LASEREMITTER_DATA->lengthHit 
        curPos = start
        if data_.LASEREMITTER_DATA->drawHit = 0 then length -= 12
        while length >= 32
            anims[1].drawAnimation(scnbuff, curPos.x - 32, curPos.y,,,ANIM_PREALPHA_TARGET)        
            curPos -= Vector2D(32, 0)
            length -= 32
        wend
        anims[1].setClippingBoundaries(32 - length, 0, 0, 0)
        anims[1].drawAnimation(scnbuff, curPos.x - 32, curPos.y,,,ANIM_PREALPHA_TARGET)        
        anims[1].setClippingBoundaries(32 - length, 0, 0, 0)
        if data_.LASEREMITTER_DATA->drawHit = 1 then
            anims[2].drawAnimation(scnbuff, start.x + data_.LASEREMITTER_DATA->lengthHit, start.y)                
        end if
    end select
    
end sub
sub Item.LASEREMITTER_PROC_CONSTRUCT()
    _initAddParameter_("FACING", _ITEM_VALUE_INTEGER)
end sub
sub Item.LASERRECEIVER_SLOT_RECIEVE(pvPair() as _Item_slotValuePair_t)
    data_.LASERRECEIVER_DATA->targetFrames = 10
end sub
sub Item.LASERRECEIVER_PROC_INIT()
    data_.LASERRECEIVER_DATA = new ITEM_LASERRECEIVER_TYPE_DATA
    data_.LASERRECEIVER_DATA->state = 0
    CREATE_ANIMS(3)
    anims[0].load(MEDIA_PATH + "laser.txt")
    anims[0].hardSwitch(1)
    anims[1].load(MEDIA_PATH + "laser.txt")
    anims[1].hardSwitch(2)
    anims[2].load(MEDIA_PATH + "laser.txt")
    anims[2].hardSwitch(3)    
    
    data_.LASERRECEIVER_DATA->targetFrames = 10
    
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "LASER RECIEVE", "RECIEVE", new Circle2D(Vector2D(0,32), 10))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "LASER RECIEVE", p)
end sub
sub Item.LASERRECEIVER_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.LASERRECEIVER_DATA then delete(data_.LASERRECEIVER_DATA)
    data_.LASERRECEIVER_DATA = 0
end sub
function Item.LASERRECEIVER_PROC_RUN(t as double) as integer
    if data_.LASERRECEIVER_DATA->targetFrames > 0 then
        data_.LASERRECEIVER_DATA->targetFrames -= 1
        data_.LASERRECEIVER_DATA->state = 0
    else
        data_.LASERRECEIVER_DATA->state = 1
    end if
    
    
    return 0
end function
sub Item.LASERRECEIVER_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    dim as integer facing, i
    dim as vector2d ptn
    getParameter(facing, "facing")
    
    select case facing
    case 0
        ptn = p + Vector2D(0, 16)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 3, 0)           
    case 1
        ptn = p + Vector2D(0, size.y*0.5)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 0, 0)     
    case 2
        ptn = p + Vector2D(0, 16)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 1, 0) 
    case 3
        ptn = p + Vector2D(-32 + size.x, size.y*0.5)
        DRAW_LIT_ANIMATION(0, ptn.x, ptn.y, 4, 0)
    end select
    if data_.LASERRECEIVER_DATA->state = 0 then
        select case facing
        case 0
            ptn = p + Vector2D(0, 16)
            anims[1].drawAnimation(scnbuff, ptn.x, ptn.y,,3)           
        case 1
            ptn = p + Vector2D(0, size.y*0.5)
            anims[1].drawAnimation(scnbuff, ptn.x, ptn.y,,0)           
        case 2
            ptn = p + Vector2D(0, 16)
            anims[1].drawAnimation(scnbuff, ptn.x, ptn.y,,1)           
        case 3
            ptn = p + Vector2D(-32 + size.x, size.y*0.5)
            anims[1].drawAnimation(scnbuff, ptn.x, ptn.y,,4)           
        end select    
    else
        select case facing
        case 0
            ptn = p + Vector2D(0, 16)
            anims[2].drawAnimation(scnbuff, ptn.x, ptn.y,,3)           
        case 1
            ptn = p + Vector2D(0, size.y*0.5)
            anims[2].drawAnimation(scnbuff, ptn.x, ptn.y,,0)           
        case 2
            ptn = p + Vector2D(0, 16)
            anims[2].drawAnimation(scnbuff, ptn.x, ptn.y,,1)           
        case 3
            ptn = p + Vector2D(-32 + size.x, size.y*0.5)
            anims[2].drawAnimation(scnbuff, ptn.x, ptn.y,,4)           
        end select      
    end if
    
end sub
sub Item.LASERRECEIVER_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.LASERRECEIVER_PROC_CONSTRUCT()
    _initAddSlot_("RECIEVE", ITEM_LASERRECEIVER_SLOT_RECIEVE_E)
    _initAddParameter_("FACING", _ITEM_VALUE_INTEGER)
end sub
sub Item.MAGICCOUCH_SLOT_MOVE(pvPair() as _Item_slotValuePair_t)
    data_.MAGICCOUCH_DATA->platform->togglePath()
    
end sub
sub Item.MAGICCOUCH_PROC_INIT()
    data_.MAGICCOUCH_DATA = new ITEM_MAGICCOUCH_TYPE_DATA
    dim as TinyDynamic_BASICPATH pathData
    dim as Vector2D path(0 to 1)
    dim as Vector2D shape(0 to 4)
    
    data_.MAGICCOUCH_DATA->lastState = 0
    
    path(0) = p 
    path(1) = p + Vector2D(size.x - 96, 0)
    
    pathData.pathPointsN = 2
    pathData.pathPoints = @(path(0))
    pathData.type_ = TOGGLE
    pathData.speed = 60
    pathData.segment = 0    
    pathData.segment_pos = 0
        
    data_.MAGICCOUCH_DATA->platform = new TinyDynamic(DYNA_BASICPATH)
    data_.MAGICCOUCH_DATA->platform->importParams(@pathData)
    
    shape(0) = Vector2D(0,32)
    shape(1) = Vector2D(96, 32)
    shape(2) = Vector2D(96, 48)
    shape(3) = Vector2D(0, 48)
    shape(4) = shape(0)
    data_.MAGICCOUCH_DATA->platform->importShape(@(shape(0)), 5)
    data_.MAGICCOUCH_DATA->platform->calcBB()
    data_.MAGICCOUCH_DATA->platform->activate()
    
    data_.MAGICCOUCH_DATA->platform_i = link.tinyspace_ptr->addDynamic(data_.MAGICCOUCH_DATA->platform)
    
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "couch.txt")

end sub
sub Item.MAGICCOUCH_PROC_FLUSH()
    link.tinyspace_ptr->removeDynamic(data_.MAGICCOUCH_DATA->platform_i)  
    delete(data_.MAGICCOUCH_DATA->platform)
    if anims_n then delete(anims)
    if data_.MAGICCOUCH_DATA then delete(data_.MAGICCOUCH_DATA)
    data_.MAGICCOUCH_DATA = 0
end sub
function Item.MAGICCOUCH_PROC_RUN(t as double) as integer
    data_.MAGICCOUCH_DATA->elevatorPos = data_.MAGICCOUCH_DATA->platform->getPointP(0)
    
    
    return 0
end function
sub Item.MAGICCOUCH_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()

    DRAW_LIT_ANIMATION(0, data_.MAGICCOUCH_DATA->elevatorPos.x, data_.MAGICCOUCH_DATA->elevatorPos.y - 32, 0, 0)

end sub
sub Item.MAGICCOUCH_PROC_DRAWOVERLAY(scnbuff as integer ptr)

    
end sub
sub Item.MAGICCOUCH_PROC_CONSTRUCT()
    _initAddSlot_("MOVE", ITEM_MAGICCOUCH_SLOT_MOVE_E)
    _initAddParameter_("STARTSIDE", _ITEM_VALUE_INTEGER)
end sub
#define ITEM_MINELANTERN_DEFINE_MOTH_ANGLE_VAR_DEG 45
#define ITEM_MINELANTERN_DEFINE_MOTH_MAG_MIN 10
#define ITEM_MINELANTERN_DEFINE_MOTH_MAG_MAX 40
function Item.MINELANTERN_FUNCTION_pickTarget(curP as Vector2D) as Vector2D
    dim as Vector2D center, v
    dim as double angle
    center = p + size*0.5
    v = (center - curP)
    v.normalize()
    if v = Vector2D(0, 0) then v = Vector2D(1, 0)
    
    angle = v.angle() + (((rnd * ITEM_MINELANTERN_DEFINE_MOTH_ANGLE_VAR_DEG * 2) - ITEM_MINELANTERN_DEFINE_MOTH_ANGLE_VAR_DEG) * (_PI_ / 180.0))
    v = Vector2D(cos(angle), sin(angle)) * ((rnd * (ITEM_MINELANTERN_DEFINE_MOTH_MAG_MAX - ITEM_MINELANTERN_DEFINE_MOTH_MAG_MIN)) + ITEM_MINELANTERN_DEFINE_MOTH_MAG_MIN)
    
    return center + v
end function
sub Item.MINELANTERN_PROC_INIT()
    data_.MINELANTERN_DATA = new ITEM_MINELANTERN_TYPE_DATA
    dim as integer i
    
    CREATE_ANIMS(4)
    PREP_LIGHTS(MEDIA_PATH + "Lights\LanternGlow_Diffuse.txt", MEDIA_PATH + "Lights\LanternGlow_Specular.txt", 2, 3, 0)  
    
    anims[0].load(MEDIA_PATH + "lantern.txt")
    anims[1].load(MEDIA_PATH + "lantern.txt")
    anims[1].hardswitch(1)
    
    if int(rnd * 2) = 0 then 
        data_.MINELANTERN_DATA->moths_N = int(rnd * 3) + 1
    else
        data_.MINELANTERN_DATA->moths_N = 0
    end if
    
    if data_.MINELANTERN_DATA->moths_N then
        data_.MINELANTERN_DATA->moths = new ITEM_MINELANTERN_TYPE_mothData_t[data_.MINELANTERN_DATA->moths_N]
        for i = 0 to data_.MINELANTERN_DATA->moths_N - 1
            data_.MINELANTERN_DATA->moths[i].anim = new Animation()
            data_.MINELANTERN_DATA->moths[i].anim->load(MEDIA_PATH + "lantern.txt")
            data_.MINELANTERN_DATA->moths[i].anim->hardSwitch(2)
            data_.MINELANTERN_DATA->moths[i].anim->play()
            data_.MINELANTERN_DATA->moths[i].p = p + size * 0.5 + Vector2D(int(rnd * 33) - 16, int(rnd * 33) - 16)
            data_.MINELANTERN_DATA->moths[i].drawP = data_.MINELANTERN_DATA->moths[i].p + Vector2D(int(rnd * 3) - 1, int(rnd * 3) - 1)
            data_.MINELANTERN_DATA->moths[i].target = MINELANTERN_FUNCTION_pickTarget(data_.MINELANTERN_DATA->moths[i].p)
            data_.MINELANTERN_DATA->moths[i].f = Vector2D(0,0)
            data_.MINELANTERN_DATA->moths[i].v = Vector2D(0,0)
        next i
    end if
    
    data_.MINELANTERN_DATA->frame = 0
    data_.MINELANTERN_DATA->flickerCounter = 0
    
end sub
sub Item.MINELANTERN_PROC_FLUSH()
    dim as integer i
    for i = 0 to data_.MINELANTERN_DATA->moths_N - 1
        delete(data_.MINELANTERN_DATA->moths[i].anim)
    next i
    if data_.MINELANTERN_DATA->moths then delete(data_.MINELANTERN_DATA->moths)
    data_.MINELANTERN_DATA->moths = 0
    if anims_n then delete(anims)
    if data_.MINELANTERN_DATA then delete(data_.MINELANTERN_DATA)
    data_.MINELANTERN_DATA = 0
end sub
function Item.MINELANTERN_PROC_RUN(t as double) as integer
    dim as integer i
    dim as double mag
    dim as Vector2D v
    for i = 0 to data_.MINELANTERN_DATA->moths_N - 1
        data_.MINELANTERN_DATA->moths[i].anim->step_animation()
        v = data_.MINELANTERN_DATA->moths[i].target - data_.MINELANTERN_DATA->moths[i].p
        v.normalize()
        data_.MINELANTERN_DATA->moths[i].f += v
        data_.MINELANTERN_DATA->moths[i].v += data_.MINELANTERN_DATA->moths[i].f
        data_.MINELANTERN_DATA->moths[i].f *= 0.9
        data_.MINELANTERN_DATA->moths[i].v *= 0.9
        data_.MINELANTERN_DATA->moths[i].p += data_.MINELANTERN_DATA->moths[i].v * 0.02
        if (data_.MINELANTERN_DATA->moths[i].p - data_.MINELANTERN_DATA->moths[i].target).magnitude() < 8 then data_.MINELANTERN_DATA->moths[i].target = MINELANTERN_FUNCTION_pickTarget(data_.MINELANTERN_DATA->moths[i].p)
        data_.MINELANTERN_DATA->moths[i].drawP = data_.MINELANTERN_DATA->moths[i].p + Vector2D(int(rnd * 3) - 1, int(rnd * 3) - 1)
    next i
    
    data_.MINELANTERN_DATA->frame += 1
    
    if int(rnd * 200) = 0 then data_.MINELANTERN_DATA->flickerCounter = int(rnd * 10) + 5
    if data_.MINELANTERN_DATA->flickerCounter > 0 then data_.MINELANTERN_DATA->flickerCounter -= 1

    lightState = 1
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    return 0
end function
sub Item.MINELANTERN_PROC_DRAW(scnbuff as integer ptr)
    dim as integer i
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
    if iif(data_.MINELANTERN_DATA->flickerCounter > 0, int(data_.MINELANTERN_DATA->frame * 0.5) and 1, 1) then anims[1].drawAnimation(scnbuff, p.x, p.y)
    
    for i = 0 to data_.MINELANTERN_DATA->moths_N - 1
        if link.level_ptr->shouldLight() then
            data_.MINELANTERN_DATA->moths[i].anim->drawAnimationLit(scnbuff, data_.MINELANTERN_DATA->moths[i].drawp.x, data_.MINELANTERN_DATA->moths[i].drawp.y,_
                                           lights, numLights, link.level_ptr->getHiddenObjectAmbientLevel(),_
                                           link.gamespace_ptr->camera,,,ANIM_TRANS)            
        else
            data_.MINELANTERN_DATA->moths[i].anim->drawAnimation(scnbuff, data_.MINELANTERN_DATA->moths[i].drawp.x, data_.MINELANTERN_DATA->moths[i].drawp.y, link.gamespace_ptr->camera,,ANIM_TRANS)
        end if  
    next i
end sub
sub Item.MINELANTERN_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.MINELANTERN_PROC_CONSTRUCT()
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
sub Item.NIXIEFLICKER_PROC_INIT()
    data_.NIXIEFLICKER_DATA = new ITEM_NIXIEFLICKER_TYPE_DATA
    dim as integer i
    CREATE_ANIMS(3)
    anims[0].load(MEDIA_PATH + "nixie.txt")
    anims[0].play()     
    
    PREP_LIGHTS(MEDIA_PATH + "Lights\RedOrange_Diffuse.txt", MEDIA_PATH + "Lights\RedOrange_Specular.txt", 1, 2, 0)  

    data_.NIXIEFLICKER_DATA->tubeValues = new integer[6]
    data_.NIXIEFLICKER_DATA->valueFixed = new integer[6]
    for i = 0 to 5
        data_.NIXIEFLICKER_DATA->tubeValues[i] = int(rnd * 36)
        data_.NIXIEFLICKER_DATA->valueFixed[i] = 0
    next i
    data_.NIXIEFLICKER_DATA->countup = 0
    data_.NIXIEFLICKER_DATA->countA = 0
end sub
sub Item.NIXIEFLICKER_PROC_FLUSH()
    delete(data_.NIXIEFLICKER_DATA->tubeValues)
    delete(data_.NIXIEFLICKER_DATA->valueFixed)
    if anims_n then delete(anims)
    if data_.NIXIEFLICKER_DATA then delete(data_.NIXIEFLICKER_DATA)
    data_.NIXIEFLICKER_DATA = 0
end sub
function Item.NIXIEFLICKER_PROC_RUN(t as double) as integer
    dim as integer i, value
    light.texture.x = p.x + size.x * 0.5
    light.texture.y = p.y + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  

    data_.NIXIEFLICKER_DATA->countup += 1
    
    if data_.NIXIEFLICKER_DATA->countup < 603 then
        data_.NIXIEFLICKER_DATA->countA += 1
        if data_.NIXIEFLICKER_DATA->countA >= 2 then
            data_.NIXIEFLICKER_DATA->countA = 0
            lightState = 1 - lightState
            for i = 0 to 5
                if data_.NIXIEFLICKER_DATA->countup > (300 + i*60) then
                    select case i
                    case 0
                        value = 30
                    case 1
                        value = 31
                    case 2
                        value = 11
                    case 3
                        value = 0
                    case 4
                        value = 7
                    case 5
                        value = 6
                    end select 
                    data_.NIXIEFLICKER_DATA->valueFixed[i] = 1
                else
                    value = int(rnd * 36)
                end if
                data_.NIXIEFLICKER_DATA->tubeValues[i] = value
            next i
        end if
    else
        lightState = 1
    end if    
    return 0
end function
sub Item.NIXIEFLICKER_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    dim as integer i, frame, posX, posY
    
    for i = 0 to 5
        frame = data_.NIXIEFLICKER_DATA->tubeValues[i]
        if lightState = 0 andAlso (data_.NIXIEFLICKER_DATA->valueFixed[i] = 0) then frame = 36
        posX = (frame * 16) mod 320
        posY = int((frame * 16) / 320) * 32
        anims[0].drawImageLit(scnbuff, p.x + i*16 + iif(i > 2, 16, 0), p.y, posX, posY, posX+15, posY+31,_
                              lights, numLights, iif((lightState = 0) andAlso (data_.NIXIEFLICKER_DATA->valueFixed[i] = 0), &h404040, &hFF8080),_
                              ,,0) 
    next i
end sub
sub Item.NIXIEFLICKER_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.NIXIEFLICKER_PROC_CONSTRUCT()
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
#define ITEM_RAZ200_DEFINE_STARNUM 40
sub Item.RAZ200_PROC_INIT()
    data_.RAZ200_DATA = new ITEM_RAZ200_TYPE_DATA
    dim as integer i
    C64.loadStandardPallette(C64_standardPallette)
    C64.loadScreenSpace(C64_standardScreen,C64_standardPallette)
    C64.loadFont(data_.RAZ200_DATA->Arena,C64.ArenaB)
    data_.RAZ200_DATA->titleImage = c64.loadImage(C64_standardScreen, MEDIA_PATH + "logo.bmp")
    data_.RAZ200_DATA->bigBunImage = c64.loadImage(C64_standardScreen, MEDIA_PATH + "bigbun.bmp")
    
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "raz200.txt")
    
    data_.RAZ200_DATA->glare = new zimage()
    data_.RAZ200_DATA->glare->load(MEDIA_PATH + "raz200glare.png")
    
    data_.RAZ200_DATA->devicePos = p + Vector2D(size.x*0.5 - 172, size.y - 335)
    data_.RAZ200_DATA->frameCount = int(rnd * 100)
    
    data_.RAZ200_DATA->stars = new ITEM_RAZ200_TYPE_backStar[ITEM_RAZ200_DEFINE_STARNUM]
    for i = 0 to ITEM_RAZ200_DEFINE_STARNUM - 1
        data_.RAZ200_DATA->stars[i].x = int(rnd * 160)
        data_.RAZ200_DATA->stars[i].y = int(rnd * 200)
        data_.RAZ200_DATA->stars[i].flavor = int(rnd * 3)
        data_.RAZ200_DATA->stars[i].speedX = 0
        data_.RAZ200_DATA->stars[i].speedY = data_.RAZ200_DATA->stars[i].flavor + 1
    next i   
end sub
sub Item.RAZ200_PROC_FLUSH()
    C64.deleteImage(data_.RAZ200_DATA->titleImage)
    C64.deleteImage(data_.RAZ200_DATA->bigBunImage)
    delete(data_.RAZ200_DATA->glare)
    delete(data_.RAZ200_DATA->stars)
    if anims_n then delete(anims)
    if data_.RAZ200_DATA then delete(data_.RAZ200_DATA)
    data_.RAZ200_DATA = 0
end sub
function Item.RAZ200_PROC_RUN(t as double) as integer
    dim as integer i, rand
    dim as integer arenaCol
    c64.clearScreen(C64_standardScreen,0)

    for i = 0 to ITEM_RAZ200_DEFINE_STARNUM - 1
        data_.RAZ200_DATA->stars[i].x += data_.RAZ200_DATA->stars[i].speedX 
        data_.RAZ200_DATA->stars[i].y += data_.RAZ200_DATA->stars[i].speedY
        if data_.RAZ200_DATA->stars[i].y > 200 then
            data_.RAZ200_DATA->stars[i].y = 0
            rand = int(rnd * 15)
            if rand < 2 then
                data_.RAZ200_DATA->stars[i].flavor = 0
            elseif rand < 6 then
                data_.RAZ200_DATA->stars[i].flavor = 1
            else
                data_.RAZ200_DATA->stars[i].flavor = 2
            end if
            data_.RAZ200_DATA->stars[i].speedY = data_.RAZ200_DATA->stars[i].flavor + 1
            data_.RAZ200_DATA->stars[i].speedX = 0
        end if
        select case data_.RAZ200_DATA->stars[i].flavor
        case 0
            c64.PIXEL(C64_standardScreen, data_.RAZ200_DATA->stars[i].x, data_.RAZ200_DATA->stars[i].y, 11)
        case 1
            c64.PIXEL(C64_standardScreen, data_.RAZ200_DATA->stars[i].x, data_.RAZ200_DATA->stars[i].y, 12)
        case 2
            c64.PIXEL(C64_standardScreen, data_.RAZ200_DATA->stars[i].x, data_.RAZ200_DATA->stars[i].y, 1)
        end select
    next i
    
    
    c64.drawImage(C64_standardScreen,0,0,data_.RAZ200_DATA->titleImage,0,0,159,198,"PSET", 40, 2, 1)
    c64.drawImage(C64_standardScreen,12,133,data_.RAZ200_DATA->bigBunImage,0,0,59,56,"PSET")
   
   
    if (int(data_.RAZ200_DATA->frameCount * 0.25) and 1) then
        arenaCol = 3
    else
        arenaCol = 6
    end if
    c64.TEXT(c64_standardScreen,90,143,"PRESS",data_.RAZ200_DATA->Arena,arenaCol)
    c64.TEXT(c64_standardScreen,90,155,"ENTER",data_.RAZ200_DATA->Arena,arenaCol)

    
    data_.RAZ200_DATA->frameCount += 1
    return 0
end function
sub Item.RAZ200_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    dim as integer dx, dy
   
 
    DRAW_LIT_ANIMATION(0, data_.RAZ200_DATA->devicePos.x, data_.RAZ200_DATA->devicePos.y, 0, 0)
    
    
    dx = data_.RAZ200_DATA->devicePos.x + 12
    dy = data_.RAZ200_DATA->devicePos.y + 19
    
    pmapFix(dx, dy)
    c64.drawScreen(scnbuff, dx, dy, c64_standardScreen)
    
    dx = data_.RAZ200_DATA->devicePos.x
    dy = data_.RAZ200_DATA->devicePos.y  
    pmapFix(dx, dy)

    bitblt_addRGBA_Clip(scnbuff, dx, dy, data_.RAZ200_DATA->glare->getData(),0,0,343,235)
    
end sub
sub Item.RAZ200_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    
end sub
sub Item.RAZ200_PROC_CONSTRUCT()
end sub
sub Item.REDPOSTLIGHT_PROC_INIT()

    CREATE_ANIMS(3)
    anims[0].load(MEDIA_PATH + "postbulb.txt")
    PREP_LIGHTS(MEDIA_PATH + "Lights\TinyRed_Diffuse.txt", MEDIA_PATH + "Lights\TinyRed_Specular.txt", 1, 2, 1)  

end sub
sub Item.REDPOSTLIGHT_PROC_FLUSH()
    
    if anims_n then delete(anims)
end sub
function Item.REDPOSTLIGHT_PROC_RUN(t as double) as integer

  
    lightState = 1
    light.texture.x = drawX + size.x * 0.5
    light.texture.y = drawY + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    return 0
end function
sub Item.REDPOSTLIGHT_PROC_DRAW(scnbuff as integer ptr)
    anims[0].drawAnimation(scnbuff, p.x+size.x*0.5, p.y+size.y*0.5 + 5)
end sub
sub Item.REDPOSTLIGHT_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.REDPOSTLIGHT_PROC_CONSTRUCT()
end sub
#define ITEM_REDWALLLIGHT_DEFINE_ANIM_SPEED 10
sub Item.REDWALLLIGHT_PROC_INIT()
    data_.REDWALLLIGHT_DATA = new ITEM_REDWALLLIGHT_TYPE_DATA
    data_.REDWALLLIGHT_DATA->curFrame = 0
    data_.REDWALLLIGHT_DATA->speedCount = ITEM_REDWALLLIGHT_DEFINE_ANIM_SPEED
    data_.REDWALLLIGHT_DATA->frameDir = 1

    CREATE_ANIMS(3)
    anims[0].load(MEDIA_PATH + "red wall light.txt")
    PREP_LIGHTS(MEDIA_PATH + "Lights\SmallRed_Diffuse.txt", MEDIA_PATH + "Lights\SmallRed_Specular.txt", 1, 2, 1)  

end sub
sub Item.REDWALLLIGHT_PROC_FLUSH()
    
    if anims_n then delete(anims)
    if data_.REDWALLLIGHT_DATA then delete(data_.REDWALLLIGHT_DATA)
    data_.REDWALLLIGHT_DATA = 0
end sub
function Item.REDWALLLIGHT_PROC_RUN(t as double) as integer
    
  
    lightState = 1
    light.texture.x = drawX + size.x * 0.5
    light.texture.y = drawY + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    return 0
end function
sub Item.REDWALLLIGHT_PROC_DRAW(scnbuff as integer ptr)
    anims[0].drawImage(scnbuff, drawX, drawY, data_.REDWALLLIGHT_DATA->curFrame*32, 0, data_.REDWALLLIGHT_DATA->curFrame*32 + 31, 31,,,,ANIM_TRANS)
    
    anims[0].drawImage(scnbuff, drawX, drawY, 128, 0, 159, 31)
end sub
sub Item.REDWALLLIGHT_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.REDWALLLIGHT_PROC_CONSTRUCT()
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
sub Item.SIGN_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    data_.SIGN_DATA->doText = 1
    setValue(1, "interact")
end sub
sub Item.SIGN_PROC_INIT()
    data_.SIGN_DATA = new ITEM_SIGN_TYPE_DATA
    setValue(0, "interact")
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 32)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
    _initAddValue_("INTERACT", _ITEM_VALUE_INTEGER)
    link.dynamiccontroller_ptr->addPublishedValue(ID, "INTERACT")
end sub
sub Item.SIGN_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.SIGN_DATA then delete(data_.SIGN_DATA)
    data_.SIGN_DATA = 0
end sub
function Item.SIGN_PROC_RUN(t as double) as integer
    dim as vector2d v
    if data_.SIGN_DATA->doText then 
        v = (p + size*0.5) - link.player_ptr->body.p
        if v.magnitude() > 70 then
            data_.SIGN_DATA->doText = 0
            setValue(0, "interact")
        end if
    end if
    return 0
end function
sub Item.SIGN_PROC_DRAW(scnbuff as integer ptr)

end sub
sub Item.SIGN_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    dim as string text
    dim as vector2d tl, br
    if data_.SIGN_DATA->doText then
    
        getParameter(text, "text")
        tl = Vector2D(p.x + size.x*0.5 - len(text)*4 - 4, p.y - 21)
        br = Vector2D(p.x + size.x*0.5 + len(text)*4 + 4, p.y - 9)
        line scnbuff, (tl.x, tl.y)-(br.x, br.y), 0, BF
        line scnbuff, (tl.x-1, tl.y-1)-(br.x+1, br.y+1), &h7f7f7f, B

        draw String scnbuff, (p.x - len(text)*4 + size.x*0.5, p.y - 18), text, &h7f7fff
    end if
end sub
sub Item.SIGN_PROC_CONSTRUCT()
    _initAddSlot_("INTERACT", ITEM_SIGN_SLOT_INTERACT_E)
    _initAddParameter_("TEXT", _ITEM_VALUE_ZSTRING)
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
sub Item.SPOTLIGHTCONTROL_PROC_INIT()
    data_.SPOTLIGHTCONTROL_DATA = new ITEM_SPOTLIGHTCONTROL_TYPE_DATA

    CREATE_ANIMS(3)
    PREP_LIGHTS(MEDIA_PATH + "Lights\MediumWhite_Diffuse.txt", MEDIA_PATH + "Lights\MediumWhite_Specular.txt", 0, 1, 1)  
    data_.SPOTLIGHTCONTROL_DATA->transitFrames = 240
    data_.SPOTLIGHTCONTROL_DATA->dire = 1
    
    anims[2].load(MEDIA_PATH + "halo.txt")
    data_.SPOTLIGHTCONTROL_DATA->tracking = 0
    data_.SPOTLIGHTCONTROL_DATA->stopPos = p
    data_.SPOTLIGHTCONTROL_DATA->sweepDire = int(rnd * 2) * 2 - 1
    data_.SPOTLIGHTCONTROL_DATA->visibleFrames = 0
    data_.SPOTLIGHTCONTROL_DATA->suspicionLevel = 0
    data_.SPOTLIGHTCONTROL_DATA->noticeBuffer = 0
    data_.SPOTLIGHTCONTROL_DATA->stopBuffer = 20
    data_.SPOTLIGHTCONTROL_DATA->v = Vector2D(0,0)
end sub
sub Item.SPOTLIGHTCONTROL_PROC_FLUSH()
    
    if anims_n then delete(anims)
    if data_.SPOTLIGHTCONTROL_DATA then delete(data_.SPOTLIGHTCONTROL_DATA)
    data_.SPOTLIGHTCONTROL_DATA = 0
end sub
function Item.SPOTLIGHTCONTROL_PROC_RUN(t as double) as integer
    dim as Vector2D v
    dim as double vmag
    
    select case data_.SPOTLIGHTCONTROL_DATA->tracking
    case 0
        data_.SPOTLIGHTCONTROL_DATA->v += Vector2D(data_.SPOTLIGHTCONTROL_DATA->sweepDire, 0)*0.1
        if data_.SPOTLIGHTCONTROL_DATA->v.magnitude() > 1 then data_.SPOTLIGHTCONTROL_DATA->v.normalize()
        p += data_.SPOTLIGHTCONTROL_DATA->v
        if data_.SPOTLIGHTCONTROL_DATA->stopBuffer <= 0 then
            if p.x < _max_(data_.SPOTLIGHTCONTROL_DATA->stopPos.x - 300, 0) then
                p.xs = _max_(data_.SPOTLIGHTCONTROL_DATA->stopPos.x - 300, 0)
                data_.SPOTLIGHTCONTROL_DATA->sweepDire *= -1
                data_.SPOTLIGHTCONTROL_DATA->stopBuffer = 20
            elseif p.x > _min_(data_.SPOTLIGHTCONTROL_DATA->stopPos.x + 300, link.level_ptr->getWidth()*16) then
                p.xs = _min_(data_.SPOTLIGHTCONTROL_DATA->stopPos.x + 300, link.level_ptr->getWidth()*16)
                data_.SPOTLIGHTCONTROL_DATA->sweepDire *= -1
                data_.SPOTLIGHTCONTROL_DATA->stopBuffer = 20
            end if
        end if
        if data_.SPOTLIGHTCONTROL_DATA->stopBuffer > 0 then data_.SPOTLIGHTCONTROL_DATA->stopBuffer -= 1
       
       
        if link.player_ptr->getCovered() < _min_(_max_((100.0 / _max_((link.player_ptr->body.p - (p + size*0.5)).magnitude(), 1.0)) - 0.3, 0.0), 0.60)then 
            data_.SPOTLIGHTCONTROL_DATA->noticeBuffer += 1              
        elseif link.player_ptr->getCovered() < 0.65 then
            v = link.player_ptr->body.p - (p + size*0.5)
            if v.magnitude() < 100 then 
                data_.SPOTLIGHTCONTROL_DATA->noticeBuffer = 0
                data_.SPOTLIGHTCONTROL_DATA->tracking = 1
                data_.SPOTLIGHTCONTROL_DATA->caughtFrames = 110 - data_.SPOTLIGHTCONTROL_DATA->suspicionLevel
                data_.SPOTLIGHTCONTROL_DATA->visibleFrames = 100
                data_.SPOTLIGHTCONTROL_DATA->suspicionLevel += 20
                if data_.SPOTLIGHTCONTROL_DATA->suspicionLevel > 100 then data_.SPOTLIGHTCONTROL_DATA->suspicionLevel = 100                
            end if
        else
            data_.SPOTLIGHTCONTROL_DATA->noticeBuffer -= 0.25
            if data_.SPOTLIGHTCONTROL_DATA->noticeBuffer <= 0 then data_.SPOTLIGHTCONTROL_DATA->noticeBuffer = 0
        end if
        
        if data_.SPOTLIGHTCONTROL_DATA->noticeBuffer >= 10 then
            data_.SPOTLIGHTCONTROL_DATA->tracking = 1
            data_.SPOTLIGHTCONTROL_DATA->caughtFrames = 180 - data_.SPOTLIGHTCONTROL_DATA->suspicionLevel
            data_.SPOTLIGHTCONTROL_DATA->visibleFrames = 60
            data_.SPOTLIGHTCONTROL_DATA->suspicionLevel += 20
            if data_.SPOTLIGHTCONTROL_DATA->suspicionLevel > 100 then data_.SPOTLIGHTCONTROL_DATA->suspicionLevel = 100
        end if
    case 1
        data_.SPOTLIGHTCONTROL_DATA->noticeBuffer = 0
        data_.SPOTLIGHTCONTROL_DATA->caughtFrames -= 1
        if data_.SPOTLIGHTCONTROL_DATA->caughtFrames <= 0 then data_.SPOTLIGHTCONTROL_DATA->tracking = 2
        if link.player_ptr->getCovered() >= 0.65 then
            data_.SPOTLIGHTCONTROL_DATA->visibleFrames -= 1
            if data_.SPOTLIGHTCONTROL_DATA->visibleFrames <= 0 then data_.SPOTLIGHTCONTROL_DATA->tracking = 0
        end if    
        p += data_.SPOTLIGHTCONTROL_DATA->v
        data_.SPOTLIGHTCONTROL_DATA->v *= 0.95
    case 2
        
        v = link.player_ptr->body.p - (p + size*0.5)
        vmag = v.magnitude()
        if vmag > 10 then
            v /= vmag
            data_.SPOTLIGHTCONTROL_DATA->v += v * 0.1
            if data_.SPOTLIGHTCONTROL_DATA->v.magnitude() > 1 then data_.SPOTLIGHTCONTROL_DATA->v.normalize()
            
            p += data_.SPOTLIGHTCONTROL_DATA->v*2
        else
            data_.SPOTLIGHTCONTROL_DATA->v *= 0.95
            p += data_.SPOTLIGHTCONTROL_DATA->v*2
        end if
        if link.player_ptr->getCovered() > 0.65 then
            data_.SPOTLIGHTCONTROL_DATA->noticeBuffer += 0.5
        else
            data_.SPOTLIGHTCONTROL_DATA->noticeBuffer -= 1
            data_.SPOTLIGHTCONTROL_DATA->suspicionLevel += 0.25
            if data_.SPOTLIGHTCONTROL_DATA->suspicionLevel > 100 then data_.SPOTLIGHTCONTROL_DATA->suspicionLevel = 100
            if data_.SPOTLIGHTCONTROL_DATA->noticeBuffer <= 0 then data_.SPOTLIGHTCONTROL_DATA->noticeBuffer = 0
        end if
        if data_.SPOTLIGHTCONTROL_DATA->noticeBuffer >= 10 + data_.SPOTLIGHTCONTROL_DATA->suspicionLevel then
            data_.SPOTLIGHTCONTROL_DATA->tracking = 1
            data_.SPOTLIGHTCONTROL_DATA->caughtFrames = 240 - data_.SPOTLIGHTCONTROL_DATA->suspicionLevel
            data_.SPOTLIGHTCONTROL_DATA->visibleFrames = 120
        end if
    end select
    
    

    
    
    
    
    
    
    
    
    

    lightState = 1
    light.texture.x = p.x + size.x*0.5
    light.texture.y = p.y + size.y * 0.5
    light.shaded.x = light.texture.x
    light.shaded.y = light.texture.y  
    return 0
end function
sub Item.SPOTLIGHTCONTROL_PROC_DRAW(scnbuff as integer ptr)
end sub
sub Item.SPOTLIGHTCONTROL_PROC_DRAWOVERLAY(scnbuff as integer ptr)
    anims[2].setGlow(&h7fffffff)
    anims[2].drawAnimation(scnbuff, p.x+size.x*0.5,p.y+size.y*0.5)

end sub
sub Item.SPOTLIGHTCONTROL_PROC_CONSTRUCT()
end sub
sub Item.setToState()
    if data_.STANDUPSWITCH_DATA->state = 0 then
        anims[0].restart()
        anims[1].restart()
        anims[0].pause()
        anims[1].pause()
    else
        anims[0].play()
        anims[1].play()        
    end if
end sub
sub Item.STANDUPSWITCH_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    data_.STANDUPSWITCH_DATA->state = 1 - data_.STANDUPSWITCH_DATA->state
    setToState()
    if data_.STANDUPSWITCH_DATA->state = 1 then
        link.soundeffects_ptr->playSound(SND_CLACKUP)
        throw("TURNON")
    else
        link.soundeffects_ptr->playSound(SND_CLACKDOWN)   
        throw("TURNOFF")
    end if
end sub
sub Item.STANDUPSWITCH_PROC_INIT()
    data_.STANDUPSWITCH_DATA = new ITEM_STANDUPSWITCH_TYPE_DATA
    dim as integer cstate
    getParameter(cstate, "state")
   
    data_.STANDUPSWITCH_DATA->state = cstate
    
    
    CREATE_ANIMS(2)
    anims[0].load(MEDIA_PATH + "standswitch.txt")
    anims[1].load(MEDIA_PATH + "standswitch.txt")
    anims[1].hardswitch(1)

    setToState()
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(0,0), Vector2D(32, 64)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.STANDUPSWITCH_PROC_FLUSH()
    
    if anims_n then delete(anims)
    if data_.STANDUPSWITCH_DATA then delete(data_.STANDUPSWITCH_DATA)
    data_.STANDUPSWITCH_DATA = 0
end sub
function Item.STANDUPSWITCH_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    anims[1].step_animation()
    return 0
end function
sub Item.STANDUPSWITCH_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
    anims[1].drawAnimation(scnbuff, p.x, p.y)
    
end sub
sub Item.STANDUPSWITCH_PROC_DRAWOVERLAY(scnbuff as integer ptr)

end sub
sub Item.STANDUPSWITCH_PROC_CONSTRUCT()
    _initAddSignal_("TURNON")
    _initAddSignal_("TURNOFF")
    _initAddSlot_("INTERACT", ITEM_STANDUPSWITCH_SLOT_INTERACT_E)
    _initAddParameter_("STATE", _ITEM_VALUE_INTEGER)
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
sub Item.VENTWIRES_PROC_INIT()
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "ventwires.txt")
    anims[0].play()
end sub
sub Item.VENTWIRES_PROC_FLUSH()

    if anims_n then delete(anims)
end sub
function Item.VENTWIRES_PROC_RUN(t as double) as integer
    anims[0].step_animation()
    return 0
end function
sub Item.VENTWIRES_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0)
end sub
sub Item.VENTWIRES_PROC_DRAWOVERLAY(scnbuff as integer ptr)
  
end sub
sub Item.VENTWIRES_PROC_CONSTRUCT()
end sub
sub Item.WALLSWITCH_SLOT_INTERACT(pvPair() as _Item_slotValuePair_t)
    
    data_.WALLSWITCH_DATA->state = 1 - data_.WALLSWITCH_DATA->state
    throw("TOGGLE")
    if data_.WALLSWITCH_DATA->state = 1 then
        throw("TURNON")
            
    else
        throw("TURNOFF")
            
    end if
end sub
sub Item.WALLSWITCH_PROC_INIT()
    data_.WALLSWITCH_DATA = new ITEM_WALLSWITCH_TYPE_DATA
 
    
    data_.WALLSWITCH_DATA->state = 0

    getParameter(data_.WALLSWITCH_DATA->state, "state")
    
    CREATE_ANIMS(1)
    anims[0].load(MEDIA_PATH + "wallswitch.txt")
    anims[0].play()
    
    link.dynamiccontroller_ptr->addPublishedSlot(ID, "INTERACT", "INTERACT", new Rectangle2D(Vector2D(8,8), Vector2D(24, 24)))
    link.dynamiccontroller_ptr->setTargetSlotOffset(ID, "INTERACT", p)
end sub
sub Item.WALLSWITCH_PROC_FLUSH()

    if anims_n then delete(anims)
    if data_.WALLSWITCH_DATA then delete(data_.WALLSWITCH_DATA)
    data_.WALLSWITCH_DATA = 0
end sub
function Item.WALLSWITCH_PROC_RUN(t as double) as integer
    if data_.WALLSWITCH_DATA->state = 0 then
        anims[0].hardSwitch(0)
    else
        anims[0].hardSwitch(1)
    end if
    
    return 0
end function
sub Item.WALLSWITCH_PROC_DRAW(scnbuff as integer ptr)
    PREP_LIT_ANIMATION()
    
    DRAW_LIT_ANIMATION(0, p.x, p.y, 0, 0 )

end sub
sub Item.WALLSWITCH_PROC_DRAWOVERLAY(scnbuff as integer ptr)
  
end sub
sub Item.WALLSWITCH_PROC_CONSTRUCT()
    _initAddSignal_("TURNON")
    _initAddSignal_("TURNOFF")
    _initAddSignal_("TOGGLE")
    _initAddSlot_("INTERACT", ITEM_WALLSWITCH_SLOT_INTERACT_E)
    _initAddParameter_("STATE", _ITEM_VALUE_INTEGER)
end sub
