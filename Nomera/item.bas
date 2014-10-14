#include "item.bi"

constructor Item()

end constructor

destructor Item()

end destructor

sub Item.init(link_ as objectLink, itemType_ as Item_Type_e, itemFlavor_ as integer)
	link = link_
	itemType = itemType_
	select case itemType
	case ITEM_BOMB
		body = TinyBody(Vector2D(0,0), 4, 10)
		orientation = (itemFlavor_ and &h11000) shr 3
		itemFlavor = (itemFlavor_ and &b111)
		body.f = Vector2D(0, -10 * DEFAULT_GRAV)
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
	case else
		
	end select
end sub

sub Item.setPos(v as Vector2D)
	body.p = v
end sub

sub Item.drawItem(scnbuff as integer ptr)
	select case itemType
	case ITEM_BOMB
		
	case else
	
	end select
end sub

function Item.process(t as double) as integer
	select case itemType
	case ITEM_BOMB
	  
	case else
		return 1
	end select
	return 0
end function
