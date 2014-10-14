#ifndef ITEM_BI
#define ITEM_BI

#include "tinybody.bi"
#include "objectlink.bi"
#include "tinyspace.bi"

#define BOMB_STICKYNESS 20

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
		declare sub init(link_ as objectLink, itemType_ as Item_Type_e, itemFlavor_ as integer)
		declare sub setPos(v as Vector2D)
		declare sub drawItem(scnbuff as integer ptr)
		declare function process(t as double) as integer
	private:
		as Item_Type_e itemType
		as integer     itemFlavor
		as TinyBody    body
		as integer     orientation
		as ObjectLink  link
end type


#endif
