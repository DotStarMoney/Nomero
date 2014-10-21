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
	flush()
	link.tinyspace_ptr->removeBody(body_i)
end destructor

sub Item.setData0(d as integer)
	data0 = d
end sub
sub Item.setData1(d as integer)
	data1 = d
end sub

sub Item.setLink(link_ as objectLink)
	link = link_
end sub

sub Item.init(itemType_ as Item_Type_e, itemFlavor_ as integer)
	itemType = itemType_
	flush()
	select case itemType
	case ITEM_BOMB
		body = TinyBody(Vector2D(0,0), 8, 10)
		orientation = (itemFlavor_ and &h11000) shr 3
		itemFlavor = (itemFlavor_ and &b111)
		body.f = Vector2D(0, -10 * DEFAULT_GRAV)
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
	case else
		anims_n = 0
	end select
end sub

sub Item.setPos(v as Vector2D)
	body.p = v
end sub

sub Item.drawItem(scnbuff as integer ptr)
	dim as integer orBits
	select case itemType
	case ITEM_BOMB
		select case itemFlavor
		case 0
			anims[0].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
		end select
	case else
	
	end select
end sub

sub Item.drawItemTop(scnbuff as integer ptr)
	dim as integer orBits
	select case itemType
	case ITEM_BOMB
		select case itemFlavor
		case 0
			if data0 then
				anims[1].setGlow(BOMB_COLORS[data0 - 1])
				anims[1].drawAnimation(scnbuff, body.p.x, body.p.y, link.gamespace_ptr->camera)
			end if
			anims[2].drawAnimation(scnbuff, body.p.x - 3, body.p.y - 16, link.gamespace_ptr->camera)
		end select
	case else
	
	end select
end sub

sub Item.flush()
	if anims then delete(anims)
end sub

function Item.process(t as double) as integer
	dim as integer i
	select case itemType
	case ITEM_BOMB
		anims[0].step_animation()
		anims[1].step_animation()
		anims[2].step_animation()
		if data1 <> 0 then
			link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,1)
			link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 16 - 8, rnd * 16 - 8),,,2)
			link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
			link.oneshoteffects_ptr->create(body.p + Vector2D(rnd * 48 - 24, rnd * 48 - 24),,,2)
			link.soundeffects_ptr->playSound(SND_EXPLODE)

			for i = 1 to 5
				link.projectilecollection_ptr->create(body.p, Vector2D(rnd*2 - 1, rnd*2 - 1) * (1 + rnd*700), DETRITIS)
			next i
			
			link.gamespace_ptr->vibrateScreen()
	
			link.level_ptr->addFallout(body.p.x(), body.p.y())
			
			return 1
		end if
	case else
		return 1
	end select
	return 0
end function
