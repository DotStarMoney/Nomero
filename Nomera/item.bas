#include "item.bi"
#include "gamespace.bi"
#include "projectilecollection.bi"

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
		orientation = (itemFlavor_ and &h11000) shr 3
		itemFlavor = (itemFlavor_ and &b111)
		data0 = 0
		data1 = 0
		anims_n = 3
		anims = new Animation[anims_n]
		anims[0].load("mines.txt")
		anims[1].load("silhouette.txt")
		anims[2].load("ledflash.txt")
		anims[0].play()
		anims[1].play()
		anims[2].play()
		anims[0].hardSwitch(itemFlavor)
		anims[1].hardSwitch(itemFlavor)
		anims[2].hardSwitch(0)
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
        
        data2 = 0
        data0 = 0
        for i = 0 to 5
            cast(integer ptr, data3)[i] = int(rnd * 36)
        next i
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
		select case itemFlavor
		case 0
			a = anims[0].getOffset() + body.p
			b = a + Vector2D(anims[0].getWidth(), anims[0].getHeight())
		end select
    case ITEM_LIGHT
        a = body.p
        b = body.p
	case else
	
	end select	
end sub

sub Item.drawItem(scnbuff as integer ptr)
	dim as integer orBits, frame
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
	dim as integer col
	select case itemType
	case ITEM_BOMB
		select case itemFlavor
		case 0
			if data0 then
				anims[1].setGlow(BOMB_COLORS[data0 - 1])
				anims[1].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
			end if
			anims[2].drawAnimation(scnbuff, body.p.x - 3, body.p.y - 16, link.gamespace_ptr->camera)
			col = BOMB_COLORS[data0 - 1]
			addColor col, &h101010
			drawStringShadow scnbuff, body.p.x - 20, body.p.y - 20, iif(data0 < 10, str(data0), "0"), col
		end select
    case ITEM_LIGHT

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
    if data3 <> 0 then delete(cast(integer ptr, data3))
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


function Item.process(t as double) as integer
	dim as integer i
    
    
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
		if (data1 = 1) orElse (freeFallingFrames >= MINE_FREEFALL_MAX) then
			link.player_ptr->removeItemReference(cast(integer, @this))
			
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
			link.player_ptr->removeItemReference(cast(integer, @this))

			'puff o' smoke and deactivate effect
			
			return 1
		end if
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

        'data2 -= 1
        'if data2 <= 0 then 
        '    data2 = int(rnd * 50) + 1
        '    data0 = 1 - data0
        'end if
            
        if data0 = 0 then
            minValue += 1
            if minValue >= 2 then
                minValue = 0
                lightState = 1 - lightState
                for i = 0 to 5
                    cast(integer ptr, data3)[i] = int(rnd * 36)
                next i
            end if
        else
            lightState = 0
        end if
    case ITEM_INTERFACE
        minValue += 1
        if minValue >= data2 then
            minValue = 0
            data1 = 1 - data1
            data2 = int(rnd * 10) + 10
        end if
  	case else
		return 1
	end select
	return 0
end function
