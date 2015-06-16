#include "item.bi"
#include "gamespace.bi"
#include "projectilecollection.bi"
#include "itemtypes.bi"

dim as uinteger ptr Item.BOMB_COLORS = 0

constructor Item()
	if BOMB_COLORS = 0 then
		BOMB_COLORS = new uinteger[10]
		BOMB_COLORS[0] = rgb( 58, 209,  70)
		BOMB_COLORS[1] = rgb(210,  57,  62)
		BOMB_COLORS[2] = rgb(  0, 198, 200)
		BOMB_COLORS[3] = rgb(200,  65, 203)
		BOMB_COLORS[4] = rgb(221, 200,  47)
		BOMB_COLORS[5] = rgb( 55,  47, 221)
		BOMB_COLORS[6] = rgb(255, 128,   0)
		BOMB_COLORS[7] = rgb( 35, 233, 179)
		BOMB_COLORS[8] = rgb(255, 255, 255)
		BOMB_COLORS[9] = rgb(185, 133, 115)
	end if
    data3 = 0
	anims = 0
end constructor

destructor Item()
	if anims then delete(anims)
    if lightState then
        imagedestroy(light.shaded.diffuse_fbimg)
        imagedestroy(light.shaded.specular_fbimg)
        imagedestroy(light.occlusion_fbimg)
    end if
    if data3 <> 0 then delete(cast(integer ptr, data3))
    if body_i <> -1 then link.tinyspace_ptr->removeBody(body_i)
end destructor

function Item.getIndicatorColor(i as integer) as integer
	return BOMB_COLORS[i]
end function

sub Item.setData0(d as integer)
	data0 = d
end sub
sub Item.setData1(d as integer)
	data1 = d
end sub
sub Item.setData2(d as integer)
	data2 = d
end sub
function Item.getData0() as integer
	return data0
end function
function Item.getData1() as integer
	return data1
end function
function Item.getData2() as integer
	return data2
end function
sub Item.setLink(link_ as objectLink)
	link = link_
end sub

sub Item.setLightModeData(minValue_p as double, maxValue_p as double, mode_p as integer)
    this.minValue = minValue_p
    this.maxValue = maxValue_p
    this.mode = mode_p
end sub

sub Item.setSize(s as Vector2D)
    size = s
end sub

function Item.getSize() as Vector2D
    return size
end function

sub Item.init(itemType_ as Item_Type_e, itemFlavor_ as integer, fast_p as integer = 0)
    dim as string lightFilename
    dim as integer lw, lh, i, steps
	itemType = itemType_
	flush()
    body_i = -1
    fast = fast_p
	select case itemType
	case ITEM_BOMB
		body = TinyBody(Vector2D(0,0), 8, 10)
		orientation = (itemFlavor_ and &b11000) shr 3
		itemFlavor = (itemFlavor_ and &b111)
		data0 = 0
		data1 = 0
        data3 = 0
        data4 = 0


        select case itemFlavor
        case 0 
        	anims_n = 3
            anims = new Animation[anims_n]           
            anims[0].load("mines.txt")
            anims[1].load("silhouette.txt")
            anims[2].load("ledflash.txt")
            
            anims[0].hardSwitch(0)
            anims[1].hardSwitch(0)
        case 3
            anims_n = 4
            anims = new Animation[anims_n]           
            anims[0].load("mines.txt")
            anims[1].load("silhouette.txt")
            anims[2].load("ledflash.txt")
            anims[3].load("smokerel.txt")
            
            anims[3].play()
            
            anims[0].hardSwitch(3)
            anims[1].hardSwitch(2)        
        case 4
            anims_n = 3
            anims = new Animation[anims_n]           
            anims[0].load("mines.txt")
            anims[1].load("silhouette.txt")
            anims[2].load("ledflash.txt")
            
            
            anims[0].hardSwitch(1)
            anims[1].hardSwitch(1)   
            
            data5 = cast(integer, new ElectricMine_ArcData_t[4])
            data6 = 0
        end select
        
        if anims_n <> 0 then
            anims[2].hardSwitch(0)
            anims[0].play()
            anims[1].play()
            anims[2].play()
        end if
        
		body.friction = 20
		select case orientation
		case 0
			body.f = body.f + Vector2D(0, BOMB_STICKYNESS)
		case 1
			body.f = body.f + Vector2D(-BOMB_STICKYNESS, 0)
		case 2
			body.f = body.f + Vector2D(0, -BOMB_STICKYNESS)
		case 3
			body.f = body.f + Vector2D(BOMB_STICKYNESS, 0)
		end select
		body_i = link.tinyspace_ptr->addBody(@body)
        lightState = 0
    case ITEM_LIGHT
        itemFlavor = itemFlavor_
        anims_n = 2
		anims = new Animation[anims_n]
        select case itemFlavor
        case 0
            lightFilename = "LightOrange"
            lw = 256
            lh = 256
        case 1
            lightFilename = "PaleBlue"
            lw = 512
            lh = 512        
        case 2
            lightFilename = "RedOrange"
            lw = 512
            lh = 512               
        case else
            lightFilename = "LightOrange"
            lw = 256
            lh = 256
        end select
        anims[0].load("Lights\" + lightFilename + "_Diffuse.txt")
        anims[1].load("Lights\" + lightFilename + "_Specular.txt")
        light.texture.diffuse_fbimg = anims[0].getRawImage()
        light.texture.specular_fbimg = anims[1].getRawImage()
        light.texture.x = body.p.x
        light.texture.y = body.p.y
        light.texture.w = lw
        light.texture.h = lh
        light.shaded = light.texture
        if fast <> 65535 then
            light.shaded.diffuse_fbimg = 0
            light.shaded.specular_fbimg = 0   
            light.occlusion_fbimg = 0       
        else
            light.shaded.diffuse_fbimg = imagecreate(lw, lh)
            light.shaded.specular_fbimg = imagecreate(lw, lh)   
            light.occlusion_fbimg = imagecreate(lw, lh)
        end if
        light.last_tl_x = 0
        light.last_tl_y = 0
        light.last_br_x = lw - 1
        light.last_br_y = lh - 1
        data0 = 0
        lightState = 1
    case ITEM_SMALLOSCILLOSCOPE
        anims_n = 2
		anims = new Animation[anims_n]
        anims[0].load("smallscope.txt")
        anims[0].play()
        anims[1].load("smallscope.txt")
        anims[1].play()       
        anims[1].hardSwitch(1)
        steps = int(rnd * 30)
        for i = 0 to steps: anims[0].step_animation(): next i
        lightState = 0
    case ITEM_INTERFACE
        
        anims_n = 3
		anims = new Animation[anims_n]
        anims[0].load("interface.txt")
        anims[0].play()
        anims[1].load("interface.txt")
        anims[1].play()       
        anims[1].hardSwitch(1)
        anims[2].load("interface.txt")
        anims[2].play()       
        anims[2].hardSwitch(2)
        lightState = 0   
        minValue = 0
        data1 = 0
        data2 = int(rnd * 10) + 10

    case ITEM_NIXIEFLICKER
        anims_n = 3
		anims = new Animation[anims_n]
        anims[0].load("nixie.txt")
        anims[0].play()        
        data3 = cast(integer, new integer[6])
        
        lw = 512
        lh = 512
        anims[1].load("Lights\RedOrange_Diffuse.txt")
        anims[2].load("Lights\RedOrange_Specular.txt")
        light.texture.diffuse_fbimg = anims[1].getRawImage()
        light.texture.specular_fbimg = anims[2].getRawImage()
        light.texture.x = 0
        light.texture.y = 0
        light.texture.w = lw
        light.texture.h = lh
        light.shaded = light.texture
        light.shaded.diffuse_fbimg = imagecreate(lw, lh)
        light.shaded.specular_fbimg = imagecreate(lw, lh)   
        light.occlusion_fbimg = imagecreate(lw, lh)
        light.last_tl_x = 0
        light.last_tl_y = 0
        light.last_br_x = lw - 1
        light.last_br_y = lh - 1
        lightState = 1
        minValue = 0
        
        data1 = 0
        data2 = 0
        data0 = 0
        for i = 0 to 5
            cast(integer ptr, data3)[i] = int(rnd * 36)
        next i
    case ITEM_COVERSMOKE
		body = TinyBody(Vector2D(0,0), 16, 10)
		    
        data0 = 0
        data1 = 0
        data2 = 1
        data3 = COVERSMOKE_LIFETIME
        data6 = 0
        anims_n = 1
        anims = new Animation[anims_n]   
        anims[0].load("coversmoke.txt")
        anims[0].play()
            
 
        itemFlavor = itemFlavor_
        
        if itemFlavor = 0 then 
            body.noCollide = 1
            data0 = 10000 * 0.17
        else
            body_i = link.tinyspace_ptr->addBody(@body)
        end if
        
        
    
    	body.friction = 0
        body.elasticity = 0.4+rnd*0.3
        lightState = 0
	case else
		anims_n = 0
	end select
end sub

sub Item.setPos(v as Vector2D)
	body.p = v
    p = v
end sub

function Item.getPos() as Vector2D
    if body_i = -1 then
        return p
    else
        return body.p
    end if
end function

sub Item.getBounds(byref a as Vector2D, byref b as Vector2D)
	select case itemType
	case ITEM_BOMB
        a = anims[0].getOffset() + body.p
        b = a + Vector2D(anims[0].getWidth(), anims[0].getHeight())
    case ITEM_LIGHT
        a = body.p
        b = body.p
	case else
	
	end select	
end sub

sub Item.drawItem(scnbuff as integer ptr)
	dim as integer orBits, frame, value
    dim as LightPair ptr ptr lights
    dim as integer numLights, posX, posY, i
    
    if link.level_ptr->shouldLight() then
        numLights = link.level_ptr->getLightList(lights)
    else
        numLights = 0
    end if
    
	select case itemType
	case ITEM_BOMB
		select case itemFlavor
		case 0
			anims[0].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
        case 3
			anims[0].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)      

        case 4
			anims[0].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
		end select
    case ITEM_LIGHT
        ''
    case ITEM_SMALLOSCILLOSCOPE

        if link.level_ptr->shouldLight() then
            anims[1].drawAnimationLit(scnbuff, p.x, p.y,_
                                      lights, numLights, link.level_ptr->getHiddenObjectAmbientLevel(),_
                                      link.gamespace_ptr->camera,,,ANIM_TRANS)            
        else
            anims[1].drawAnimation(scnbuff, p.x, p.y, link.gamespace_ptr->camera,,ANIM_TRANS)
        end if
        anims[0].drawAnimation(scnbuff, p.x, p.y, link.gamespace_ptr->camera,,ANIM_GLOW)
    case ITEM_INTERFACE
        if link.level_ptr->shouldLight() then
            anims[0].drawAnimationLit(scnbuff, p.x, p.y,_
                                      lights, numLights, link.level_ptr->getHiddenObjectAmbientLevel(),_
                                      link.gamespace_ptr->camera)            
        else
            anims[0].drawAnimation(scnbuff, p.x, p.y, link.gamespace_ptr->camera)
        end if        
        anims[1].drawAnimation(scnbuff, p.x, p.y, link.gamespace_ptr->camera)        

        if data1 = 1 then
            anims[2].drawAnimation(scnbuff, p.x, p.y, link.gamespace_ptr->camera)        
        end if
    case ITEM_NIXIEFLICKER
        for i = 0 to 5
            frame = cast(integer ptr, data3)[i]
            if lightState = 0 then frame = 36
            
            posX = (frame * 16) mod 320
            posY = int((frame * 16) / 320) * 32
            anims[0].drawImageLit(scnbuff, p.x + i*16 + iif(i > 2, 16, 0), p.y, posX, posY, posX+15, posY+31,_
                                  lights, numLights, iif(lightState = 0, &h404040, &hFF8080),_
                                  link.gamespace_ptr->camera, 0) 
        next i
    
	case else
	
	end select
end sub

sub Item.drawItemTop(scnbuff as integer ptr)
	dim as integer orBits
	dim as integer col, value
	select case itemType
	case ITEM_BOMB
        select case itemFlavor
        case 0
            if data0 then
                anims[1].setGlow(BOMB_COLORS[data0 - 1])
                anims[1].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
            end if
            anims[2].drawAnimation(scnbuff, body.p.x, body.p.y - 16, link.gamespace_ptr->camera)
            col = BOMB_COLORS[data0 - 1]
            addColor col, &h101010
            drawStringShadow scnbuff, body.p.x - 20, body.p.y - 20, iif(data0 < 10, str(data0), "0"), col
        case 3
            if data4 = 0 then
                if data0 then
                    anims[1].setGlow(BOMB_COLORS[data0 - 1])
                    anims[1].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
                end if
                anims[2].drawAnimation(scnbuff, body.p.x - 1, body.p.y - 16, link.gamespace_ptr->camera)
                col = BOMB_COLORS[data0 - 1]
                addColor col, &h101010
                drawStringShadow scnbuff, body.p.x - 20, body.p.y - 20, iif(data0 < 10, str(data0), "0"), col   
            end if        
            if data4 = 1 then 
                value = 50 + data3*2
                if value > 255 then value = 255
                value = ((value/255.0)^0.5)*255
                anims[3].setGlow(&h00ffffff or (value shl 24))
                anims[3].drawAnimation(scnbuff, body.p.x-2, body.p.y-7, link.gamespace_ptr->camera) 
            end if
        case 4
            if data4 = 0 then
                if data0 then
                    anims[1].setGlow(BOMB_COLORS[data0 - 1])
                    anims[1].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
                end if
                anims[2].drawAnimation(scnbuff, body.p.x - 1, body.p.y - 14, link.gamespace_ptr->camera)
                col = BOMB_COLORS[data0 - 1]
                addColor col, &h101010
                drawStringShadow scnbuff, body.p.x - 20, body.p.y - 20, iif(data0 < 10, str(data0), "0"), col   
            end if
        end select
    case ITEM_LIGHT

    case ITEM_COVERSMOKE
        ''
	case else
	
	end select
end sub

sub Item.flush()
	if anims then delete(anims)
    if lightState then
        imagedestroy(light.shaded.diffuse_fbimg)
        imagedestroy(light.shaded.specular_fbimg)
        imagedestroy(light.occlusion_fbimg)
    end if
    select case itemType
    case ITEM_INTERFACE
    
        if data3 <> 0 then delete(cast(integer ptr, data3))
    case ITEM_BOMB
        select case itemFlavor
        case 4
            if data5 <> 0 then delete(cast(ElectricMine_ArcData_t ptr, data5))
        end select
    end select
end sub

function Item.getFlavor() as integer
	return itemFlavor
end function

function Item.getType() as Item_Type_e
	return itemType
end function

function Item.hasLight() as integer
    return lightState
end function

function Item.getLightingData() as LightPair ptr
    return @light
end function

sub Item.setVel(v as Vector2D)
    body.v = v
end sub

function Item.process(t as double) as integer
	dim as integer i, value, dx, dy, x0, y0, x1, y1
    dim as integer ptr img
    dim as double randAngle
    dim as double dist
    dim as Vector2D v, pt
    dim as Item ptr newItem
    dim as ElectricMine_ArcData_t ptr elecData
    
    
	select case itemType
	case ITEM_BOMB
		anims[0].step_animation()
		anims[1].step_animation()
		anims[2].step_animation()
		if link.tinyspace_ptr->getArbiterN(body_i) = 0 then
			freeFallingFrames += 1
		else
			freeFallingFrames = 0
		end if
        select case itemFlavor
        case 0
            if (data1 = 1) orElse (freeFallingFrames >= MINE_FREEFALL_MAX) then

            
                'link.player_ptr->removeItemReference(cast(integer, @this))

                link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,1)
                link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,2)
                link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 64 - 32, rnd * 64 - 32),,,2)
                link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 64 - 32, rnd * 64 - 32),,,2)
                link.oneshoteffects_ptr->create(body.p, FLASH,,1)

                link.soundeffects_ptr->playSound(SND_EXPLODE)

                for i = 1 to 5
                    link.projectilecollection_ptr->create(body.p, Vector2D(rnd*2 - 1.0, rnd*2 - 1.0) * (300 + rnd*700), DETRITIS)
                next i
                
                link.gamespace_ptr->vibrateScreen()
        
                link.level_ptr->addFallout(body.p.x(), body.p.y())
                return 1
            elseif (data1 = 2) then
                
                'puff o' smoke and deactivate effect
                
                return 1
            end if
        case 3
            if data4 = 0 then
                if (data1 = 1) orElse (freeFallingFrames >= MINE_FREEFALL_MAX) andALso (data4 = 0) then
                    link.soundeffects_ptr->playSound(SND_EXPLODE_4)
                    data4 = 1
                    data3 = SMOKEMINE_TIME                    
                    if (freeFallingFrames >= MINE_FREEFALL_MAX) andAlso data1 = 0 then 
                        link.player_ptr->removeItemReference(cast(integer, @this))
                    end if
                    
                   
                elseif (data1 = 2) then
                    'puff o' smoke and deactivate effect
                    return 1
                end if
            elseif data4 = 1 then
                data3 -= 1
            	anims[3].step_animation()

                if (data3 mod 2) = 0 then 
                    newItem = link.dynamiccontroller_ptr->addOneItem(body.p + Vector2D(0, -100), ITEM_COVERSMOKE, data3 mod 4)
                    newItem->setVel(Vector2D(((2.0*rnd) - 1.0)*80.0, -100 - rnd*25))   
                end if
                
                if data3 = 4 then link.oneshoteffects_ptr->create(body.p, SMOKE,,1)
                if data3 = 0 then return 1
            end if
        case 4
            elecData = cast(ElectricMine_ArcData_t ptr, data5)
            if (data1 = 2) andAlso (data4 = 0) then            
                return 1
            elseif (data1 = 1) orElse (freeFallingFrames >= MINE_FREEFALL_MAX) andALso (data4 = 0) then
                data3 = ELECMINE_TIME
                data4 = 1
                link.oneshoteffects_ptr->create(body.p, ELECTRIC_FLASH,,1)
                link.soundeffects_ptr->playSound(SND_EXPLODE_3)

                for i = 0 to MAX_RAYCAST_ATTEMPTS - 1
                    randAngle = rnd*PI*2
                    v = Vector2D(cos(randAngle), sin(randAngle))*RAYCAST_DIST
                    dist = link.tinyspace_ptr->raycast(body.p, v, pt)
                    if dist >= 0 then
                   
                        elecData[data6].arcID = link.electricarc_ptr->create()
                        elecData[data6].bPos = (Vector2D(0,rnd)-Vector2D(0,0.5))*10 - Vector2D(1,4)
                        elecData[data6].endPos = pt
                        link.electricarc_ptr->setPoints(elecData[data6].arcID, body.p + elecData[data6].bPos, pt)
       
                        data6 += 1
                        if data6 = 4 then exit for
                    end if
                next i
                
                link.soundeffects_ptr->playSound(SND_ARC)
                
                anims[0].hardSwitch(2)
                
                if (freeFallingFrames >= MINE_FREEFALL_MAX) andAlso data1 = 0 then 
                    link.player_ptr->removeItemReference(cast(integer, @this))
                end if
            end if
            
            if data4 then
                data3 -= 1
                if data6 > 0 then
                    for i = 0 to data6 - 1
                        link.electricarc_ptr->setPoints(elecData[i].arcID, body.p + elecData[i].bPos, elecData[i].endPos)
                    next i
                end if
                
                if data3 = 0 then
                    if data6 > 0 then
                        for i = 0 to data6 - 1
                            link.electricarc_ptr->destroy(elecData[i].arcID)
                        next i
                    end if
                    
                    link.oneshoteffects_ptr->create(body.p, BLUE_FLASH,,1)
                    return 1
                end if
            end if    
        end select
    case ITEM_LIGHT
        light.texture.x = body.p.x
        light.texture.y = body.p.y
        light.shaded.x = light.texture.x
        light.shaded.y = light.texture.y
        
        select case mode
        case MODE_FLICKER
            if data0 <= 0 then
                data0 = (maxValue - minValue)*rnd + minValue
                lightState = 1 - lightState 
            else
                data0 -= 1
            end if
        case MODE_TOGGLE
            minValue += 1
            if minValue >= maxValue then
                minValue = 0
                lightState = 1 - lightState
            end if
        case MODE_STATIC
            lightState = 1
        end select
       
        if data1 <> 0 then return 1
    case ITEM_SMALLOSCILLOSCOPE
        anims[0].step_animation()
        
    case ITEM_NIXIEFLICKER
        light.texture.x = p.x + size.x * 0.5
        light.texture.y = p.y + size.y * 0.5
        light.shaded.x = light.texture.x
        light.shaded.y = light.texture.y  

        'when data2 countdown started
        data2 += 1
        
        if data2 < 603 then
            minValue += 1
            if minValue >= 2 then
                minValue = 0
                lightState = 1 - lightState
                for i = 0 to 5
                    if data2 > (300 + i*60) then
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
                    else
                        value = int(rnd * 36)
                    end if
                    cast(integer ptr, data3)[i] = value
                next i
            end if
        else
            lightState = 1
        end if
    case ITEM_INTERFACE
        minValue += 1
        if minValue >= data2 then
            minValue = 0
            data1 = 1 - data1
            data2 = int(rnd * 10) + 10
        end if
    case ITEM_COVERSMOKE
        anims[0].setSpeed(data2)
        anims[0].step_animation()
        body.f = Vector2D(0, -body.m * DEFAULT_GRAV) * (0.7 + ((data0 / 10000.0)^(2))*0.3)
        body.v = body.v * ((COVERSMOKE_DAMPING_MAX - 1) * (data1 / 10000.0) + 1)
        
        if body.v.magnitude() < 2.0 then body.noCollide = 1 
        
        if itemFlavor = 0 then
            body.v = body.v + ((Vector2D(0, body.m * DEFAULT_GRAV) + body.f) / body.m) * t
            body.p = body.p + body.v*t
        end if
        
        if body.didCollide then 
            body.v *= 0.75
            body.didCollide = 0
        end if
         
         /'
        if data3 >= 290 then
            anims[0].setGlow(&h00ffffff or int(((300 - data3) / 10.0) * 255) shl 24)
        elseif data3 >= 60 then
            anims[0].setGlow(&hffffffff)
        else
            anims[0].setGlow(&h00ffffff or int((data3 / 60.0) * 255) shl 24)        
        end if
        '/
        
        anims[0].drawAnimation(link.level_ptr->getSmokeTexture(), body.p.x, body.p.y,,,,-link.gamespace_ptr->camera + Vector2D(SCRX*0.5, SCRY*0.5))
        
        data0 += 100
        data1 += 10
        data3 -= 1
        if data0 > 10000 then data0 = 10000
        if data1 > 10000 then data1 = 10000
        if anims[0].done then return 1
  	case else
		return 1
	end select
	return 0
end function
