#ifndef ITEM_BI
#define ITEM_BI

#include "tinybody.bi"
#include "objectlink.bi"
#include "tinyspace.bi"
#include "animation.bi"

#define BOMB_STICKYNESS 0


enum Item_Type_e
	ITEM_KEY
	ITEM_INTELLIGENCE
	ITEM_SECRETFURNITURE
	ITEM_CASH
	ITEM_BOMB
	ITEM_DYNAMICPLATFORM
end enum

'for bomb, first 3 bits define bomb type.
'	next 2 bits are orientation


type Item
	public:
		declare constructor()
		declare destructor()
		declare sub init(itemType_ as Item_Type_e, itemFlavor_ as integer)
		declare sub setPos(v as Vector2D)
		declare sub drawItem(scnbuff as integer ptr)
		declare sub drawItemTop(scnbuff as integer ptr)
		declare sub setData0(d as integer)
		declare sub setData1(d as integer)
		declare function process(t as double) as integer
		declare sub flush()
		declare sub setLink(link_ as objectLink)
	private:
		static as uinteger ptr BOMB_COLORS
	
		as Item_Type_e itemType
		as integer     itemFlavor
		as TinyBody    body
		as integer     body_i
		as integer     orientation
		as ObjectLink  link
		as integer       anims_n
		as Animation ptr anims
		as integer     data0
		as integer     data1
end type


#endif
