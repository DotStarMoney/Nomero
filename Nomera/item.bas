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
	anims = 0
end constructor

destructor Item()
	if anims then delete(anims)
    if lightState then
        imagedestroy(lightShaded.diffuse_fbimg)
        imagedestroy(lightShaded.specular_fbimg)
    end if
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

sub Item.init(itemType_ as Item_Type_e, itemFlavor_ as integer)
    dim as string lightFilename
    dim as integer lw, lh
	itemType = itemType_
	flush()
    body_i = -1
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
        body = TinyBody(Vector2D(0,0), 4, 1)
        body.elasticity = 1
        body.v = Vector2D(100, 0)
        itemFlavor = itemFlavor_
        anims_n = 2
		anims = new Animation[anims_n]
        select case itemFlavor
        case 0
            lightFilename = "LightOrange"
            lw = 256
            lh = 256
        case else
            lightFilename = "LightOrange"
            lw = 256
            lh = 256
        end select
        anims[0].load("Lights\" + lightFilename + "_Diffuse.txt")
        anims[1].load("Lights\" + lightFilename + "_Specular.txt")
        lightTex.diffuse_fbimg = anims[0].getRawImage()
        lightTex.specular_fbimg = anims[1].getRawImage()
        lightTex.x = body.p.x
        lightTex.y = body.p.y
        lightTex.w = lw
        lightTex.h = lh
        lightShaded = lightTex
        lightShaded.diffuse_fbimg = imagecreate(lw, lh)
        lightShaded.specular_fbimg = imagecreate(lw, lh)        
        body_i = link.tinyspace_ptr->addBody(@body)
        lightState = 1
	case else
		anims_n = 0
	end select
end sub

sub Item.setPos(v as Vector2D)
	body.p = v
end sub

function Item.getPos() as Vector2D
	return body.p
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
	dim as integer orBits
	select case itemType
	case ITEM_BOMB
		select case itemFlavor
		case 0
			anims[0].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
		end select
    case ITEM_LIGHT
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
        circle scnbuff, (body.p.x, body.p.y), 3, rgb(255, 255,255),,,,F
	case else
	
	end select
end sub

sub Item.flush()
	if anims then delete(anims)
    if lightState then
        imagedestroy(lightShaded.diffuse_fbimg)
        imagedestroy(lightShaded.specular_fbimg)
    end if
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

sub Item.getLightingData(texture as Pointlight, shaded as Pointlight)
    texture = lightTex
    shaded = lightShaded
end sub

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
        lightTex.x = body.p.x
        lightTex.y = body.p.y
        lightShaded.x = lightTex.x
        lightShaded.y = lightTex.y
       
        if data1 <> 0 then return 1
  	case else
		return 1
	end select
	return 0
end function
